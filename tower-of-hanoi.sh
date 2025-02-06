#!/bin/bash

# Обработчик SIGINT
trap 'echo "\nДля завершения работы введите \"q\" или \"Q\"."' SIGINT

# Инициализация стеков
declare -a A=(8 7 6 5 4 3 2 1)
declare -a B=()
declare -a C=()

# Переменные
move_count=1

# Функция для отображения текущего состояния стеков
print_stacks() {
    max_height=8
    for ((i=max_height-1; i>=0; i--)); do
        printf "|%s|  |%s|  |%s|\n" \
            "${A[i]:- }" "${B[i]:- }" "${C[i]:- }"
    done
    echo "+-+  +-+  +-+"
    echo " A    B    C"
}

# Функция для проверки победы
check_victory() {
    local -n stack=$1
    local expected=(8 7 6 5 4 3 2 1)
    if [[ "${stack[*]}" == "${expected[*]}" ]]; then
        echo "Поздравляем! Вы выиграли за $((move_count-1)) ходов."
        exit 0
    fi
}

# Функция для выполнения хода
make_move() {
    local from=${1^^}
    local to=${2^^}
    # Проверка имен стеков
    if [[ $from == $to || ${#from} -gt 1 || ${#to} -gt 1 ]]; then
        echo "Ошибка ввода. Повторите попытку."
        return 1
    fi

    # Ссылки на стеки
    local -n src=$from
    local -n dest=$to

    # Проверка на пустоту стека-источника
    if [ ${#src[@]} -eq 0 ]; then
        echo "Стек $from пуст. Повторите попытку."
        return 1
    fi

    # Проверка правил перемещения
    local disk=${src[-1]}
    if [ ${#dest[@]} -gt 0 ] && [ $disk -gt ${dest[-1]} ]; then
        echo "Такое перемещение запрещено!"
        return 1
    fi

    # Перемещение диска
    src=(${src[@]:0:${#src[@]}-1})
    dest+=($disk)

    return 0
}

# Главный цикл
while true; do
    print_stacks
    echo -n "Ход № $move_count (откуда, куда): "
    read -r input

    # Проверка на выход
    if [[ ${input,,} == "q" ]]; then
        exit 1
    fi

    # Разбор ввода
    input=${input^^}
    # Проверяем, был ли ввод через пробел или слитно
    if [[ "$input" =~ ^([ABC])([ABC])$ ]]; then
        arg1="${BASH_REMATCH[1]}"
        arg2="${BASH_REMATCH[2]}"
    elif [[ "$input" =~ ^([ABC])\ ([ABC])$ ]]; then
        arg1="${BASH_REMATCH[1]}"
        arg2="${BASH_REMATCH[2]}"
    else
        echo "Некорректный ввод. Повторите попытку"
        continue
    fi

    # Выполнение хода
    if make_move "${arg1}" "${arg2}"; then
        ((move_count++))
        check_victory B
        check_victory C
    fi

done