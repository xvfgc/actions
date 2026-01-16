const std = @import("std");

const f32x4 = @Vector(4, f32);
const i32x4 = @Vector(4, i32);
const f32x8 = @Vector(8, f32);
const i32x8 = @Vector(8, i32);
const u32x8 = @Vector(8, u32);

fn vcvtps2dq(x: f32x8) i32x8 {
    return asm ("vcvtps2dq %[x], %[result]"
        : [result] "=x" (-> i32x8),
        : [x] "x" (x),
    );
}

fn fcvtns(x: f32x8) i32x8 {
    const low: f32x4 = x[0..4].*;
    const high: f32x4 = x[4..8].*;

    const low_i: i32x4 = asm ("fcvtns %[result].4s, %[x].4s"
        : [result] "=w" (-> i32x4),
        : [x] "w" (low),
    );
    const high_i: i32x4 = asm ("fcvtns %[result].4s, %[x].4s"
        : [result] "=w" (-> i32x4),
        : [x] "w" (high),
    );

    return low_i ++ high_i;
}

fn intFromFloatRound(x: f32x8) i32x8 {
    return switch (@import("builtin").cpu.arch) {
        .x86_64 => vcvtps2dq(x),
        .aarch64 => fcvtns(x),
        // else => @intFromFloat(@round(x)),
        else => unreachable,
    };
}

pub fn main() void {
    const input: f32x8 = [_]f32{ 1.5, 2.5, 3.5, 4.0, 5.9, -6.1, 7.4, -8.8 };
    const result: i32x8 = intFromFloatRound(input);
    std.debug.print("input: {}\n", .{input});
    std.debug.print("Result: {}\n", .{result});
}
