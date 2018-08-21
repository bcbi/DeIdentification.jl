

"""
    clean_symbol(sym)
This function removes periods and replaces them with an underscore in a symbol.
"""
function clean_symbol(sym)
    str = string(sym)
    str_clean = lowercase(replace(str, r"\.+", "_"))
    str_clean2 = strip(str_clean, ['_'])
    return Symbol(str_clean2)
end
