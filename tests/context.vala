class ContextTests : Kkc.TestCase {
    Kkc.Context context;

    public ContextTests () {
        base ("Context");

        add_test ("initial", this.test_initial);
        add_test ("sentence_conversion", this.test_sentence_conversion);
        add_test ("segment_conversion", this.test_segment_conversion);
    }

    struct ConversionData {
        string keys;
        string input;
        string segments;
        int segments_size;
        int segments_cursor_pos;
        string output;
    }

    void do_conversions (ConversionData[] conversions) {
        foreach (var conversion in conversions) {
            context.process_key_events (conversion.keys);
            var output = context.poll_output ();
            assert (output == conversion.output);
            assert (context.input == conversion.input);
            assert (context.segments.get_output () == conversion.segments);
            assert (context.segments.size == conversion.segments_size);
            assert (context.segments.cursor_pos == conversion.segments_cursor_pos);
            context.reset ();
            context.clear_output ();
        }
    }

    static const ConversionData INITIAL_DATA[] = {
        { "a TAB", "あい", "", 0, -1, "" },
        { "k y o", "きょ", "", 0, -1, "" },
        { "k y o DEL", "", "", 0, -1, "" },
        { "k y o F7", "キョ", "", 0, -1, "" },
        { "k y o F10", "kyo", "", 0, -1, "" },
        { "k y o F10 F10", "KYO", "", 0, -1, "" },
        { "k y o F9", "ｋｙｏ", "", 0, -1, "" },
        { "k y o F10 F9", "ｋｙｏ", "", 0, -1, "" },
        { "k y o F9 RET", "", "", 0, -1, "ｋｙｏ" },
        { "w a t a s h i F10 n o", "の", "", 0, -1, "watashi" },
        { "a C-c", "", "", 0, -1, "" }
    };

    public void test_initial () {
        do_conversions (INITIAL_DATA);

        var input_mode = context.input_mode;
        context.process_key_events ("A-l");
        assert (context.input_mode == Kkc.InputMode.LATIN);
        context.reset ();
        context.clear_output ();
        context.input_mode = input_mode;

        context.process_key_events ("(alt a)");
        context.reset ();
        context.clear_output ();

        context.process_key_events ("\\(");
        context.reset ();
        context.clear_output ();

        context.process_key_events ("a RET");
        assert (context.has_output ());
        assert (context.peek_output () == "あ");
        assert (context.has_output ());
        context.reset ();
        context.clear_output ();

        assert (context.punctuation_style == Kkc.PunctuationStyle.JA_JA);
        context.punctuation_style = Kkc.PunctuationStyle.EN_EN;
        context.process_key_events (". RET");
        assert (context.poll_output () == "．");
        assert (context.punctuation_style == Kkc.PunctuationStyle.EN_EN);
        context.reset ();
        context.clear_output ();

        var rule = context.typing_rule;
        assert (rule != null);
        assert (rule.metadata.name == "default");

        var metadata = Kkc.Rule.find_rule ("kana");
        context.typing_rule = new Kkc.Rule (metadata);
        context.process_key_event (new Kkc.KeyEvent.from_x_event (132, 0x5c, 0));
        context.typing_rule = rule;
    }

    static const ConversionData SENTENCE_CONVERSION_DATA[] = {
        { "k y u u k a SPC C-Right C-Right C-Right F10",
          "きゅうか",
          "kyuuka",
          1,
          0,
          "" },
        { "1 a n SPC C-Right C-Right SPC",
          "１あん",
          "一案",
          1,
          0,
          "" },
        { "a i SPC",
          "あい",
          "愛",
          1,
          0,
          "" }
    };

    public void test_sentence_conversion () {
        do_conversions (SENTENCE_CONVERSION_DATA);
    }

    static const ConversionData SEGMENT_CONVERSION_DATA[] = {
        { "",
          "わたしのなまえはなかのです",
          "",
          0,
          -1,
          "" },
        { "SPC",
          "わたしのなまえはなかのです",
          "私の名前は中野です",
          6,
          0,
          "" },
        { "SPC Left",
          "わたしのなまえはなかのです",
          "私の名前は中野です",
          6,
          0,
          "" },
        { "SPC Right",
          "わたしのなまえはなかのです",
          "私の名前は中野です",
          6,
          1,
          "" },
        { "SPC Right C-Right",
          "わたしのなまえはなかのです",
          "私のな前は中野です",
          6,
          1,
          "" },
        { "SPC Right Right C-Left",
          "わたしのなまえはなかのです",
          "私のなまえは中野です",
          7,
          2,
          "" },
        { "SPC SPC",
          "わたしのなまえはなかのです",
          "渡しの名前は中野です",
          6,
          0,
          "" },
        { "SPC SPC Right",
          "わたしのなまえはなかのです",
          "渡しの名前は中野です",
          6,
          1,
          "" },
        { "SPC SPC Right SPC",
          "わたしのなまえはなかのです",
          "渡し埜名前は中野です",
          6,
          1,
          "" },
        { "SPC SPC Right SPC SPC",
          "わたしのなまえはなかのです",
          "渡し之名前は中野です",
          6,
          1,
          "" },
        { "SPC Right Right C-Left SPC RET",
          "",
          "",
          0,
          -1,
          "私の生えは中野です" },
        { "SPC Right F10",
          "わたしのなまえはなかのです",
          "私no名前は中野です",
          6,
          1,
          "" },
        { "SPC F10 F10",
          "わたしのなまえはなかのです",
          "WATASHIの名前は中野です",
          6,
          0,
          "" }
    };

    public void test_segment_conversion () {
        const string PREFIX_KEYS =
            "w a t a s h i n o n a m a e h a n a k a n o d e s u ";

        ConversionData[] conversions =
            new ConversionData[SEGMENT_CONVERSION_DATA.length];

        for (var i = 0; i < SEGMENT_CONVERSION_DATA.length; i++) {
            conversions[i] = SEGMENT_CONVERSION_DATA[i];
            conversions[i].keys = PREFIX_KEYS + SEGMENT_CONVERSION_DATA[i].keys;
        }

        do_conversions (conversions);
    }

    public override void set_up () {
        try {
            var model = Kkc.LanguageModel.load ("sorted3");
            context = new Kkc.Context (model);
        } catch (Kkc.LanguageModelError e) {
            stderr.printf ("%s\n", e.message);
        }

        try {
            new Kkc.SystemSegmentDictionary (
                "test-system-dictionary-nonexistent");
            assert_not_reached ();
        } catch (Error e) {
        }

        try {
            var srcdir = Environment.get_variable ("srcdir");
            assert (srcdir != null);
            var dictionary = new Kkc.SystemSegmentDictionary (
                Path.build_filename (srcdir, "file-dict.dat"));
            context.dictionaries.add (dictionary);
        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }

        context.dictionaries.add (new Kkc.EmptySegmentDictionary ());
    }

    public override void tear_down () {
        context = null;
    }
}

int main (string[] args)
{
  Test.init (ref args);
  Kkc.init ();

  TestSuite root = TestSuite.get_root ();
  root.add_suite (new ContextTests ().get_suite ());

  Test.run ();

  return 0;
}
