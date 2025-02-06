#!/bin/bash

# Функция для генерации случайного 4-значного числа с неповторяющимися цифрами
generate_number() {
    digits=($(shuf -i 0-9))
    echo "${digits[0]}${digits[1]}${digits[2]}${digits[3]}"
}

# Проверка валидности введенного пользователем числа
is_valid_number() {
    local input="$1"
    [[ "$input" =~ ^[0-9]{4}$ ]] || return 1
    local unique_digits=$(echo "$input" | grep -o . | sort -u | tr -d '\n')
    [[ ${#unique_digits} -eq 4 ]] || return 1
    return 0
}

# Подсчет быков и коров
count_bulls_and_cows() {
    local guess="$1"
    local bulls=0
    local cows=0
    for i in {0..3}; do
        if [[ ${guess:$i:1} == ${secret_number:$i:1} ]]; then
            ((bulls++))
        elif [[ $secret_number == *${guess:$i:1}* ]]; then
            ((cows++))
        fi
    done
    echo "$bulls $cows"
}

trap 'echo "\nДля выхода введите q или Q."' SIGINT

secret_number=$(generate_number)
declare -a history
attempt=0

cat <<EOL
********************************************************************************
* Я загадал 4-значное число с неповторяющимися цифрами. На каждом ходу делайте *
* попытку отгадать загаданное число. Попытка - это 4-значное число с           *
* неповторяющимися цифрами.                                                    *
********************************************************************************
EOL

while true; do
    read -p "Попытка $((++attempt)): " user_input

    if [[ "$user_input" =~ ^[qQ]$ ]]; then
        echo "Выход из игры."
        exit 1
    fi

    if ! is_valid_number "$user_input"; then
        echo "Ошибка: Введите 4-значное число с неповторяющимися цифрами."
        ((attempt--))
        continue
    fi

    read bulls cows <<< $(count_bulls_and_cows "$user_input")
    echo "Коров - $cows, Быков - $bulls"
    history+=("$attempt. $user_input (Коров - $cows Быков - $bulls)")

    echo -e "\nИстория ходов:"
    printf "%s\n" "${history[@]}"

    if [[ "$bulls" -eq 4 ]]; then
        echo "Поздравляем! Вы угадали число: $secret_number"
        exit 0
    fi
done