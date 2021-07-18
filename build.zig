const std = @import("std");
const Builder = std.build.Builder;
const Target = std.Target;
const CrossTarget = std.zig.CrossTarget;
const panic = std.debug.panic;
const print = std.debug.print;
const assert = std.debug.assert;
const Dir = std.fs.Dir;

pub fn stivale2_kernel(b: *Builder, arch: std.Target.Cpu.Arch) *std.build.LibExeObjStep
{
    const kernel_filename = b.fmt("kernel_{s}.elf", .{@tagName(arch)});
    const kernel = b.addExecutable(kernel_filename, "src/kernel/main.zig");
    kernel.setOutputDir(b.cache_root);
    const mode = b.standardReleaseOptions();
    kernel.setBuildMode(mode);
    kernel.install();

    var disabled_features = std.Target.Cpu.Feature.Set.empty;
    var enabled_features = std.Target.Cpu.Feature.Set.empty;

    switch (arch)
    {
        .x86_64 =>
        {
            const features = std.Target.x86.Feature;
            disabled_features.addFeature(@enumToInt(features.mmx));
            disabled_features.addFeature(@enumToInt(features.sse));
            disabled_features.addFeature(@enumToInt(features.sse2));
            disabled_features.addFeature(@enumToInt(features.avx));
            disabled_features.addFeature(@enumToInt(features.avx2));

            enabled_features.addFeature(@enumToInt(features.soft_float));
            kernel.code_model = .kernel;
        },
        else => unreachable,
    }
    kernel.disable_stack_probing = true;
    kernel.setTarget(.
        {
            .cpu_arch = arch,
            .os_tag = std.Target.Os.Tag.freestanding,
            .abi = std.Target.Abi.none,
            .cpu_features_sub = disabled_features,
            .cpu_features_add = enabled_features,
        });

    kernel.setLinkerScriptPath("src/kernel/linker_script.ld");
    b.default_step.dependOn(&kernel.step);

    return kernel;
}

fn copy_file_str(dst_dir: []const u8, src_dir: []const u8, file: []const u8) !void
{
    var cwd = std.fs.cwd();
    const dst_dir_handle = try cwd.openDir(dst_dir, .{});
    const src_dir_handle = try cwd.openDir(src_dir, .{});

    try copy_file(dst_dir_handle, src_dir_handle, file);
}

fn copy_file(dst_dir: Dir, src_dir: Dir, file: []const u8) !void
{
    print("Copying {s}...\n", .{file});
    try std.fs.Dir.copyFile(src_dir, file, dst_dir, file, .{});
}

const LimineVersion = struct
{
    major: u16,
    minor: u16,
};

const limine_version = LimineVersion
{
    .major = 2,
    .minor = 35,
};

const most_updated_limine_minor_version = 35;

fn execute_program(program_arguments: [:null]const ?[*:0]const u8) !void
{
    const pid = try std.os.fork();

    switch (pid)
    {
        0 =>
        {
            const program_name = program_arguments[0].?;
            const execv_err = std.os.execvpeZ(program_name, program_arguments, std.c.environ);
            panic("Execv error: {}\n", .{execv_err});
        },
        else =>
        {
            _ = std.os.waitpid(pid, 0);
        }
    }
}

const LimineImage = struct
{
    step: std.build.Step,
    builder: *std.build.Builder,
    kernel_step: *std.build.LibExeObjStep,
    image_path: []const u8,

    fn make(step: *std.build.Step) !void
    {
        print("Making Limine image...\n", .{});
        const self = @fieldParentPtr(Self, "step", step);
        var b = self.builder;
        const image_path = self.image_path;
        const image_dir = b.fmt("{s}/image_directory", .{b.cache_root});
        const cwd = std.fs.cwd();

        if (cwd.deleteFile(image_path))
        {
            print("Already existent ISO deleted\n", .{});
        }
        else |err|
        {
            switch (err)
            {
                error.FileNotFound => print("{s} not found. Not doing anything...\n", .{image_path}),
                else => panic("ni: {}\n", .{err}),
            }
        }

        print("Creating image directory...\n", .{});

        try cwd.makePath(b.fmt("{s}/EFI/BOOT", .{image_dir}));

        const expected_limine_path = b.fmt("limine_{}.{}", .{limine_version.major, limine_version.minor});

        const limine_dir = blk:
        {
            if (cwd.openDir(expected_limine_path, .{})) |dir|
            {
                break :blk dir;
            }
            else |open_err|
            {
                const minimal_limine_major_version = 2;
                var minor_version: u64 = 0;
                var found_old_limine_versions = false;
                while (minor_version <= most_updated_limine_minor_version) : (minor_version += 1)
                {
                    if (cwd.access(b.fmt("limine_{}.{}", .{minimal_limine_major_version, minor_version}), .{})) |foo|
                    {
                        if (minimal_limine_major_version != limine_version.major or minor_version != limine_version.minor)
                        {
                            found_old_limine_versions = true;
                            panic("We should remove this limine repo\n", .{});
                        }
                    }
                    else |access_err| { }
                }

                if (found_old_limine_versions)
                {
                    print("Removed old limine versions...\n", .{});
                }

                print("About to Git clone the limine repo\n", .{});

                const tag = try std.fmt.allocPrintZ(b.allocator, "--branch=v{}.{}", .{limine_version.major, limine_version.minor});
                const limine_path_z = try std.fmt.allocPrintZ(b.allocator, "{s}", .{expected_limine_path});
                const args = [_:null]?[*:0]const u8 {"git", "clone", "https://github.com/limine-bootloader/limine.git", "--branch=v2.35-binary", "--depth=1", "limine_2.35"};

                try execute_program(args[0..:null]);

                const dir = try cwd.openDir(expected_limine_path, .{});
                break :blk dir;
            }
        };

        print("Existent directory... Keep going\n", .{});

        const limine_cfg_dir = try cwd.openDir("src/kernel", .{});
        const image_dir_handle = try cwd.openDir(image_dir, .{});

        const cache_dir = try cwd.openDir(b.cache_root, .{});
        try copy_file(image_dir_handle, cache_dir, "kernel_x86_64.elf");
        try copy_file(image_dir_handle, limine_dir, "limine-eltorito-efi.bin");
        try copy_file(image_dir_handle, limine_dir, "limine-cd.bin");
        try copy_file(image_dir_handle, limine_dir, "limine.sys");
        try copy_file(image_dir_handle, limine_cfg_dir, "limine.cfg");

        const efi_boot_dir = try image_dir_handle.openDir("EFI/BOOT", .{});
        try copy_file(efi_boot_dir, limine_cfg_dir, "limine.cfg");
        try copy_file(efi_boot_dir, limine_dir, "BOOTX64.EFI");

        print("Making ISO image of the kernel with XORRISO...\n", .{});
        const xorriso = [_:null]?[*:0]const u8 {"xorriso", "-as", "mkisofs", "-b", "limine-cd.bin", "-no-emul-boot", "-boot-load-size", "4", "-boot-info-table", "-part_like_isohybrid", "-eltorito-alt-boot", "-e", "limine-eltorito-efi.bin", "-no-emul-boot", "-isohybrid-gpt-basdat", "zig-cache/image_directory", "-o", "zig-cache/kernel.iso"};
        try execute_program(xorriso[0..:null]);

        print("Installing limine in kernel image...\n", .{});
        const limine_install = [_:null]?[*:0]const u8 {"limine_2.35/limine-install", "zig-cache/kernel.iso"};
        try execute_program(limine_install[0..:null]);
    }

    fn create(b: *Builder, kernel: *std.build.LibExeObjStep, image_path: []const u8) *Self
    {
        var self = b.allocator.create(LimineImage) catch @panic("out of memory");
        self.* = Self
        {
            .step = std.build.Step.init(.Custom, "limine_image", b.allocator, LimineImage.make),
            .builder = b,
            .kernel_step = kernel,
            .image_path = image_path,
        };
        self.step.dependOn(&kernel.step);

        return self;
    }

    const Self = @This();
};


fn debug_qemu_x86_64_bios(b: *Builder, comptime qemu_command: []const []const u8) *std.build.RunStep
{
    const debug_remotely_with_gdb: []const u8 = "-S";
    const freeze_cpu_at_startup: []const u8 = "-s";

    const run_step = b.addSystemCommand(qemu_command ++ &[_][]const u8 {"-S", "-s"});

    const run_command = b.step("qemu", "Run on x86_64 with Limine BIOS bootloader");
    run_command.dependOn(&run_step.step);

    return run_step;
}


fn run_qemu_x86_64_bios(b: *Builder, comptime qemu_command: []const []const u8) *std.build.RunStep
{
    const run_step = b.addSystemCommand(qemu_command);

    const run_command = b.step("run", "Run on x86_64 with Limine BIOS bootloader");
    run_command.dependOn(&run_step.step);

    return run_step;
}

fn debug_with_gdb(b: *Builder, kernel_path: []const u8) *std.build.RunStep
{
    const cmd = &[_][]const u8
    {
        "x86_64-elf-gdb",
        kernel_path,
        "-ex",
        "target remote localhost:1234",
    };

    const debug_step = b.addSystemCommand(cmd);

    const debug_command = b.step("gdb", "Debug x86_64 kernel with GDB");
    debug_command.dependOn(&debug_step.step);

    return debug_step;
}

pub fn build(b: *std.build.Builder) void
{
    const kernel = stivale2_kernel(b, .x86_64);
    const cache_root = "zig-cache";
    const image_path = cache_root ++ "/kernel.iso";
    var limine_image = LimineImage.create(b, kernel, image_path);
    b.default_step.dependOn(&limine_image.step);

    const base_qemu_command = &[_][]const u8
    {
        "qemu-system-x86_64",
        "-cdrom", image_path,
        "-serial", "stdio",
        "-display", "none",
        "-m", "4G",
        "-machine", "q35",
    };

    const qemu_run = run_qemu_x86_64_bios(b, base_qemu_command[0..]);
    qemu_run.step.dependOn(&limine_image.step);

    const qemu_debug = debug_qemu_x86_64_bios(b, base_qemu_command[0..]);
    qemu_debug.step.dependOn(&limine_image.step);

    const debug_gdb = debug_with_gdb(b, kernel.getOutputPath());
    debug_gdb.step.dependOn(&limine_image.step);
}
