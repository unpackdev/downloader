// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library UnicodeMap {
    function codepointToBlock(uint256 cp) external pure returns(string memory) {
        if(cp < 66560) {
            if(cp < 10224) {
                if(cp < 5920) {
                    if(cp < 2304) {
                        if(cp < 1424) {
                            if(cp < 688) {
                                if(cp < 256) {
                                    if(cp < 128) {
                                        return "Basic Latin";
                                    } else {
                                        return "Latin-1 Supplement";
                                    }
                                } else {
                                    if(cp < 384) {
                                        return "Latin Extended-A";
                                    } else {
                                        if(cp < 592) {
                                            return "Latin Extended-B";
                                        } else {
                                            return "IPA Extensions";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 1024) {
                                    if(cp < 768) {
                                        return "Spacing Modifier Letters";
                                    } else {
                                        if(cp < 880) {
                                            return "Combining Diacritical Marks";
                                        } else {
                                            return "Greek and Coptic";
                                        }
                                    }
                                } else {
                                    if(cp < 1280) {
                                        return "Cyrillic";
                                    } else {
                                        if(cp < 1328) {
                                            return "Cyrillic Supplement";
                                        } else {
                                            return "Armenian";
                                        }
                                    }
                                }
                            }
                        } else {
                            if(cp < 1984) {
                                if(cp < 1792) {
                                    if(cp < 1536) {
                                        return "Hebrew";
                                    } else {
                                        return "Arabic";
                                    }
                                } else {
                                    if(cp < 1872) {
                                        return "Syriac";
                                    } else {
                                        if(cp < 1920) {
                                            return "Arabic Supplement";
                                        } else {
                                            return "Thaana";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 2144) {
                                    if(cp < 2048) {
                                        return "NKo";
                                    } else {
                                        if(cp < 2112) {
                                            return "Samaritan";
                                        } else {
                                            return "Mandaic";
                                        }
                                    }
                                } else {
                                    if(cp < 2160) {
                                        return "Syriac Supplement";
                                    } else {
                                        if(cp < 2208) {
                                            return "";
                                        } else {
                                            return "Arabic Extended-A";
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if(cp < 3712) {
                            if(cp < 2944) {
                                if(cp < 2560) {
                                    if(cp < 2432) {
                                        return "Devanagari";
                                    } else {
                                        return "Bengali";
                                    }
                                } else {
                                    if(cp < 2688) {
                                        return "Gurmukhi";
                                    } else {
                                        if(cp < 2816) {
                                            return "Gujarati";
                                        } else {
                                            return "Oriya";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 3328) {
                                    if(cp < 3072) {
                                        return "Tamil";
                                    } else {
                                        if(cp < 3200) {
                                            return "Telugu";
                                        } else {
                                            return "Kannada";
                                        }
                                    }
                                } else {
                                    if(cp < 3456) {
                                        return "Malayalam";
                                    } else {
                                        if(cp < 3584) {
                                            return "Sinhala";
                                        } else {
                                            return "Thai";
                                        }
                                    }
                                }
                            }
                        } else {
                            if(cp < 4992) {
                                if(cp < 4256) {
                                    if(cp < 3840) {
                                        return "Lao";
                                    } else {
                                        if(cp < 4096) {
                                            return "Tibetan";
                                        } else {
                                            return "Myanmar";
                                        }
                                    }
                                } else {
                                    if(cp < 4352) {
                                        return "Georgian";
                                    } else {
                                        if(cp < 4608) {
                                            return "Hangul Jamo";
                                        } else {
                                            return "Ethiopic";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 5760) {
                                    if(cp < 5024) {
                                        return "Ethiopic Supplement";
                                    } else {
                                        if(cp < 5120) {
                                            return "Cherokee";
                                        } else {
                                            return "Unified Canadian Aboriginal Syllabics";
                                        }
                                    }
                                } else {
                                    if(cp < 5792) {
                                        return "Ogham";
                                    } else {
                                        if(cp < 5888) {
                                            return "Runic";
                                        } else {
                                            return "Tagalog";
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if(cp < 7424) {
                        if(cp < 6688) {
                            if(cp < 6320) {
                                if(cp < 5984) {
                                    if(cp < 5952) {
                                        return "Hanunoo";
                                    } else {
                                        return "Buhid";
                                    }
                                } else {
                                    if(cp < 6016) {
                                        return "Tagbanwa";
                                    } else {
                                        if(cp < 6144) {
                                            return "Khmer";
                                        } else {
                                            return "Mongolian";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 6528) {
                                    if(cp < 6400) {
                                        return "Unified Canadian Aboriginal Syllabics Extended";
                                    } else {
                                        if(cp < 6480) {
                                            return "Limbu";
                                        } else {
                                            return "Tai Le";
                                        }
                                    }
                                } else {
                                    if(cp < 6624) {
                                        return "New Tai Lue";
                                    } else {
                                        if(cp < 6656) {
                                            return "Khmer Symbols";
                                        } else {
                                            return "Buginese";
                                        }
                                    }
                                }
                            }
                        } else {
                            if(cp < 7168) {
                                if(cp < 6912) {
                                    if(cp < 6832) {
                                        return "Tai Tham";
                                    } else {
                                        return "Combining Diacritical Marks Extended";
                                    }
                                } else {
                                    if(cp < 7040) {
                                        return "Balinese";
                                    } else {
                                        if(cp < 7104) {
                                            return "Sundanese";
                                        } else {
                                            return "Batak";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 7312) {
                                    if(cp < 7248) {
                                        return "Lepcha";
                                    } else {
                                        if(cp < 7296) {
                                            return "Ol Chiki";
                                        } else {
                                            return "Cyrillic Extended-C";
                                        }
                                    }
                                } else {
                                    if(cp < 7360) {
                                        return "Georgian Extended";
                                    } else {
                                        if(cp < 7376) {
                                            return "Sundanese Supplement";
                                        } else {
                                            return "Vedic Extensions";
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if(cp < 8592) {
                            if(cp < 8192) {
                                if(cp < 7616) {
                                    if(cp < 7552) {
                                        return "Phonetic Extensions";
                                    } else {
                                        return "Phonetic Extensions Supplement";
                                    }
                                } else {
                                    if(cp < 7680) {
                                        return "Combining Diacritical Marks Supplement";
                                    } else {
                                        if(cp < 7936) {
                                            return "Latin Extended Additional";
                                        } else {
                                            return "Greek Extended";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 8400) {
                                    if(cp < 8304) {
                                        return "General Punctuation";
                                    } else {
                                        if(cp < 8352) {
                                            return "Superscripts and Subscripts";
                                        } else {
                                            return "Currency Symbols";
                                        }
                                    }
                                } else {
                                    if(cp < 8448) {
                                        return "Combining Diacritical Marks for Symbols";
                                    } else {
                                        if(cp < 8528) {
                                            return "Letterlike Symbols";
                                        } else {
                                            return "Number Forms";
                                        }
                                    }
                                }
                            }
                        } else {
                            if(cp < 9472) {
                                if(cp < 9216) {
                                    if(cp < 8704) {
                                        return "Arrows";
                                    } else {
                                        if(cp < 8960) {
                                            return "Mathematical Operators";
                                        } else {
                                            return "Miscellaneous Technical";
                                        }
                                    }
                                } else {
                                    if(cp < 9280) {
                                        return "Control Pictures";
                                    } else {
                                        if(cp < 9312) {
                                            return "Optical Character Recognition";
                                        } else {
                                            return "Enclosed Alphanumerics";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 9728) {
                                    if(cp < 9600) {
                                        return "Box Drawing";
                                    } else {
                                        if(cp < 9632) {
                                            return "Block Elements";
                                        } else {
                                            return "Geometric Shapes";
                                        }
                                    }
                                } else {
                                    if(cp < 9984) {
                                        return "Miscellaneous Symbols";
                                    } else {
                                        if(cp < 10176) {
                                            return "Dingbats";
                                        } else {
                                            return "Miscellaneous Mathematical Symbols-A";
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if(cp < 43264) {
                    if(cp < 12592) {
                        if(cp < 11648) {
                            if(cp < 11008) {
                                if(cp < 10496) {
                                    if(cp < 10240) {
                                        return "Supplemental Arrows-A";
                                    } else {
                                        return "Braille Patterns";
                                    }
                                } else {
                                    if(cp < 10624) {
                                        return "Supplemental Arrows-B";
                                    } else {
                                        if(cp < 10752) {
                                            return "Miscellaneous Mathematical Symbols-B";
                                        } else {
                                            return "Supplemental Mathematical Operators";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 11392) {
                                    if(cp < 11264) {
                                        return "Miscellaneous Symbols and Arrows";
                                    } else {
                                        if(cp < 11360) {
                                            return "Glagolitic";
                                        } else {
                                            return "Latin Extended-C";
                                        }
                                    }
                                } else {
                                    if(cp < 11520) {
                                        return "Coptic";
                                    } else {
                                        if(cp < 11568) {
                                            return "Georgian Supplement";
                                        } else {
                                            return "Tifinagh";
                                        }
                                    }
                                }
                            }
                        } else {
                            if(cp < 12256) {
                                if(cp < 11776) {
                                    if(cp < 11744) {
                                        return "Ethiopic Extended";
                                    } else {
                                        return "Cyrillic Extended-A";
                                    }
                                } else {
                                    if(cp < 11904) {
                                        return "Supplemental Punctuation";
                                    } else {
                                        if(cp < 12032) {
                                            return "CJK Radicals Supplement";
                                        } else {
                                            return "Kangxi Radicals";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 12352) {
                                    if(cp < 12272) {
                                        return "";
                                    } else {
                                        if(cp < 12288) {
                                            return "Ideographic Description Characters";
                                        } else {
                                            return "CJK Symbols and Punctuation";
                                        }
                                    }
                                } else {
                                    if(cp < 12448) {
                                        return "Hiragana";
                                    } else {
                                        if(cp < 12544) {
                                            return "Katakana";
                                        } else {
                                            return "Bopomofo";
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if(cp < 42128) {
                            if(cp < 12800) {
                                if(cp < 12704) {
                                    if(cp < 12688) {
                                        return "Hangul Compatibility Jamo";
                                    } else {
                                        return "Kanbun";
                                    }
                                } else {
                                    if(cp < 12736) {
                                        return "Bopomofo Extended";
                                    } else {
                                        if(cp < 12784) {
                                            return "CJK Strokes";
                                        } else {
                                            return "Katakana Phonetic Extensions";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 19904) {
                                    if(cp < 13056) {
                                        return "Enclosed CJK Letters and Months";
                                    } else {
                                        if(cp < 13312) {
                                            return "CJK Compatibility";
                                        } else {
                                            return "CJK Unified Ideographs Extension A";
                                        }
                                    }
                                } else {
                                    if(cp < 19968) {
                                        return "Yijing Hexagram Symbols";
                                    } else {
                                        if(cp < 40960) {
                                            return "CJK Unified Ideographs";
                                        } else {
                                            return "Yi Syllables";
                                        }
                                    }
                                }
                            }
                        } else {
                            if(cp < 42784) {
                                if(cp < 42560) {
                                    if(cp < 42192) {
                                        return "Yi Radicals";
                                    } else {
                                        if(cp < 42240) {
                                            return "Lisu";
                                        } else {
                                            return "Vai";
                                        }
                                    }
                                } else {
                                    if(cp < 42656) {
                                        return "Cyrillic Extended-B";
                                    } else {
                                        if(cp < 42752) {
                                            return "Bamum";
                                        } else {
                                            return "Modifier Tone Letters";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 43072) {
                                    if(cp < 43008) {
                                        return "Latin Extended-D";
                                    } else {
                                        if(cp < 43056) {
                                            return "Syloti Nagri";
                                        } else {
                                            return "Common Indic Number Forms";
                                        }
                                    }
                                } else {
                                    if(cp < 43136) {
                                        return "Phags-pa";
                                    } else {
                                        if(cp < 43232) {
                                            return "Saurashtra";
                                        } else {
                                            return "Devanagari Extended";
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if(cp < 65040) {
                        if(cp < 43888) {
                            if(cp < 43520) {
                                if(cp < 43360) {
                                    if(cp < 43312) {
                                        return "Kayah Li";
                                    } else {
                                        return "Rejang";
                                    }
                                } else {
                                    if(cp < 43392) {
                                        return "Hangul Jamo Extended-A";
                                    } else {
                                        if(cp < 43488) {
                                            return "Javanese";
                                        } else {
                                            return "Myanmar Extended-B";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 43744) {
                                    if(cp < 43616) {
                                        return "Cham";
                                    } else {
                                        if(cp < 43648) {
                                            return "Myanmar Extended-A";
                                        } else {
                                            return "Tai Viet";
                                        }
                                    }
                                } else {
                                    if(cp < 43776) {
                                        return "Meetei Mayek Extensions";
                                    } else {
                                        if(cp < 43824) {
                                            return "Ethiopic Extended-A";
                                        } else {
                                            return "Latin Extended-E";
                                        }
                                    }
                                }
                            }
                        } else {
                            if(cp < 56320) {
                                if(cp < 55216) {
                                    if(cp < 43968) {
                                        return "Cherokee Supplement";
                                    } else {
                                        if(cp < 44032) {
                                            return "Meetei Mayek";
                                        } else {
                                            return "Hangul Syllables";
                                        }
                                    }
                                } else {
                                    if(cp < 55296) {
                                        return "Hangul Jamo Extended-B";
                                    } else {
                                        if(cp < 56192) {
                                            return "High Surrogates";
                                        } else {
                                            return "High Private Use Surrogates";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 64256) {
                                    if(cp < 57344) {
                                        return "Low Surrogates";
                                    } else {
                                        if(cp < 63744) {
                                            return "Private Use Area";
                                        } else {
                                            return "CJK Compatibility Ideographs";
                                        }
                                    }
                                } else {
                                    if(cp < 64336) {
                                        return "Alphabetic Presentation Forms";
                                    } else {
                                        if(cp < 65024) {
                                            return "Arabic Presentation Forms-A";
                                        } else {
                                            return "Variation Selectors";
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if(cp < 65936) {
                            if(cp < 65280) {
                                if(cp < 65072) {
                                    if(cp < 65056) {
                                        return "Vertical Forms";
                                    } else {
                                        return "Combining Half Marks";
                                    }
                                } else {
                                    if(cp < 65104) {
                                        return "CJK Compatibility Forms";
                                    } else {
                                        if(cp < 65136) {
                                            return "Small Form Variants";
                                        } else {
                                            return "Arabic Presentation Forms-B";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 65664) {
                                    if(cp < 65520) {
                                        return "Halfwidth and Fullwidth Forms";
                                    } else {
                                        if(cp < 65536) {
                                            return "Specials";
                                        } else {
                                            return "Linear B Syllabary";
                                        }
                                    }
                                } else {
                                    if(cp < 65792) {
                                        return "Linear B Ideograms";
                                    } else {
                                        if(cp < 65856) {
                                            return "Aegean Numbers";
                                        } else {
                                            return "Ancient Greek Numbers";
                                        }
                                    }
                                }
                            }
                        } else {
                            if(cp < 66304) {
                                if(cp < 66176) {
                                    if(cp < 66000) {
                                        return "Ancient Symbols";
                                    } else {
                                        if(cp < 66048) {
                                            return "Phaistos Disc";
                                        } else {
                                            return "";
                                        }
                                    }
                                } else {
                                    if(cp < 66208) {
                                        return "Lycian";
                                    } else {
                                        if(cp < 66272) {
                                            return "Carian";
                                        } else {
                                            return "Coptic Epact Numbers";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 66432) {
                                    if(cp < 66352) {
                                        return "Old Italic";
                                    } else {
                                        if(cp < 66384) {
                                            return "Gothic";
                                        } else {
                                            return "Old Permic";
                                        }
                                    }
                                } else {
                                    if(cp < 66464) {
                                        return "Ugaritic";
                                    } else {
                                        if(cp < 66528) {
                                            return "Old Persian";
                                        } else {
                                            return "";
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            if(cp < 75088) {
                if(cp < 69840) {
                    if(cp < 68224) {
                        if(cp < 67680) {
                            if(cp < 66864) {
                                if(cp < 66688) {
                                    if(cp < 66640) {
                                        return "Deseret";
                                    } else {
                                        return "Shavian";
                                    }
                                } else {
                                    if(cp < 66736) {
                                        return "Osmanya";
                                    } else {
                                        if(cp < 66816) {
                                            return "Osage";
                                        } else {
                                            return "Elbasan";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 67456) {
                                    if(cp < 66928) {
                                        return "Caucasian Albanian";
                                    } else {
                                        if(cp < 67072) {
                                            return "";
                                        } else {
                                            return "Linear A";
                                        }
                                    }
                                } else {
                                    if(cp < 67584) {
                                        return "";
                                    } else {
                                        if(cp < 67648) {
                                            return "Cypriot Syllabary";
                                        } else {
                                            return "Imperial Aramaic";
                                        }
                                    }
                                }
                            }
                        } else {
                            if(cp < 67872) {
                                if(cp < 67760) {
                                    if(cp < 67712) {
                                        return "Palmyrene";
                                    } else {
                                        return "Nabataean";
                                    }
                                } else {
                                    if(cp < 67808) {
                                        return "";
                                    } else {
                                        if(cp < 67840) {
                                            return "Hatran";
                                        } else {
                                            return "Phoenician";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 68000) {
                                    if(cp < 67904) {
                                        return "Lydian";
                                    } else {
                                        if(cp < 67968) {
                                            return "";
                                        } else {
                                            return "Meroitic Hieroglyphs";
                                        }
                                    }
                                } else {
                                    if(cp < 68096) {
                                        return "Meroitic Cursive";
                                    } else {
                                        if(cp < 68192) {
                                            return "Kharoshthi";
                                        } else {
                                            return "Old South Arabian";
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if(cp < 68864) {
                            if(cp < 68448) {
                                if(cp < 68288) {
                                    if(cp < 68256) {
                                        return "Old North Arabian";
                                    } else {
                                        return "";
                                    }
                                } else {
                                    if(cp < 68352) {
                                        return "Manichaean";
                                    } else {
                                        if(cp < 68416) {
                                            return "Avestan";
                                        } else {
                                            return "Inscriptional Parthian";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 68608) {
                                    if(cp < 68480) {
                                        return "Inscriptional Pahlavi";
                                    } else {
                                        if(cp < 68528) {
                                            return "Psalter Pahlavi";
                                        } else {
                                            return "";
                                        }
                                    }
                                } else {
                                    if(cp < 68688) {
                                        return "Old Turkic";
                                    } else {
                                        if(cp < 68736) {
                                            return "";
                                        } else {
                                            return "Old Hungarian";
                                        }
                                    }
                                }
                            }
                        } else {
                            if(cp < 69424) {
                                if(cp < 69248) {
                                    if(cp < 68928) {
                                        return "Hanifi Rohingya";
                                    } else {
                                        if(cp < 69216) {
                                            return "";
                                        } else {
                                            return "Rumi Numeral Symbols";
                                        }
                                    }
                                } else {
                                    if(cp < 69312) {
                                        return "Yezidi";
                                    } else {
                                        if(cp < 69376) {
                                            return "";
                                        } else {
                                            return "Old Sogdian";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 69600) {
                                    if(cp < 69488) {
                                        return "Sogdian";
                                    } else {
                                        if(cp < 69552) {
                                            return "";
                                        } else {
                                            return "Chorasmian";
                                        }
                                    }
                                } else {
                                    if(cp < 69632) {
                                        return "Elymaic";
                                    } else {
                                        if(cp < 69760) {
                                            return "Brahmi";
                                        } else {
                                            return "Kaithi";
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if(cp < 71760) {
                        if(cp < 70656) {
                            if(cp < 70144) {
                                if(cp < 69968) {
                                    if(cp < 69888) {
                                        return "Sora Sompeng";
                                    } else {
                                        return "Chakma";
                                    }
                                } else {
                                    if(cp < 70016) {
                                        return "Mahajani";
                                    } else {
                                        if(cp < 70112) {
                                            return "Sharada";
                                        } else {
                                            return "Sinhala Archaic Numbers";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 70320) {
                                    if(cp < 70224) {
                                        return "Khojki";
                                    } else {
                                        if(cp < 70272) {
                                            return "";
                                        } else {
                                            return "Multani";
                                        }
                                    }
                                } else {
                                    if(cp < 70400) {
                                        return "Khudawadi";
                                    } else {
                                        if(cp < 70528) {
                                            return "Grantha";
                                        } else {
                                            return "";
                                        }
                                    }
                                }
                            }
                        } else {
                            if(cp < 71264) {
                                if(cp < 70880) {
                                    if(cp < 70784) {
                                        return "Newa";
                                    } else {
                                        return "Tirhuta";
                                    }
                                } else {
                                    if(cp < 71040) {
                                        return "";
                                    } else {
                                        if(cp < 71168) {
                                            return "Siddham";
                                        } else {
                                            return "Modi";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 71424) {
                                    if(cp < 71296) {
                                        return "Mongolian Supplement";
                                    } else {
                                        if(cp < 71376) {
                                            return "Takri";
                                        } else {
                                            return "";
                                        }
                                    }
                                } else {
                                    if(cp < 71488) {
                                        return "Ahom";
                                    } else {
                                        if(cp < 71680) {
                                            return "";
                                        } else {
                                            return "Dogra";
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if(cp < 72816) {
                            if(cp < 72192) {
                                if(cp < 71936) {
                                    if(cp < 71840) {
                                        return "";
                                    } else {
                                        return "Warang Citi";
                                    }
                                } else {
                                    if(cp < 72032) {
                                        return "Dives Akuru";
                                    } else {
                                        if(cp < 72096) {
                                            return "";
                                        } else {
                                            return "Nandinagari";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 72384) {
                                    if(cp < 72272) {
                                        return "Zanabazar Square";
                                    } else {
                                        if(cp < 72368) {
                                            return "Soyombo";
                                        } else {
                                            return "";
                                        }
                                    }
                                } else {
                                    if(cp < 72448) {
                                        return "Pau Cin Hau";
                                    } else {
                                        if(cp < 72704) {
                                            return "";
                                        } else {
                                            return "Bhaiksuki";
                                        }
                                    }
                                }
                            }
                        } else {
                            if(cp < 73472) {
                                if(cp < 73056) {
                                    if(cp < 72896) {
                                        return "Marchen";
                                    } else {
                                        if(cp < 72960) {
                                            return "";
                                        } else {
                                            return "Masaram Gondi";
                                        }
                                    }
                                } else {
                                    if(cp < 73136) {
                                        return "Gunjala Gondi";
                                    } else {
                                        if(cp < 73440) {
                                            return "";
                                        } else {
                                            return "Makasar";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 73728) {
                                    if(cp < 73648) {
                                        return "";
                                    } else {
                                        if(cp < 73664) {
                                            return "Lisu Supplement";
                                        } else {
                                            return "Tamil Supplement";
                                        }
                                    }
                                } else {
                                    if(cp < 74752) {
                                        return "Cuneiform";
                                    } else {
                                        if(cp < 74880) {
                                            return "Cuneiform Numbers and Punctuation";
                                        } else {
                                            return "Early Dynastic Cuneiform";
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if(cp < 123584) {
                    if(cp < 110592) {
                        if(cp < 93072) {
                            if(cp < 83584) {
                                if(cp < 78896) {
                                    if(cp < 77824) {
                                        return "";
                                    } else {
                                        return "Egyptian Hieroglyphs";
                                    }
                                } else {
                                    if(cp < 78912) {
                                        return "Egyptian Hieroglyph Format Controls";
                                    } else {
                                        if(cp < 82944) {
                                            return "";
                                        } else {
                                            return "Anatolian Hieroglyphs";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 92784) {
                                    if(cp < 92160) {
                                        return "";
                                    } else {
                                        if(cp < 92736) {
                                            return "Bamum Supplement";
                                        } else {
                                            return "Mro";
                                        }
                                    }
                                } else {
                                    if(cp < 92880) {
                                        return "";
                                    } else {
                                        if(cp < 92928) {
                                            return "Bassa Vah";
                                        } else {
                                            return "Pahawh Hmong";
                                        }
                                    }
                                }
                            }
                        } else {
                            if(cp < 94176) {
                                if(cp < 93856) {
                                    if(cp < 93760) {
                                        return "";
                                    } else {
                                        return "Medefaidrin";
                                    }
                                } else {
                                    if(cp < 93952) {
                                        return "";
                                    } else {
                                        if(cp < 94112) {
                                            return "Miao";
                                        } else {
                                            return "";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 101120) {
                                    if(cp < 94208) {
                                        return "Ideographic Symbols and Punctuation";
                                    } else {
                                        if(cp < 100352) {
                                            return "Tangut";
                                        } else {
                                            return "Tangut Components";
                                        }
                                    }
                                } else {
                                    if(cp < 101632) {
                                        return "Khitan Small Script";
                                    } else {
                                        if(cp < 101776) {
                                            return "Tangut Supplement";
                                        } else {
                                            return "";
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if(cp < 119376) {
                            if(cp < 113664) {
                                if(cp < 110896) {
                                    if(cp < 110848) {
                                        return "Kana Supplement";
                                    } else {
                                        return "Kana Extended-A";
                                    }
                                } else {
                                    if(cp < 110960) {
                                        return "Small Kana Extension";
                                    } else {
                                        if(cp < 111360) {
                                            return "Nushu";
                                        } else {
                                            return "";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 118784) {
                                    if(cp < 113824) {
                                        return "Duployan";
                                    } else {
                                        if(cp < 113840) {
                                            return "Shorthand Format Controls";
                                        } else {
                                            return "";
                                        }
                                    }
                                } else {
                                    if(cp < 119040) {
                                        return "Byzantine Musical Symbols";
                                    } else {
                                        if(cp < 119296) {
                                            return "Musical Symbols";
                                        } else {
                                            return "Ancient Greek Musical Notation";
                                        }
                                    }
                                }
                            }
                        } else {
                            if(cp < 120832) {
                                if(cp < 119648) {
                                    if(cp < 119520) {
                                        return "";
                                    } else {
                                        if(cp < 119552) {
                                            return "Mayan Numerals";
                                        } else {
                                            return "Tai Xuan Jing Symbols";
                                        }
                                    }
                                } else {
                                    if(cp < 119680) {
                                        return "Counting Rod Numerals";
                                    } else {
                                        if(cp < 119808) {
                                            return "";
                                        } else {
                                            return "Mathematical Alphanumeric Symbols";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 122928) {
                                    if(cp < 121520) {
                                        return "Sutton SignWriting";
                                    } else {
                                        if(cp < 122880) {
                                            return "";
                                        } else {
                                            return "Glagolitic Supplement";
                                        }
                                    }
                                } else {
                                    if(cp < 123136) {
                                        return "";
                                    } else {
                                        if(cp < 123216) {
                                            return "Nyiakeng Puachue Hmong";
                                        } else {
                                            return "";
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if(cp < 129024) {
                        if(cp < 126720) {
                            if(cp < 125280) {
                                if(cp < 124928) {
                                    if(cp < 123648) {
                                        return "Wancho";
                                    } else {
                                        return "";
                                    }
                                } else {
                                    if(cp < 125152) {
                                        return "Mende Kikakui";
                                    } else {
                                        if(cp < 125184) {
                                            return "";
                                        } else {
                                            return "Adlam";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 126208) {
                                    if(cp < 126064) {
                                        return "";
                                    } else {
                                        if(cp < 126144) {
                                            return "Indic Siyaq Numbers";
                                        } else {
                                            return "";
                                        }
                                    }
                                } else {
                                    if(cp < 126288) {
                                        return "Ottoman Siyaq Numbers";
                                    } else {
                                        if(cp < 126464) {
                                            return "";
                                        } else {
                                            return "Arabic Mathematical Alphabetic Symbols";
                                        }
                                    }
                                }
                            }
                        } else {
                            if(cp < 127744) {
                                if(cp < 127136) {
                                    if(cp < 126976) {
                                        return "";
                                    } else {
                                        if(cp < 127024) {
                                            return "Mahjong Tiles";
                                        } else {
                                            return "Domino Tiles";
                                        }
                                    }
                                } else {
                                    if(cp < 127232) {
                                        return "Playing Cards";
                                    } else {
                                        if(cp < 127488) {
                                            return "Enclosed Alphanumeric Supplement";
                                        } else {
                                            return "Enclosed Ideographic Supplement";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 128640) {
                                    if(cp < 128512) {
                                        return "Miscellaneous Symbols and Pictographs";
                                    } else {
                                        if(cp < 128592) {
                                            return "Emoticons";
                                        } else {
                                            return "Ornamental Dingbats";
                                        }
                                    }
                                } else {
                                    if(cp < 128768) {
                                        return "Transport and Map Symbols";
                                    } else {
                                        if(cp < 128896) {
                                            return "Alchemical Symbols";
                                        } else {
                                            return "Geometric Shapes Extended";
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if(cp < 183984) {
                            if(cp < 130048) {
                                if(cp < 129536) {
                                    if(cp < 129280) {
                                        return "Supplemental Arrows-C";
                                    } else {
                                        return "Supplemental Symbols and Pictographs";
                                    }
                                } else {
                                    if(cp < 129648) {
                                        return "Chess Symbols";
                                    } else {
                                        if(cp < 129792) {
                                            return "Symbols and Pictographs Extended-A";
                                        } else {
                                            return "Symbols for Legacy Computing";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 173824) {
                                    if(cp < 131072) {
                                        return "";
                                    } else {
                                        if(cp < 173792) {
                                            return "CJK Unified Ideographs Extension B";
                                        } else {
                                            return "";
                                        }
                                    }
                                } else {
                                    if(cp < 177984) {
                                        return "CJK Unified Ideographs Extension C";
                                    } else {
                                        if(cp < 178208) {
                                            return "CJK Unified Ideographs Extension D";
                                        } else {
                                            return "CJK Unified Ideographs Extension E";
                                        }
                                    }
                                }
                            }
                        } else {
                            if(cp < 917504) {
                                if(cp < 195104) {
                                    if(cp < 191472) {
                                        return "CJK Unified Ideographs Extension F";
                                    } else {
                                        if(cp < 194560) {
                                            return "";
                                        } else {
                                            return "CJK Compatibility Ideographs Supplement";
                                        }
                                    }
                                } else {
                                    if(cp < 196608) {
                                        return "";
                                    } else {
                                        if(cp < 201552) {
                                            return "CJK Unified Ideographs Extension G";
                                        } else {
                                            return "";
                                        }
                                    }
                                }
                            } else {
                                if(cp < 918000) {
                                    if(cp < 917632) {
                                        return "Tags";
                                    } else {
                                        if(cp < 917760) {
                                            return "";
                                        } else {
                                            return "Variation Selectors Supplement";
                                        }
                                    }
                                } else {
                                    if(cp < 983040) {
                                        return "";
                                    } else {
                                        if(cp < 1048576) {
                                            return "Supplementary Private Use Area-A";
                                        } else {
                                            return "Supplementary Private Use Area-B";
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}