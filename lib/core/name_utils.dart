String normalizeTreeName(String value) => value.trim().replaceAll(RegExp(r'\s+'), ' ');

bool isValidTreeName(String value) => normalizeTreeName(value).isNotEmpty;
