; Test 32-bit floating-point strict subtraction.
;
; RUN: llc < %s -mtriple=s390x-linux-gnu -mcpu=z10 \
; RUN:   | FileCheck -check-prefix=CHECK -check-prefix=CHECK-SCALAR %s
; RUN: llc < %s -mtriple=s390x-linux-gnu -mcpu=z14 | FileCheck %s

declare float @foo()
declare half @llvm.experimental.constrained.fsub.f16(half, half, metadata, metadata)
declare float @llvm.experimental.constrained.fsub.f32(float, float, metadata, metadata)

; Check register subtraction.
define half @f0(half %f1, half %f2) #0 {
; CHECK-LABEL: f0:
; CHECK: brasl %r14, __extendhfsf2@PLT
; CHECK: brasl %r14, __extendhfsf2@PLT
; CHECK: sebr %f0, %f9
; CHECK: brasl %r14, __truncsfhf2@PLT
; CHECK: br %r14
  %res = call half @llvm.experimental.constrained.fsub.f16(
                        half %f1, half %f2,
                        metadata !"round.dynamic",
                        metadata !"fpexcept.strict") #0
  ret half %res
}

; Check register subtraction.
define float @f1(float %f1, float %f2) #0 {
; CHECK-LABEL: f1:
; CHECK: sebr %f0, %f2
; CHECK: br %r14
  %res = call float @llvm.experimental.constrained.fsub.f32(
                        float %f1, float %f2,
                        metadata !"round.dynamic",
                        metadata !"fpexcept.strict") #0
  ret float %res
}

; Check the low end of the SEB range.
define float @f2(float %f1, ptr %ptr) #0 {
; CHECK-LABEL: f2:
; CHECK: seb %f0, 0(%r2)
; CHECK: br %r14
  %f2 = load float, ptr %ptr
  %res = call float @llvm.experimental.constrained.fsub.f32(
                        float %f1, float %f2,
                        metadata !"round.dynamic",
                        metadata !"fpexcept.strict") #0
  ret float %res
}

; Check the high end of the aligned SEB range.
define float @f3(float %f1, ptr %base) #0 {
; CHECK-LABEL: f3:
; CHECK: seb %f0, 4092(%r2)
; CHECK: br %r14
  %ptr = getelementptr float, ptr %base, i64 1023
  %f2 = load float, ptr %ptr
  %res = call float @llvm.experimental.constrained.fsub.f32(
                        float %f1, float %f2,
                        metadata !"round.dynamic",
                        metadata !"fpexcept.strict") #0
  ret float %res
}

; Check the next word up, which needs separate address logic.
; Other sequences besides this one would be OK.
define float @f4(float %f1, ptr %base) #0 {
; CHECK-LABEL: f4:
; CHECK: aghi %r2, 4096
; CHECK: seb %f0, 0(%r2)
; CHECK: br %r14
  %ptr = getelementptr float, ptr %base, i64 1024
  %f2 = load float, ptr %ptr
  %res = call float @llvm.experimental.constrained.fsub.f32(
                        float %f1, float %f2,
                        metadata !"round.dynamic",
                        metadata !"fpexcept.strict") #0
  ret float %res
}

; Check negative displacements, which also need separate address logic.
define float @f5(float %f1, ptr %base) #0 {
; CHECK-LABEL: f5:
; CHECK: aghi %r2, -4
; CHECK: seb %f0, 0(%r2)
; CHECK: br %r14
  %ptr = getelementptr float, ptr %base, i64 -1
  %f2 = load float, ptr %ptr
  %res = call float @llvm.experimental.constrained.fsub.f32(
                        float %f1, float %f2,
                        metadata !"round.dynamic",
                        metadata !"fpexcept.strict") #0
  ret float %res
}

; Check that SEB allows indices.
define float @f6(float %f1, ptr %base, i64 %index) #0 {
; CHECK-LABEL: f6:
; CHECK: sllg %r1, %r3, 2
; CHECK: seb %f0, 400(%r1,%r2)
; CHECK: br %r14
  %ptr1 = getelementptr float, ptr %base, i64 %index
  %ptr2 = getelementptr float, ptr %ptr1, i64 100
  %f2 = load float, ptr %ptr2
  %res = call float @llvm.experimental.constrained.fsub.f32(
                        float %f1, float %f2,
                        metadata !"round.dynamic",
                        metadata !"fpexcept.strict") #0
  ret float %res
}

; Check that subtractions of spilled values can use SEB rather than SEBR.
define float @f7(ptr %ptr0) #0 {
; CHECK-LABEL: f7:
; CHECK: brasl %r14, foo@PLT
; CHECK-SCALAR: seb %f0, 16{{[04]}}(%r15)
; CHECK: br %r14
  %ptr1 = getelementptr float, ptr %ptr0, i64 2
  %ptr2 = getelementptr float, ptr %ptr0, i64 4
  %ptr3 = getelementptr float, ptr %ptr0, i64 6
  %ptr4 = getelementptr float, ptr %ptr0, i64 8
  %ptr5 = getelementptr float, ptr %ptr0, i64 10
  %ptr6 = getelementptr float, ptr %ptr0, i64 12
  %ptr7 = getelementptr float, ptr %ptr0, i64 14
  %ptr8 = getelementptr float, ptr %ptr0, i64 16
  %ptr9 = getelementptr float, ptr %ptr0, i64 18
  %ptr10 = getelementptr float, ptr %ptr0, i64 20

  %val0 = load float, ptr %ptr0
  %val1 = load float, ptr %ptr1
  %val2 = load float, ptr %ptr2
  %val3 = load float, ptr %ptr3
  %val4 = load float, ptr %ptr4
  %val5 = load float, ptr %ptr5
  %val6 = load float, ptr %ptr6
  %val7 = load float, ptr %ptr7
  %val8 = load float, ptr %ptr8
  %val9 = load float, ptr %ptr9
  %val10 = load float, ptr %ptr10

  %ret = call float @foo() #0

  %sub0 = call float @llvm.experimental.constrained.fsub.f32(
                        float %ret, float %val0,
                        metadata !"round.dynamic",
                        metadata !"fpexcept.strict") #0
  %sub1 = call float @llvm.experimental.constrained.fsub.f32(
                        float %sub0, float %val1,
                        metadata !"round.dynamic",
                        metadata !"fpexcept.strict") #0
  %sub2 = call float @llvm.experimental.constrained.fsub.f32(
                        float %sub1, float %val2,
                        metadata !"round.dynamic",
                        metadata !"fpexcept.strict") #0
  %sub3 = call float @llvm.experimental.constrained.fsub.f32(
                        float %sub2, float %val3,
                        metadata !"round.dynamic",
                        metadata !"fpexcept.strict") #0
  %sub4 = call float @llvm.experimental.constrained.fsub.f32(
                        float %sub3, float %val4,
                        metadata !"round.dynamic",
                        metadata !"fpexcept.strict") #0
  %sub5 = call float @llvm.experimental.constrained.fsub.f32(
                        float %sub4, float %val5,
                        metadata !"round.dynamic",
                        metadata !"fpexcept.strict") #0
  %sub6 = call float @llvm.experimental.constrained.fsub.f32(
                        float %sub5, float %val6,
                        metadata !"round.dynamic",
                        metadata !"fpexcept.strict") #0
  %sub7 = call float @llvm.experimental.constrained.fsub.f32(
                        float %sub6, float %val7,
                        metadata !"round.dynamic",
                        metadata !"fpexcept.strict") #0
  %sub8 = call float @llvm.experimental.constrained.fsub.f32(
                        float %sub7, float %val8,
                        metadata !"round.dynamic",
                        metadata !"fpexcept.strict") #0
  %sub9 = call float @llvm.experimental.constrained.fsub.f32(
                        float %sub8, float %val9,
                        metadata !"round.dynamic",
                        metadata !"fpexcept.strict") #0
  %sub10 = call float @llvm.experimental.constrained.fsub.f32(
                        float %sub9, float %val10,
                        metadata !"round.dynamic",
                        metadata !"fpexcept.strict") #0

  ret float %sub10
}

attributes #0 = { strictfp }
