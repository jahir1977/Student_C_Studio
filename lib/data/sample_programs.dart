import '../models/sample_program.dart';

/// All sample programs from HSC ICT অধ্যায় ৫ (প্রোগ্রামিং ভাষা),
/// grouped by topic, for the Sample Program picker.
///
/// NOTE: "প্রোগ্রাম ৫.৩২ — ইউজার ডিফাইন্ড ফাংশন" requires the
/// FunctionChecker fix (see function_checker.dart) to run
/// successfully in the app, since the current FunctionChecker does
/// not recognise user-defined function calls. Every other program
/// below uses only main()/printf()/scanf()/pow()/sqrt()/strlen()/
/// strcmp(), which are already whitelisted.
const List<SampleProgram> sampleProgramLibrary = [
  // ---------------------------------------------------------------
  // ভেরিয়েবল ও ডেটা টাইপ
  // ---------------------------------------------------------------
  SampleProgram(
    id: 'p5_1_hello_world',
    titleBn: '৫.১ Hello World প্রদর্শন',
    topicTagBn: 'ভেরিয়েবল ও ডেটা টাইপ',
    code: '''#include<stdio.h>
int main()
{
    printf("Hello World!");
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_2_char_data_type',
    titleBn: '৫.২ ক্যারেক্টার ডেটা টাইপ',
    topicTagBn: 'ভেরিয়েবল ও ডেটা টাইপ',
    code: '''#include<stdio.h>
int main()
{
    char grade;
    grade = 'A';
    printf("%c", grade);
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_3_variable_update',
    titleBn: '৫.৩ ভ্যারিয়েবল আপডেট',
    topicTagBn: 'ভেরিয়েবল ও ডেটা টাইপ',
    code: '''#include<stdio.h>
int main()
{
    int number;
    number = 10;
    printf("%d\\n", number);
    number = 25;
    printf("%d", number);
    return 0;
}''',
  ),

  // ---------------------------------------------------------------
  // গাণিতিক অপারেটর ও এক্সপ্রেশন
  // ---------------------------------------------------------------
  SampleProgram(
    id: 'p5_4_sum_difference',
    titleBn: '৫.৪ যোগফল ও বিয়োগফল',
    topicTagBn: 'গাণিতিক অপারেটর ও এক্সপ্রেশন',
    code: '''#include<stdio.h>
int main()
{
    int a, b, sum, difference;
    a = 15;
    b = 5;
    sum = a + b;
    difference = a - b;
    printf("Sum = %d\\n", sum);
    printf("Difference = %d", difference);
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_5_product_quotient',
    titleBn: '৫.৫ গুণফল ও ভাগফল',
    topicTagBn: 'গাণিতিক অপারেটর ও এক্সপ্রেশন',
    code: '''#include<stdio.h>
int main()
{
    float a, b, product, quotient;
    a = 15;
    b = 5;
    product = a * b;
    quotient = a / b;
    printf("Product = %f\\n", product);
    printf("Quotient = %f", quotient);
    return 0;
}''',
  ),

  // ---------------------------------------------------------------
  // ইনপুট/আউটপুট ও তাপমাত্রা রূপান্তর
  // ---------------------------------------------------------------
  SampleProgram(
    id: 'p5_6_user_input_sum',
    titleBn: '৫.৬ ব্যবহারকারীর ইনপুট নিয়ে যোগফল',
    topicTagBn: 'ইনপুট/আউটপুট (scanf/printf)',
    code: '''#include<stdio.h>
int main()
{
    int a, b, sum;
    printf("Enter two numbers: ");
    scanf("%d %d", &a, &b);
    sum = a + b;
    printf("Sum = %d", sum);
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_7_celsius_to_fahrenheit',
    titleBn: '৫.৭ সেলসিয়াস থেকে ফারেনহাইট',
    topicTagBn: 'ইনপুট/আউটপুট (scanf/printf)',
    code: '''#include<stdio.h>
int main()
{
    float celsius, fahrenheit;
    printf("Enter temperature in Celsius: ");
    scanf("%f", &celsius);
    fahrenheit = (celsius * 9 / 5) + 32;
    printf("Fahrenheit = %f", fahrenheit);
    return 0;
}''',
  ),

  // ---------------------------------------------------------------
  // শর্ত নিয়ন্ত্রণ (if-else / switch)
  // ---------------------------------------------------------------
  SampleProgram(
    id: 'p5_8_if_else_equal_static',
    titleBn: '৫.৮ দুটি সংখ্যা সমান কিনা (স্থির মান)',
    topicTagBn: 'শর্ত নিয়ন্ত্রণ (if-else)',
    code: '''#include<stdio.h>
int main()
{
    int a, b;
    a = 10;
    b = 10;
    if (a == b)
    {
        printf("Equal");
    }
    else
    {
        printf("Not Equal");
    }
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_9_if_else_equal_input',
    titleBn: '৫.৯ দুটি সংখ্যা সমান কিনা (ইনপুট থেকে)',
    topicTagBn: 'শর্ত নিয়ন্ত্রণ (if-else)',
    code: '''#include<stdio.h>
int main()
{
    int a, b;
    printf("Enter two numbers: ");
    scanf("%d %d", &a, &b);
    if (a == b)
    {
        printf("Equal");
    }
    else
    {
        printf("Not Equal");
    }
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_10_else_if_ladder',
    titleBn: '৫.১০ Else-If লেডার (বড়/ছোট নির্ণয়)',
    topicTagBn: 'শর্ত নিয়ন্ত্রণ (if-else)',
    code: '''#include<stdio.h>
int main()
{
    int a, b, c;
    printf("Enter three numbers: ");
    scanf("%d %d %d", &a, &b, &c);
    if (a > b && a > c)
    {
        printf("%d is the largest", a);
    }
    else if (b > a && b > c)
    {
        printf("%d is the largest", b);
    }
    else
    {
        printf("%d is the largest", c);
    }
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_11_letter_grade',
    titleBn: '৫.১১ লেটার গ্রেড নির্ণয়',
    topicTagBn: 'শর্ত নিয়ন্ত্রণ (if-else)',
    code: '''#include<stdio.h>
int main()
{
    int marks;
    printf("Enter marks: ");
    scanf("%d", &marks);
    if (marks >= 80)
    {
        printf("Grade: A+");
    }
    else if (marks >= 70)
    {
        printf("Grade: A");
    }
    else if (marks >= 60)
    {
        printf("Grade: A-");
    }
    else if (marks >= 50)
    {
        printf("Grade: B");
    }
    else if (marks >= 40)
    {
        printf("Grade: C");
    }
    else
    {
        printf("Grade: F");
    }
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_12_logical_operator_job_age',
    titleBn: '৫.১২ লজিক্যাল অপারেটর (চাকরির বয়স যাচাই)',
    topicTagBn: 'শর্ত নিয়ন্ত্রণ (if-else)',
    code: '''#include<stdio.h>
int main()
{
    int age;
    printf("Enter your age: ");
    scanf("%d", &age);
    if (age >= 18 && age <= 35)
    {
        printf("You are eligible to apply");
    }
    else
    {
        printf("You are not eligible to apply");
    }
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_13_modulus_divisible_3_5',
    titleBn: '৫.১৩ মডুলাস: ৩ ও ৫ দ্বারা বিভাজ্য কিনা',
    topicTagBn: 'শর্ত নিয়ন্ত্রণ (if-else)',
    code: '''#include<stdio.h>
int main()
{
    int number;
    printf("Enter a number: ");
    scanf("%d", &number);
    if (number % 3 == 0 && number % 5 == 0)
    {
        printf("Divisible by both 3 and 5");
    }
    else
    {
        printf("Not divisible by both 3 and 5");
    }
    return 0;
}''',
  ),

  // ---------------------------------------------------------------
  // লুপ (while / do-while / for)
  // ---------------------------------------------------------------
  SampleProgram(
    id: 'p5_14_while_print_5_times',
    titleBn: '৫.১৪ While লুপ: ৫ বার প্রিন্ট',
    topicTagBn: 'লুপ (while/do-while/for)',
    code: '''#include<stdio.h>
int main()
{
    int i;
    i = 1;
    while (i <= 5)
    {
        printf("Student C Studio\\n");
        i = i + 1;
    }
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_15_print_1_to_100',
    titleBn: '৫.১৫ ১ থেকে ১০০ পর্যন্ত প্রিন্ট',
    topicTagBn: 'লুপ (while/do-while/for)',
    code: '''#include<stdio.h>
int main()
{
    int i;
    i = 1;
    while (i <= 100)
    {
        printf("%d\\n", i);
        i = i + 1;
    }
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_16_print_even_1_to_100',
    titleBn: '৫.১৬ ১ থেকে ১০০ পর্যন্ত জোড় সংখ্যা',
    topicTagBn: 'লুপ (while/do-while/for)',
    code: '''#include<stdio.h>
int main()
{
    int i;
    i = 2;
    while (i <= 100)
    {
        printf("%d\\n", i);
        i = i + 2;
    }
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_17_sum_1_to_100_while',
    titleBn: '৫.১৭ ১ থেকে ১০০ পর্যন্ত যোগফল (while)',
    topicTagBn: 'লুপ (while/do-while/for)',
    code: '''#include<stdio.h>
int main()
{
    int i, sum;
    i = 1;
    sum = 0;
    while (i <= 100)
    {
        sum = sum + i;
        i = i + 1;
    }
    printf("Sum = %d", sum);
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_18_do_while_1_to_100',
    titleBn: '৫.১৮ Do-While লুপ',
    topicTagBn: 'লুপ (while/do-while/for)',
    code: '''#include<stdio.h>
int main()
{
    int i;
    i = 1;
    do
    {
        printf("%d\\n", i);
        i = i + 1;
    }
    while (i <= 100);
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_19_for_loop_sum_1_to_100',
    titleBn: '৫.১৯ For লুপ: ১ থেকে ১০০ যোগফল',
    topicTagBn: 'লুপ (while/do-while/for)',
    code: '''#include<stdio.h>
int main()
{
    int i, sum;
    sum = 0;
    for (i = 1; i <= 100; i = i + 1)
    {
        sum = sum + i;
    }
    printf("Sum = %d", sum);
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_20_continue_statement',
    titleBn: '৫.২০ Continue স্টেটমেন্ট',
    topicTagBn: 'লুপ (while/do-while/for)',
    code: '''#include<stdio.h>
int main()
{
    int i;
    for (i = 1; i <= 10; i = i + 1)
    {
        if (i == 5)
        {
            continue;
        }
        printf("%d\\n", i);
    }
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_21_multiplication_table',
    titleBn: '৫.২১ নামতা (Multiplication Table)',
    topicTagBn: 'লুপ (while/do-while/for)',
    code: '''#include<stdio.h>
int main()
{
    int number, i;
    printf("Enter a number: ");
    scanf("%d", &number);
    for (i = 1; i <= 10; i = i + 1)
    {
        printf("%d x %d = %d\\n", number, i, number * i);
    }
    return 0;
}''',
  ),

  // ---------------------------------------------------------------
  // অ্যারে (Array)
  // ---------------------------------------------------------------
  SampleProgram(
    id: 'p5_22_array_declaration_students',
    titleBn: '৫ জন শিক্ষার্থীর নম্বর অ্যারেতে রাখা',
    topicTagBn: 'অ্যারে (Array)',
    code: '''#include<stdio.h>
int main()
{
    int marks[5];
    int i;
    for (i = 0; i < 5; i = i + 1)
    {
        printf("Enter marks of student %d: ", i + 1);
        scanf("%d", &marks[i]);
    }
    for (i = 0; i < 5; i = i + 1)
    {
        printf("%d\\n", marks[i]);
    }
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_23_array_sum',
    titleBn: 'অ্যারের যোগফল (১০টি সংখ্যা)',
    topicTagBn: 'অ্যারে (Array)',
    code: '''#include<stdio.h>
int main()
{
    int number[10];
    int i, sum;
    sum = 0;
    for (i = 0; i < 10; i = i + 1)
    {
        printf("Enter number %d: ", i + 1);
        scanf("%d", &number[i]);
        sum = sum + number[i];
    }
    printf("Sum = %d", sum);
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_24_swapping_two_variables',
    titleBn: 'মান অদলবদল (Swapping)',
    topicTagBn: 'অ্যারে (Array)',
    code: '''#include<stdio.h>
int main()
{
    int a, b, temp;
    a = 5;
    b = 10;
    temp = a;
    a = b;
    b = temp;
    printf("a = %d\\n", a);
    printf("b = %d", b);
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_25_array_reverse',
    titleBn: 'অ্যারে রিভার্স',
    topicTagBn: 'অ্যারে (Array)',
    code: '''#include<stdio.h>
int main()
{
    int number[5];
    int i;
    for (i = 0; i < 5; i = i + 1)
    {
        printf("Enter number %d: ", i + 1);
        scanf("%d", &number[i]);
    }
    printf("Reversed array: ");
    for (i = 4; i >= 0; i = i - 1)
    {
        printf("%d ", number[i]);
    }
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_28_linear_search',
    titleBn: 'লিনিয়ার সার্চ',
    topicTagBn: 'অ্যারে (Array)',
    code: '''#include<stdio.h>
int main()
{
    int number[10];
    int i, key, found;
    for (i = 0; i < 10; i = i + 1)
    {
        printf("Enter number %d: ", i + 1);
        scanf("%d", &number[i]);
    }
    printf("Enter the number to search: ");
    scanf("%d", &key);
    found = 0;
    for (i = 0; i < 10; i = i + 1)
    {
        if (number[i] == key)
        {
            found = 1;
        }
    }
    if (found == 1)
    {
        printf("Number found");
    }
    else
    {
        printf("Number not found");
    }
    return 0;
}''',
  ),

  // ---------------------------------------------------------------
  // স্ট্রিং (String)
  // ---------------------------------------------------------------
  SampleProgram(
    id: 'p5_26_string_input_name',
    titleBn: 'স্ট্রিং ইনপুট (নাম)',
    topicTagBn: 'স্ট্রিং (String)',
    code: '''#include<stdio.h>
int main()
{
    char name[30];
    printf("Enter your name: ");
    scanf("%s", name);
    printf("Your name is %s", name);
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_27_string_length_loop',
    titleBn: 'স্ট্রিং দৈর্ঘ্য (লুপ দিয়ে)',
    topicTagBn: 'স্ট্রিং (String)',
    code: '''#include<stdio.h>
int main()
{
    char word[30];
    int length, i;
    printf("Enter a word: ");
    scanf("%s", word);
    length = 0;
    for (i = 0; word[i] != '\\0'; i = i + 1)
    {
        length = length + 1;
    }
    printf("Length = %d", length);
    return 0;
}''',
  ),

  // ---------------------------------------------------------------
  // লাইব্রেরি ফাংশন (math.h / string.h)
  // ---------------------------------------------------------------
  SampleProgram(
    id: 'p5_29_sqrt_function',
    titleBn: 'গাণিতিক ফাংশন: sqrt()',
    topicTagBn: 'লাইব্রেরি ফাংশন (math.h/string.h)',
    code: '''#include<stdio.h>
#include<math.h>
int main()
{
    float number, result;
    printf("Enter a number: ");
    scanf("%f", &number);
    result = sqrt(number);
    printf("Square root = %f", result);
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_30_pow_function',
    titleBn: 'পাওয়ার ফাংশন: pow()',
    topicTagBn: 'লাইব্রেরি ফাংশন (math.h/string.h)',
    code: '''#include<stdio.h>
#include<math.h>
int main()
{
    float x, y, result;
    printf("Enter base and power: ");
    scanf("%f %f", &x, &y);
    result = pow(x, y);
    printf("Result = %f", result);
    return 0;
}''',
  ),
  SampleProgram(
    id: 'p5_31_strlen_strcmp',
    titleBn: 'লাইব্রেরি ফাংশন: strlen() ও strcmp()',
    topicTagBn: 'লাইব্রেরি ফাংশন (math.h/string.h)',
    code: '''#include<stdio.h>
#include<string.h>
int main()
{
    char first[30], second[30];
    int length;
    printf("Enter first word: ");
    scanf("%s", first);
    printf("Enter second word: ");
    scanf("%s", second);
    length = strlen(first);
    printf("Length of first word = %d\\n", length);
    if (strcmp(first, second) == 0)
    {
        printf("Words are equal");
    }
    else
    {
        printf("Words are not equal");
    }
    return 0;
}''',
  ),

  // ---------------------------------------------------------------
  // ইউজার ডিফাইন্ড ফাংশন
  // ---------------------------------------------------------------
  SampleProgram(
    id: 'p5_32_user_defined_function',
    titleBn: '৫.৩২ ইউজার ডিফাইন্ড ফাংশন',
    topicTagBn: 'ইউজার ডিফাইন্ড ফাংশন',
    code: '''#include<stdio.h>
float celsiusToFahrenheit(float celsius)
{
    float fahrenheit;
    fahrenheit = (celsius * 9 / 5) + 32;
    return fahrenheit;
}

int main()
{
    float c, f;
    printf("Enter temperature in Celsius: ");
    scanf("%f", &c);
    f = celsiusToFahrenheit(c);
    printf("Fahrenheit = %f", f);
    return 0;
}''',
  ),

  // ---------------------------------------------------------------
  // সৃজনশীল প্রশ্ন সমাধান
  // ---------------------------------------------------------------
  SampleProgram(
    id: 'c1_sum_odd_1_to_30',
    titleBn: 'সৃজনশীল ১: ১-৩০ বিজোড় সংখ্যার যোগফল',
    topicTagBn: 'সৃজনশীল প্রশ্ন সমাধান',
    code: '''#include<stdio.h>
int main()
{
    int i, sum;
    sum = 0;
    for (i = 1; i <= 30; i = i + 2)
    {
        sum = sum + i;
    }
    printf("Sum of odd numbers = %d", sum);
    return 0;
}''',
  ),
  SampleProgram(
    id: 'c2_reverse_digits',
    titleBn: 'সৃজনশীল ২: সংখ্যার অংক বিপরীত ক্রমে',
    topicTagBn: 'সৃজনশীল প্রশ্ন সমাধান',
    code: '''#include<stdio.h>
int main()
{
    int number, digit, reverse;
    reverse = 0;
    printf("Enter a number: ");
    scanf("%d", &number);
    while (number > 0)
    {
        digit = number % 10;
        reverse = (reverse * 10) + digit;
        number = number / 10;
    }
    printf("Reversed number = %d", reverse);
    return 0;
}''',
  ),
  SampleProgram(
    id: 'c3_celsius_to_fahrenheit_flowchart',
    titleBn: 'সৃজনশীল ৩: সেলসিয়াস থেকে ফারেনহাইট (ফ্লোচার্ট অনুযায়ী)',
    topicTagBn: 'সৃজনশীল প্রশ্ন সমাধান',
    code: '''#include<stdio.h>
int main()
{
    float celsius, fahrenheit;
    printf("Enter temperature in Celsius: ");
    scanf("%f", &celsius);
    fahrenheit = (celsius * 9 / 5) + 32;
    printf("Fahrenheit = %f", fahrenheit);
    return 0;
}''',
  ),
  SampleProgram(
    id: 'c4_group_by_roll',
    titleBn: 'সৃজনশীল ৪: রোল নম্বর অনুযায়ী গ্রুপ (A/B/C)',
    topicTagBn: 'সৃজনশীল প্রশ্ন সমাধান',
    code: '''#include<stdio.h>
int main()
{
    int roll;
    printf("Enter roll number: ");
    scanf("%d", &roll);
    if (roll >= 1 && roll <= 20)
    {
        printf("Group A");
    }
    else if (roll >= 21 && roll <= 40)
    {
        printf("Group B");
    }
    else
    {
        printf("Group C");
    }
    return 0;
}''',
  ),
  SampleProgram(
    id: 'c5_fahrenheit_to_celsius',
    titleBn: 'সৃজনশীল ৫: ফারেনহাইট থেকে সেলসিয়াস',
    topicTagBn: 'সৃজনশীল প্রশ্ন সমাধান',
    code: '''#include<stdio.h>
int main()
{
    float fahrenheit, celsius;
    printf("Enter temperature in Fahrenheit: ");
    scanf("%f", &fahrenheit);
    celsius = (fahrenheit - 32) * 5 / 9;
    printf("Celsius = %f", celsius);
    return 0;
}''',
  ),
  SampleProgram(
    id: 'c6_lcm_gcd',
    titleBn: 'সৃজনশীল ৬: ল.সা.গু (LCM) ও গ.সা.গু (GCD)',
    topicTagBn: 'সৃজনশীল প্রশ্ন সমাধান',
    code: '''#include<stdio.h>
int main()
{
    int a, b, x, y, temp, gcd, lcm;
    printf("Enter two numbers: ");
    scanf("%d %d", &a, &b);
    x = a;
    y = b;
    while (y != 0)
    {
        temp = y;
        y = x % y;
        x = temp;
    }
    gcd = x;
    lcm = (a * b) / gcd;
    printf("GCD = %d\\n", gcd);
    printf("LCM = %d", lcm);
    return 0;
}''',
  ),
];
