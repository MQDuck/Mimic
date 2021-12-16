import math


def calculate_probability_table(trait_weights: [int], trait_counts: [int], max_roll: int) -> [int]:
    if len(trait_weights) != len(trait_counts):
        raise ValueError

    weight_sum = sum(trait_weights[i] * trait_counts[i] for i in range(len(trait_weights)))

    def weight_range(weight: int) -> int:
        return math.ceil(max_roll * weight / weight_sum)

    table = [0]

    for i in range(len(trait_weights)):
        for j in range(trait_counts[i]):
            table.append(table[-1] + weight_range(trait_weights[i]))

    return table[1:-1]


if __name__ == '__main__':
    def main():
        probability_weights = [8, 4, 1]
        trait_counts = [10, 6, 2]

        table = calculate_probability_table(probability_weights, trait_counts, 2 ** 48 - 1)
        s = '[\n' + ''.join(f'    {table[i]},\n' for i in range(len(table)))[:-2] + '\n]'
        print(s)


    main()
