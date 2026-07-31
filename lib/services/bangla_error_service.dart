class BanglaErrorService {
  const BanglaErrorService();

  String explain(String error) {
    if (error.contains("No code found")) {
      return "এডিটরে কোনো C Program লেখা হয়নি।";
    }

    if (error.contains("undefined reference to 'main'")) {
      return "main() Function ছাড়া কোনো C Program শুরু করা যায় না।";
    }

    if (error.contains("expected ';'")) {
      return "সম্ভবত Statement-এর শেষে সেমিকোলন (;) দিতে ভুল হয়েছে।";
    }

    if (error.contains("expected '}'")) {
      return "Opening Brace ({) এবং Closing Brace (}) সমান নয়।";
    }

    return "অজানা Compiler Error।";
  }
}