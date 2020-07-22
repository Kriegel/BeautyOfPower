// Token
using System.Globalization;
using System.Management.Automation.Internal;
using System.Management.Automation.Language;

/// <summary>
/// Represents many of the various PowerShell tokens, and is the base class for all PowerShell tokens.
/// </summary>
public class CustomToken 
{
	private TokenKind _kind;

	private TokenFlags _tokenFlags;

	private readonly InternalScriptExtent _scriptExtent;

	/// <summary>
	/// Return the text of the token as it appeared in the script.
	/// </summary>
	public string Text => _scriptExtent.Text;

	/// <summary>
	/// Return the flags for the token.
	/// </summary>
	public TokenFlags TokenFlags
	{
		get
		{
			return _tokenFlags;
		}
		internal set
		{
			_tokenFlags = value;
		}
	}

	/// <summary>
	/// Return the kind of token.
	/// </summary>
	public TokenKind Kind => _kind;

	/// <summary>
	/// Returns true if the token is in error somehow, such as missing a closing quote.
	/// </summary>
	public bool HasError => (_tokenFlags & TokenFlags.TokenInError) != 0;

	/// <summary>
	/// Return the extent in the script of the token.
	/// </summary>
	public IScriptExtent Extent => _scriptExtent;

	internal CustomToken(InternalScriptExtent scriptExtent, TokenKind kind, TokenFlags tokenFlags)
	{
		_scriptExtent = scriptExtent;
		_kind = kind;
		_tokenFlags = (tokenFlags | kind.GetTraits());
	}

	internal void SetIsCommandArgument()
	{
		if (_kind != TokenKind.Identifier)
		{
			_kind = TokenKind.Generic;
		}
	}

	/// <summary>
	/// Return the text of the token as it appeared in the script.
	/// </summary>
	public override string ToString()
	{
		if (_kind != TokenKind.EndOfInput)
		{
			return Text;
		}
		return "<eof>";
	}

	internal virtual string ToDebugString(int indent)
	{
		return string.Format(CultureInfo.InvariantCulture, "{0}{1}: <{2}>", StringUtil.Padding(indent), _kind, Text);
	}
}
