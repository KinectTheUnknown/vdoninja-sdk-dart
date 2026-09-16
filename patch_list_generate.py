import re

file_path = "lib/src/vdoninja_sdk/vdoninja_sdk_web.dart"

with open(file_path, "r") as f:
    content = f.read()

pattern = r"""  if \(value\.isA<JSArray>\(\)\) \{
    return \(value as JSArray\)\.toDart\.map\(_jsAnyToDart\)\.toList\(\);
  \}"""

replacement = r"""  if (value.isA<JSArray>()) {
    final dartList = (value as JSArray).toDart;
    return List<dynamic>.generate(
      dartList.length,
      (i) => _jsAnyToDart(dartList[i]),
      growable: true,
    );
  }"""

new_content = re.sub(pattern, replacement, content)

if content == new_content:
    print("Failed to replace")
else:
    with open(file_path, "w") as f:
        f.write(new_content)
    print("Replaced successfully")
