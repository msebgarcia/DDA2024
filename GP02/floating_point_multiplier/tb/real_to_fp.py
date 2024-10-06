import math

def real_to_fp(num : float) -> str:
    if num == 0:
        return "0" * 13

    sign = int(num < 0)
    num = abs(num)
    
    unbiased_exponent = math.floor(math.log2(num))
    normalized_mantissa = num / (2 ** unbiased_exponent) - 1
    
    biased_exponent = unbiased_exponent + 7
    if biased_exponent < 0 or biased_exponent > 15:
        raise ValueError("Number cannot be represented with bias of 7")
    
    binary_mantissa = ""
    for _ in range(8):
        normalized_mantissa *= 2
        if normalized_mantissa >= 1:
            binary_mantissa += "1"
            normalized_mantissa -= 1
        else:
            binary_mantissa += "0"
    
    return f"{sign}_{biased_exponent:04b}_{binary_mantissa}"

in_range_op_data1 = [1.25, 10, -15, -144]
in_range_op_data2 = [2, 25, 15, -0.015625]
result_in_range   = [a * b for a, b in zip(in_range_op_data1, in_range_op_data2)]

fp_d1 = []
fp_d2 = []
fp_res = []
for i in range(len(in_range_op_data1)):
    fp_d1.append(real_to_fp(in_range_op_data1[i]))
    fp_d2.append(real_to_fp(in_range_op_data2[i]))
    fp_res.append(real_to_fp(result_in_range[i]))

assign_1 = "assign data_1_in_range = {"
assign_2 = "assign data_2_in_range = {"
assign_3 = "assign result_in_range = {"
for i in range(len(fp_d1)):
    assign_1 += f"\n    13'b{fp_d1[i]} {',' if (i < len(fp_d1)-1) else ' '} // {in_range_op_data1[i]}"
    assign_2 += f"\n    13'b{fp_d2[i]} {',' if (i < len(fp_d2)-1) else ' '} // {in_range_op_data2[i]}"
    assign_3 += f"\n    13'b{fp_res[i]} {',' if (i < len(fp_res)-1) else ' '} // {result_in_range[i]}"
assign_1 += "\n};"
assign_2 += "\n};"
assign_3 += "\n};"

print(assign_1)
print(assign_2)
print(assign_3)

print("\n----------------------------------------------------------------------------------------------------------\n\tUnderflow")

uflow_data1 = [0.015625, -.5, 0.025, -0.025]
uflow_data2 = [0.015625, -0.015625, 0.5, 0.025]
fp_d1 = []
fp_d2 = []
for i in range(len(in_range_op_data1)):
    fp_d1.append(real_to_fp(uflow_data1[i]))
    fp_d2.append(real_to_fp(uflow_data2[i]))
assign_1 = "assign data_1_underflow = {"
assign_2 = "assign data_2_underflow = {"
for i in range(len(fp_d1)):
    assign_1 += f"\n    13'b{fp_d1[i]} {',' if (i < len(fp_d1)-1) else ' '} // {uflow_data1[i]}"
    assign_2 += f"\n    13'b{fp_d2[i]} {',' if (i < len(fp_d2)-1) else ' '} // {uflow_data2[i]}"
assign_1 += "\n};"
assign_2 += "\n};"

print(assign_1)
print(assign_2)

print("\n----------------------------------------------------------------------------------------------------------\n\tOverflow")

oflow_data1 = [255, 64, -16, 103]
oflow_data2 = [255, -4, -32, 32]
fp_d1 = []
fp_d2 = []
for i in range(len(in_range_op_data1)):
    fp_d1.append(real_to_fp(oflow_data1[i]))
    fp_d2.append(real_to_fp(oflow_data2[i]))
assign_1 = "assign data_1_overflow = {"
assign_2 = "assign data_2_overflow = {"
for i in range(len(fp_d1)):
    assign_1 += f"\n    13'b{fp_d1[i]} {',' if (i < len(fp_d1)-1) else ' '} // {oflow_data1[i]}"
    assign_2 += f"\n    13'b{fp_d2[i]} {',' if (i < len(fp_d2)-1) else ' '} // {oflow_data2[i]}"
assign_1 += "\n};"
assign_2 += "\n};"

print(assign_1)
print(assign_2)

