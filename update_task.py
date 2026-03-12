import re

with open('docs/project/task.md', 'r') as f:
    content = f.read()

content = content.replace(
    "- [ ] BA Agent: Create scenario editor input survey (multiple choice form)",
    "- [x] BA Agent: Create scenario editor input survey (multiple choice form)"
)

with open('docs/project/task.md', 'w') as f:
    f.write(content)
