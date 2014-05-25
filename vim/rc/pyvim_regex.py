import vim

indentation  = '^  *'
alpha_       = '[A-Za-z_]'      # alphabet and underscore
alphanum_    = '[0-9A-Za-z_]'   # alphanumerics and underscore
alphanumdot_ = '[0-9A-Za-z_.]'  # alphanumerics and underscore
var = '\\<[' + alpha_ + alphanum_ + '*\\>'
chainedvar = '\\<[' + alpha_ + alphanumdot_ + '*\\>'

simplestr = r"'[^']*'"
endl         = ' *$'  # end of line plus whitespace
#anychar      = '.*'   # match anything


def group(regex):
    return '\\(' + regex + '\\)'


def bref(num):
    return '\\' + str(num)


def resub(regex, repl, modifiers='gce'):
    cmd = '%s/' + regex + '/' + repl + '/' + modifiers
    print(cmd)
    vim.command(cmd)

# Comments / Removes explicit new actions
#regex = group(indentation) + group('ui\\.action' + alphanum_ + '* = ') + group('.*newAction')
#repl_comment = bref(1) + '#' + bref(2) + '\r' + bref(1) + bref(3)
#repl_remove = bref(1) + bref(3)
#comment_newaction_def = (regex, repl_comment)
#remove_newaction_def  = (regex, repl_remove)

# Call specified regexes
# resub(*remove_newaction_def)

# Cleans up common flake8 errors

# Fix not <word> is
fix_notis_regex = ' \\<not\\> ' + group(chainedvar) + ' is '
repl = ' ' + bref(1) + ' is not '
#resub(fix_notis_regex, repl)


fix_notin_regex1 = ' \\<not\\> ' + group(chainedvar) + ' in '
fix_notin_regex2 = ' \\<not\\> ' + group(simplestr)  + ' in '
repl = ' ' + bref(1) + ' not in '
#resub(fix_notin_regex1, repl)
#resub(fix_notin_regex2, repl)


# Pep8 spaces between operators
def ensurespaces(op):
    repl = ' ' + op + ' '
    resub('\\>' + op + '\\<', repl)
    resub(group('[\\])"]') + op + '\\<', bref(1) + repl)
