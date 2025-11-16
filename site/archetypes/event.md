---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
start: {{ .Date.Format "2006-01-02" }}
end: {{ .Date.Format "2006-01-02" }}
location: ""
active: true
draft: false
---