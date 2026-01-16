const std = @import("std");

const f32x16 = @Vector(16, f32);
const i32x16 = @Vector(16, i32);
const f32x8 = @Vector(8, f32);
const i32x8 = @Vector(8, i32);
const f32x4 = @Vector(4, f32);
const i32x4 = @Vector(4, i32);

const mask_lx4: i32x4 = .{ 0, 1, 2, 3 };
const mask_hx4: i32x4 = .{ 4, 5, 6, 7 };
const mask_lhx8: i32x8 = .{ 0, 1, 2, 3, -1, -2, -3, -4 };
const mask_lx8: i32x8 = .{ 0, 1, 2, 3, 4, 5, 6, 7 };
const mask_hx8: i32x8 = .{ 8, 9, 10, 11, 12, 13, 14, 15 };
const mask_lhx16: i32x16 = .{ 0, 1, 2, 3, 4, 5, 6, 7, -1, -2, -3, -4, -5, -6, -7, -8 };

fn vcvtps2dq(x: f32x8) i32x8 {
    return asm ("vcvtps2dq %[x], %[result]"
        : [result] "=x" (-> i32x8),
        : [x] "x" (x),
    );
}

fn fcvtns(x: f32x8) i32x8 {
    const low: f32x4 = @shuffle(f32, x, undefined, mask_lx4);
    const high: f32x4 = @shuffle(f32, x, undefined, mask_hx4);

    const low_i: i32x4 = asm ("fcvtns %[result].4s, %[x].4s"
        : [result] "=w" (-> i32x4),
        : [x] "w" (low),
    );
    const high_i: i32x4 = asm ("fcvtns %[result].4s, %[x].4s"
        : [result] "=w" (-> i32x4),
        : [x] "w" (high),
    );

    return @shuffle(i32, low_i, high_i, mask_lhx8);
}

fn intFromFloatRound8x(x: f32x8) i32x8 {
    return switch (@import("builtin").cpu.arch) {
        .x86_64 => vcvtps2dq(x),
        .aarch64 => fcvtns(x),
        else => @intFromFloat(@round(x)),
    };
}

fn intFromFloatRound(x: anytype) @Vector(@typeInfo(@TypeOf(x)).vector.len, i32) {
    return switch (@typeInfo(@TypeOf(x)).vector.len) {
        8 => intFromFloatRound8x(x),
        16 => {
            const low: f32x8 = @shuffle(f32, x, undefined, mask_lx8);
            const high: f32x8 = @shuffle(f32, x, undefined, mask_hx8);
            const low_i: i32x8 = intFromFloatRound8x(low);
            const high_i: i32x8 = intFromFloatRound8x(high);
            return @shuffle(i32, low_i, high_i, mask_lhx16);
        },
        else => @compileError("Unsupported vector length"),
    };
}

pub fn main() !void {
    const x1: f32x16 = .{ 1.0, 2.5, 3.5, 4.2, 5.9, 6.1, 7.5, 8.5, 9.1, 10.2, 11.3, 12.5, 13.5, 14.6, 15.7, 16.8 };
    const y1: i32x16 = @intFromFloat(@round(x1));
    const y2: i32x16 = intFromFloatRound(x1);

    const vec_len = @typeInfo(f32x16).vector.len;
    std.debug.print("Vector length: {}\n", .{vec_len});

    std.debug.print("y1: {}\n", .{y1});
    std.debug.print("y2: {}\n", .{y2});
}
