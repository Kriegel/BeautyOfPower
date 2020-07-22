# The Powershell PSParser knows different token types since PowerShell 3.0

```powershell
# list all Parser knowen Token Types
# (count can differ with .Net Versions)
[System.Management.Automation.Language.Token].Assembly.GetTypes() | Where-Object { $_.Name -like '*Token' -and $_.IsPublic } | Select-Object -ExpandProperty Name # | Measure-Object # (13)
```

## Token Flags

```powershell
# The System.Management.Automation.Language.TokenFlags is an Enum so we can enumerate the different Flag names
# (count can differ with .Net Versions)
[Enum]::GetNames([System.Management.Automation.Language.TokenFlags]) # | Measure-Object # (28)
```

or use

Get-BopTokenFlag

which ships with this Module

## Token Kind

The new Parser knows many different Token-Kinds since PowerShell 3.0
which are member of the Token Types and can be used to details the Token Types

```powershell
# The System.Management.Automation.Language.TokenKind is an Enum so we can enumerate the different Kind names
# (count can differ with .Net Versions)
[Enum]::GetNames([System.Management.Automation.Language.TokenKind]) # | Measure-Object # (150)
```

or use

Get-BopTokenKind

which ships with this Module

---
> NOTE:
> I prefer to filter first for TokenFlags and after that the TokenKind.
> With TokenFlags it is easy to find all Keywords or CommandNames.
> to find Parameter you have to use the TokenKind on the other Hand
---

## List of Names

### Token Types

    PSToken
    Token
    NumberToken
    ParameterToken
    VariableToken
    StringToken
    StringLiteralToken
    StringExpandableToken
    LabelToken
    RedirectionToken
    InputRedirectionToken
    MergingRedirectionToken
    FileRedirectionToken

### TokenFlags (not sorted)

    None
    BinaryPrecedenceLogical
    BinaryPrecedenceBitwise
    BinaryPrecedenceComparison
    BinaryPrecedenceAdd
    BinaryPrecedenceMultiply
    BinaryPrecedenceFormat
    BinaryPrecedenceRange
    BinaryPrecedenceMask
    Keyword
    ScriptBlockBlockName
    BinaryOperator
    UnaryOperator
    CaseSensitiveOperator
    SpecialOperator
    AssignmentOperator
    ParseModeInvariant
    TokenInError
    DisallowedInRestrictedMode
    PrefixOrPostfixOperator
    CommandName
    MemberName
    TypeName
    AttributeName
    CanConstantFold
    StatementDoesntSupportAttributes

### TokenKind (not sorted)

    Unknown, Variable, SplattedVariable, Parameter, Number,
    Label, Identifier, Generic, NewLine, LineContinuation,
    Comment, EndOfInput, StringLiteral, StringExpandable, HereStringLiteral,
    HereStringExpandable, LParen, RParen, LCurly, RCurly,
    LBracket, RBracket, AtParen, AtCurly, DollarParen,
    Semi, AndAnd, OrOr, Ampersand, Pipe,
    Comma, MinusMinus, PlusPlus, DotDot, ColonColon,
    Dot, Exclaim, Multiply, Divide, Rem,
    Plus, Minus, Equals, PlusEquals, MinusEquals,
    MultiplyEquals, DivideEquals, RemainderEquals, Redirection, RedirectInStd,
    Format, Not, Bnot, And, Or,
    Xor, Band, Bor, Bxor, Join,
    Ieq, Ine, Ige, Igt, Ilt,
    Ile, Ilike, Inotlike, Imatch, Inotmatch,
    Ireplace, Icontains, Inotcontains, Iin, Inotin,
    Isplit, Ceq, Cne, Cge, Cgt,
    Clt, Cle, Clike, Cnotlike, Cmatch,
    Cnotmatch, Creplace, Ccontains, Cnotcontains, Cin,
    Cnotin, Csplit, Is, IsNot, As,
    PostfixPlusPlus, PostfixMinusMinus, Shl, Shr, Colon,
    Begin, Break, Catch, Class, Continue,
    Data, Define, Do, Dynamicparam, Else,
    ElseIf, End, Exit, Filter, Finally,
    For, Foreach, From, Function, If,
    In, Param, Process, Return, Switch,
    Throw, Trap, Try, Until, Using,
    Var, While, Workflow, Parallel, Sequence,
    InlineScript, Configuration, DynamicKeyword, Public, Private,
    Static, Interface, Enum, Namespace, Module,
    Type, Assembly, Command, Hidden, Base
