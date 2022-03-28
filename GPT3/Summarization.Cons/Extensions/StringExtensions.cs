namespace Summarization.Cons.Extensions;

public static class StringExtensions
{
    public static string MaxLength(this string input, int length)
    {
        if (string.IsNullOrEmpty(input) || input.Length <= length)
        {
            return input;
        }

        return input.Substring(0, length);
    }
}