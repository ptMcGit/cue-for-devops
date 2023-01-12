import "encoding/yaml"

data: """
x: 4.5
y: 2.34
"""
point: yaml.Unmarshal(data)
