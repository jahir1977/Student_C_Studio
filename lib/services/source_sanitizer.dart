class SourceSanitizer {
  static String sanitize(String source) {
    final output = StringBuffer();

    bool insideDoubleQuote = false;
    bool insideSingleQuote = false;
    bool insideLineComment = false;
    bool insideBlockComment = false;
    bool escaped = false;

    for (int index = 0; index < source.length; index++) {
      final char = source[index];

      final String? nextChar =
          index + 1 < source.length ? source[index + 1] : null;

      if (insideLineComment) {
        if (char == '\n') {
          insideLineComment = false;
          output.write('\n');
        } else {
          output.write(' ');
        }

        continue;
      }

      if (insideBlockComment) {
        if (char == '*' && nextChar == '/') {
          output.write(' ');
          output.write(' ');
          insideBlockComment = false;
          index++;
          continue;
        }

        if (char == '\n') {
          output.write('\n');
        } else {
          output.write(' ');
        }

        continue;
      }

      if (escaped) {
        output.write(char);
        escaped = false;
        continue;
      }

      if ((insideDoubleQuote || insideSingleQuote) && char == r'\') {
        output.write(char);
        escaped = true;
        continue;
      }

      if (!insideSingleQuote && char == '"') {
        insideDoubleQuote = !insideDoubleQuote;
        output.write(char);
        continue;
      }

      if (!insideDoubleQuote && char == "'") {
        insideSingleQuote = !insideSingleQuote;
        output.write(char);
        continue;
      }

      if (!insideDoubleQuote &&
          !insideSingleQuote &&
          char == '/' &&
          nextChar == '/') {
        insideLineComment = true;
        output.write(' ');
        output.write(' ');
        index++;
        continue;
      }

      if (!insideDoubleQuote &&
          !insideSingleQuote &&
          char == '/' &&
          nextChar == '*') {
        insideBlockComment = true;
        output.write(' ');
        output.write(' ');
        index++;
        continue;
      }

      output.write(char);
    }

    return output.toString();
  }
}