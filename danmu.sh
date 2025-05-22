#!/bin/sh

# 警告：纯 shell/awk JSON 解析。脆弱。确保 Unix (LF) 行尾符。

OUTPUT_FILENAME="danmaku_converted_output.xml"
HISTORY_FILENAME="影视列表.txt" 

p5_fixed_default="1742618977"
p6_fixed_default="0"
p7_fixed_default="0"
p8_fixed_default="26732601000067074"
p9_fixed_default="1"
color_fixed_decimal="16777215" 

C_RESET='\033[0m'
C_BOLD='\033[1m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_MAGENTA='\033[0;35m'
C_CYAN='\033[0;36m'
C_WHITE='\033[0;37m'

TITLE_COLOR="${C_BOLD}${C_CYAN}"
STEP_COLOR="${C_BOLD}${C_BLUE}"
PROMPT_COLOR="${C_YELLOW}"
INFO_COLOR="${C_CYAN}"
SUCCESS_COLOR="${C_GREEN}"
WARNING_COLOR="${C_YELLOW}"
ERROR_COLOR="${C_RED}"
DEBUG_COLOR="${C_MAGENTA}"
NC="${C_RESET}"

printf "${TITLE_COLOR}=====================================${NC}\n"
printf "${TITLE_COLOR}   弹幕格式转换与下载脚本 v5.2 ${NC}\n" # 版本号微调
printf "${TITLE_COLOR}=====================================${NC}\n\n"

printf "${STEP_COLOR}步骤 1: 选择或输入影视名称${NC}\n"

show_name=""
printf "${PROMPT_COLOR}操作选项:\n"
printf "  1) 从已有影视列表中选择 (%s)\n" "$HISTORY_FILENAME"
printf "  2) 输入新的影视名称\n"
printf "请输入选项 (1 或 2): ${NC}"
read -r name_choice

if [ "$name_choice" = "1" ]; then
    if [ ! -f "$HISTORY_FILENAME" ] || [ ! -s "$HISTORY_FILENAME" ]; then 
        printf "${WARNING_COLOR}警告: 影视列表 (%s) 为空或不存在，请先添加新的影视名称。${NC}\n" "$HISTORY_FILENAME"
        name_choice="2" 
    else
        printf "${INFO_COLOR}从列表中选择影视名称:${NC}\n"
        awk '{printf "  %s) %s\n", NR, $0}' "$HISTORY_FILENAME"
        printf "${PROMPT_COLOR}请输入序号: ${NC}"
        read -r selection_num

        if ! echo "$selection_num" | grep -q '^[0-9][0-9]*$'; then
            printf "${ERROR_COLOR}错误: 输入的序号无效。将引导您输入新名称。${NC}\n"
            name_choice="2"
        else
            total_shows=$(grep -c . "$HISTORY_FILENAME" 2>/dev/null || echo 0) 
            if [ "$selection_num" -ge 1 ] && [ "$selection_num" -le "$total_shows" ]; then
                show_name=$(sed -n "${selection_num}p" "$HISTORY_FILENAME")
                printf "${INFO_COLOR}已选择影视: %s${NC}\n" "$show_name"
            else
                printf "${ERROR_COLOR}错误: 无效的序号选择。将引导您输入新名称。${NC}\n"
                name_choice="2"
            fi
        fi
    fi
fi

if [ "$name_choice" = "2" ]; then
    printf "${PROMPT_COLOR}请输入新的影视名称: ${NC}"
    read -r new_show_name
    if [ -z "$new_show_name" ]; then
        printf "${ERROR_COLOR}错误：影视名称不能为空。${NC}\n" >&2
        exit 1
    fi
    show_name="$new_show_name"
    
    is_in_history=1 
    if [ -f "$HISTORY_FILENAME" ]; then 
        if grep -qFx "$show_name" "$HISTORY_FILENAME"; then
            is_in_history=0 
        fi
    fi

    if [ "$is_in_history" -ne 0 ]; then 
        # --- 修改点在这里 ---
        # 如果历史文件存在且有内容，先追加一个换行符，以确保新条目另起一行
        if [ -f "$HISTORY_FILENAME" ] && [ -s "$HISTORY_FILENAME" ]; then
            printf "\n" >> "$HISTORY_FILENAME" 
        fi
        # 然后追加新的影视名（echo会自动在其后添加换行符）
        echo "$show_name" >> "$HISTORY_FILENAME" 
        # --- 修改结束 ---
        
        if [ $? -eq 0 ]; then
            printf "${INFO_COLOR}信息: '%s' 已添加到影视列表 (%s)。${NC}\n" "$show_name" "$HISTORY_FILENAME"
        else
            printf "${ERROR_COLOR}错误: 无法将 '%s' 添加到影视列表 (%s)。请检查目录写入权限。${NC}\n" "$show_name" "$HISTORY_FILENAME" >&2
        fi
    fi
fi

if [ -z "$show_name" ]; then
    printf "${ERROR_COLOR}错误: 未能确定影视名称。脚本退出。${NC}\n" >&2
    exit 1
fi

printf "\n${STEP_COLOR}步骤 2: 输入分集信息与准备输出路径${NC}\n"
if [ ! -d "$show_name" ]; then
    printf "${INFO_COLOR}信息: 文件夹 '%s' 不存在，正在创建...${NC}\n" "$show_name"
    mkdir -p "$show_name" 
    if [ $? -ne 0 ]; then
        printf "${ERROR_COLOR}错误：创建文件夹 '%s' 失败。请检查权限或名称是否有效。${NC}\n" "$show_name" >&2
        exit 1
    else
        printf "${SUCCESS_COLOR}信息: 文件夹 '%s' 创建成功。${NC}\n" "$show_name"
    fi
else
    printf "${INFO_COLOR}信息: 文件夹 '%s' 已存在。${NC}\n" "$show_name"
fi

printf "${PROMPT_COLOR}请输入集数 (例如 01, E02。如果是电影，请输入 0 ): ${NC}"
read -r episode_number
if [ -z "$episode_number" ]; then
    printf "${ERROR_COLOR}错误：集数不能为空。${NC}\n" >&2
    exit 1
fi

output_filename_base="${show_name}/${show_name}"
if [ "$episode_number" = "0" ]; then
    output_filename="${output_filename_base}.xml" 
    printf "${INFO_COLOR}信息: 检测到电影模式。${NC}\n"
else
    output_filename="${output_filename_base}-${episode_number}.xml"
fi
printf "${INFO_COLOR}信息: 输出结果将保存到文件 -> %s${NC}\n\n" "$output_filename"


printf "${STEP_COLOR}步骤 3: 选择输入链接类型${NC}\n"
printf "${PROMPT_COLOR}请选择输入链接的类型：\n"
printf "  1) 直接 JSON 弹幕下载链接\n"
printf "  2) 视频网页链接 (爱奇艺 / 腾讯 / 优酷)\n"
printf "请输入选项 (1 或 2): ${NC}"
read -r input_type_choice

final_danmaku_download_url="" 

printf "\n${STEP_COLOR}步骤 4: 构造最终下载链接${NC}\n"
if [ "$input_type_choice" = "1" ]; then
    printf "${PROMPT_COLOR}请输入 JSON 弹幕下载链接: ${NC}"
    read -r final_danmaku_download_url
    printf "${INFO_COLOR}信息: 使用直接JSON弹幕链接。${NC}\n"
elif [ "$input_type_choice" = "2" ]; then
    printf "${PROMPT_COLOR}请输入视频网页链接 (爱奇艺 / 腾讯 / 优酷): ${NC}"
    read -r video_page_url

    if [ -z "$video_page_url" ]; then
        printf "${ERROR_COLOR}错误：未输入视频网页链接。${NC}\n" >&2
        exit 1
    fi

    if echo "$video_page_url" | grep -q -E "iqiyi\.com|v\.qq\.com"; then
        printf "${INFO_COLOR}信息: 检测到爱奇艺或腾讯视频链接，正在处理...${NC}\n"
        base_video_url="${video_page_url%%\?*}"
        final_danmaku_download_url="https://dmku.hls.one/?ac=dm&url=${base_video_url}"
    elif echo "$video_page_url" | grep -q "youku\.com"; then
        printf "${INFO_COLOR}信息: 检测到优酷链接，正在处理...${NC}\n"
        extracted_youku_id=""
        if echo "$video_page_url" | grep -q "vid="; then
            extracted_youku_id=$(echo "$video_page_url" | sed -n 's/.*vid=\([^&]*\).*/\1/p')
        fi
        if [ -z "$extracted_youku_id" ] && echo "$video_page_url" | grep -q "v_show/id_"; then
            extracted_youku_id=$(echo "$video_page_url" | sed -n 's|.*v_show/id_\([^.]*\).*|\1|p')
        fi

        if [ -n "$extracted_youku_id" ]; then
            youku_target_segment_for_dmku="http://v.youku.com/v_show/id_${extracted_youku_id}.html"
            final_danmaku_download_url="https://dmku.hls.one/?ac=dm&url=${youku_target_segment_for_dmku}"
        else
            printf "${WARNING_COLOR}警告：无法从优酷链接中提取有效的视频ID。将尝试使用原始链接进行通用拼接。${NC}\n" >&2
            final_danmaku_download_url="https://dmku.hls.one/?ac=dm&url=${video_page_url}"
        fi
    else
        printf "${WARNING_COLOR}警告：无法明确识别视频网站，将尝试使用通用拼接方式。${NC}\n" >&2
        final_danmaku_download_url="https://dmku.hls.one/?ac=dm&url=${video_page_url}"
    fi
else
    printf "${ERROR_COLOR}错误：无效的选项 '%s'。${NC}\n" "$input_type_choice" >&2
    exit 1
fi

if [ -z "$final_danmaku_download_url" ]; then
    printf "${ERROR_COLOR}错误：未能生成有效的弹幕下载链接。${NC}\n" >&2
    exit 1
fi
#printf "${DEBUG_COLOR}调试: 最终下载链接 -> %s${NC}\n" "$final_danmaku_download_url"

printf "\n${STEP_COLOR}步骤 5: 下载弹幕内容${NC}\n"
printf "${INFO_COLOR}正在下载 (超时时间 18 秒)...${NC}\n"
user_agent_string="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
json_content=$(curl -sSLk -A "$user_agent_string" -m 18 "$final_danmaku_download_url")
curl_exit_status=$?

if [ $curl_exit_status -ne 0 ]; then
    if [ $curl_exit_status -eq 28 ]; then 
        printf "${ERROR_COLOR}错误：下载超时，服务器繁忙或链接无效 (超过18秒未响应)。${NC}\n" >&2
    else
        printf "${ERROR_COLOR}错误：下载弹幕内容失败 (curl 错误码: %s)。${NC}\n" "$curl_exit_status" >&2
    fi
    exit 1
fi
if [ -z "$json_content" ]; then
    printf "${ERROR_COLOR}错误：下载成功但内容为空。服务器可能未返回有效数据。${NC}\n" >&2
    exit 1
fi
printf "${SUCCESS_COLOR}下载成功!${NC}\n"

printf "\n${STEP_COLOR}步骤 6: 检测格式并进行转换${NC}\n"
first_char=$(echo "$json_content" | sed -e 's/^[[:space:]]*//' | cut -c1)
format_type="unknown"

if [ "$first_char" = "[" ]; then
    format_type="new"
    printf "${INFO_COLOR}检测到弹幕数据为新格式 (JSON 数组)，开始转换...${NC}\n"
elif [ "$first_char" = "{" ]; then
    format_type="old"
    printf "${INFO_COLOR}检测到弹幕数据为旧格式 (JSON 对象)，开始转换...${NC}\n"
else
    printf "${ERROR_COLOR}错误：无法识别下载的弹幕数据是什么JSON顶层结构。内容可能不是有效的JSON。${NC}\n" >&2
    printf "${DEBUG_COLOR}调试信息：获取到的内容前200字符如下：${NC}\n" >&2
    echo "$json_content" | head -c 200 >&2 
    printf "\n${DEBUG_COLOR}<--- 内容预览结束 (或已达200字符)${NC}\n" >&2
    exit 1
fi

{
    printf "%s\n" '<?xml version="1.0" encoding="utf-8"?>'
    printf "%s\n" '<i>'

    if [ "$format_type" = "old" ]; then
        danmuku_array_str_old=$(echo "$json_content" | sed -n 's/.*"danmuku":\(\[\[.*\]\]\).*/\1/p')
        if [ -z "$danmuku_array_str_old" ]; then
            printf "${ERROR_COLOR}错误（旧格式解析）：核心 \"danmuku\" 数组未找到。${NC}\n" >&2
        else
            items_str_old=$(echo "$danmuku_array_str_old" | sed 's/^\[//; s/\]$//')
            echo "$items_str_old" | sed 's/\],\[/\
/g' | awk -v p5f="$p5_fixed_default" -v p6f="$p6_fixed_default" -v p7f="$p7_fixed_default" \
                     -v p8f="$p8_fixed_default" -v p9f="$p9_fixed_default" \
                     -v param_fixed_color="$color_fixed_decimal" '
                BEGIN { FS=","; }
                function trim_and_strip_quotes(s_in) {
                    sub(/^[ \t\r\n]+/, "", s_in); sub(/[ \t\r\n]+$/, "", s_in);
                    sub(/^"/, "", s_in); sub(/"$/, "", s_in);
                    return s_in;
                }
                function escape_xml_simplified_awk(text,    local_perc_r, local_amp_r) {
                    local_perc_r = "%%"; gsub(/%/, local_perc_r, text);
                    local_amp_r  = "&amp;"; gsub(/&/, local_amp_r, text);
                    return text;
                }
                { 
                    current_line_content = $0;
                    sub(/^\[/, "", current_line_content); sub(/\]$/, "", current_line_content);
                    delete fields_array; 
                    num_fields = split(current_line_content, fields_array, FS);

                    var_p1_timestamp = ""; if (num_fields >= 1) var_p1_timestamp = trim_and_strip_quotes(fields_array[1]);
                    var_mode_str_from_json = ""; if (num_fields >= 2) var_mode_str_from_json = trim_and_strip_quotes(fields_array[2]);
                    var_font_size_str_from_json = ""; if (num_fields >= 4) var_font_size_str_from_json = trim_and_strip_quotes(fields_array[4]);
                    var_text_content_raw_cleaned = "";
                    if (num_fields >= 5) { 
                        var_text_content_raw_cleaned = fields_array[5];
                        for (i = 6; i <= num_fields; i++) { var_text_content_raw_cleaned = var_text_content_raw_cleaned "," fields_array[i]; }
                        var_text_content_raw_cleaned = trim_and_strip_quotes(var_text_content_raw_cleaned);
                    }
                    var_p2_mode_val="1"; 
                    if (var_mode_str_from_json == "top" || var_mode_str_from_json == "5") { var_p2_mode_val = "5"; }
                    else if (var_mode_str_from_json == "bottom" || var_mode_str_from_json == "4") { var_p2_mode_val = "4"; }
                    else if (var_mode_str_from_json == "right" || var_mode_str_from_json == "1") { var_p2_mode_val = "1"; }
                    var_p3_font_size_val = var_font_size_str_from_json;
                    sub(/px$/, "", var_p3_font_size_val); sub(/PX$/, "", var_p3_font_size_val);
                    var_p4_color_decimal_val = param_fixed_color;
                    var_text_content_escaped_val = escape_xml_simplified_awk(var_text_content_raw_cleaned);
                    printf "        <d p=\"%s,%s,%s,%s,%s,%s,%s,%s,%s\">%s</d>\n", 
                        var_p1_timestamp, var_p2_mode_val, var_p3_font_size_val, var_p4_color_decimal_val,
                        p5f, p6f, p7f, p8f, p9f, var_text_content_escaped_val;
                }
            '
        fi

    elif [ "$format_type" = "new" ]; then
        echo "$json_content" | sed 's/^\[//; s/\]$//; s/},{/}\
{/g' | awk -v p5def="$p5_fixed_default" -v p6def="$p6_fixed_default" -v p7def="$p7_fixed_default" \
            -v p8def="$p8_fixed_default" -v p9def="$p9_fixed_default" \
            -v param_fixed_color="$color_fixed_decimal" '
            BEGIN { FS="\""; }
            function escape_xml_simplified_awk_new(text, local_perc_r, local_amp_r) {
                local_perc_r = "%%"; gsub(/%/, local_perc_r, text);
                local_amp_r  = "&amp;"; gsub(/&/, local_amp_r, text);
                return text;
            }
            function trim_p_field(val) { 
                sub(/^[ \t\r\n]+/, "", val); sub(/[ \t\r\n]+$/, "", val);
                return val;
            }
            {
                if (NF < 8) next; 
                text_val = $4;    
                params_str = $8;  

                delete p_array;
                num_p_fields = split(params_str, p_array, ",");
                if (num_p_fields == 0) next; 

                p1_ts = (num_p_fields >= 1 ? trim_p_field(p_array[1]) : "0");
                mode_str_json = (num_p_fields >= 2 ? trim_p_field(p_array[2]) : "1");
                p3_font_val_json = (num_p_fields >= 3 ? trim_p_field(p_array[3]) : "25");
                p4_color_val = param_fixed_color;

                p5_val = p5def; 
                if (num_p_fields >= 5 && trim_p_field(p_array[5]) ~ /^[0-9]+$/ && length(trim_p_field(p_array[5])) >= 10) {
                    p5_val = int(trim_p_field(p_array[5]) / 1000); 
                }
                
                p6_val = (num_p_fields >= 6 && trim_p_field(p_array[6]) != "" ? trim_p_field(p_array[6]) : p6def);
                p7_val = (num_p_fields >= 7 && trim_p_field(p_array[7]) != "" ? trim_p_field(p_array[7]) : p7def);
                p8_val = (num_p_fields >= 8 && trim_p_field(p_array[8]) != "" ? trim_p_field(p_array[8]) : p8def);
                p9_val = (num_p_fields >= 9 && trim_p_field(p_array[9]) != "" ? trim_p_field(p_array[9]) : p9def);

                p2_mode_val = "1"; 
                if (mode_str_json == "1" || mode_str_json == "right") { p2_mode_val = "1"; }
                else if (mode_str_json == "4" || mode_str_json == "bottom") { p2_mode_val = "4"; }
                else if (mode_str_json == "5" || mode_str_json == "top") { p2_mode_val = "5"; }
                else if (mode_str_json == "0" || mode_str_json == "2") { p2_mode_val = "1"; } 

                sub(/px$/, "", p3_font_val_json); sub(/PX$/, "", p3_font_val_json);
                text_escaped = escape_xml_simplified_awk_new(text_val);
                printf "        <d p=\"%s,%s,%s,%s,%s,%s,%s,%s,%s\">%s</d>\n", 
                    p1_ts, p2_mode_val, p3_font_val_json, p4_color_val,
                    p5_val, p6_val, p7_val, p8_val, p9_val, text_escaped;
            }
        '
    fi

    printf "%s\n" '</i>'

} > "$output_filename"

printf "\n${STEP_COLOR}步骤 7: 操作完成${NC}\n"
if [ $? -eq 0 ] && [ -s "$output_filename" ]; then
    content_lines=$(grep -cvE '^<\?xml|<i|</i' "$output_filename")
    if [ "$content_lines" -gt 0 ]; then
        printf "${SUCCESS_COLOR}转换成功！结果已保存到 %s 文件中。${NC}\n" "$output_filename"
    else
        printf "${WARNING_COLOR}警告：转换已执行，但输出文件 %s 中没有实际的弹幕内容。${NC}\n" "$output_filename"
    fi
else
    printf "${ERROR_COLOR}转换过程中发生错误，或者输出文件 %s 为空或未创建。${NC}\n" "$output_filename"
fi
# 脚本末尾