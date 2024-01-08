//   _    _       _               _         ____              _____           _      __  
//  | |  | |     (_)             | |       / / _|            / ____|         | |     \ \ 
//  | |  | |_ __  _  ___ ___   __| | ___  | | |_ ___  _ __  | |  __  ___  ___| | _____| |
//  | |  | | '_ \| |/ __/ _ \ / _` |/ _ \ | |  _/ _ \| '__| | | |_ |/ _ \/ _ \ |/ / __| |
//  | |__| | | | | | (_| (_) | (_| |  __/ | | || (_) | |    | |__| |  __/  __/   <\__ \ |
//   \____/|_| |_|_|\___\___/ \__,_|\___| | |_| \___/|_|     \_____|\___|\___|_|\_\___/ |
//                                         \_\                                       /_/ 
//
// An NFT contract for Unicode characters. Strictly limited supply of 143,859, but only one u.
// Free to mint - call `mintAny()` or `mintAll()`.

// File: UnicodeMap.sol


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

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol



pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol



pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol



pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File: @openzeppelin/contracts/token/ERC721/ERC721.sol



pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: unicode.sol


pragma solidity ^0.8.2;




/// @title Base64
/// @author Brecht Devos - <brecht@loopring.org>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

contract UnicodeForGeeks is ERC721, Ownable {
    constructor() ERC721("Unicode (for Geeks)", hex"efbfbd") {}

    /**
     * @dev Mints all the characters in `chars`. Reverts if any are already minted.
     * @param to The address that should own the newly minted characters.
     * @param chars The characters to mint.
     */
    function mintAll(address to, string calldata chars) external {
        for(uint256 offset = 0; offset < bytes(chars).length;) {
            (uint256 codepoint, uint256 len) = charToCodepoint(chars, offset);
            // Check the character is valid
            require(bytes(UnicodeMap.codepointToBlock(codepoint)).length > 0, "Invalid character");
            _safeMint(to, codepoint);
            offset += len;
        }
    }
    
    /**
     * @dev Mints any of the characters in `chars` that are not already minted.
     * @param to The address that should own the newly minted characters.
     * @param chars The characters to mint.
     */
    function mintAny(address to, string calldata chars) external {
        for(uint256 offset = 0; offset < bytes(chars).length;) {
            (uint256 codepoint, uint256 len) = charToCodepoint(chars, offset);
            // Check the character is valid
            require(bytes(UnicodeMap.codepointToBlock(codepoint)).length > 0, "Invalid character");
            if(!_exists(codepoint)) {
                _safeMint(to, codepoint);
            }
            offset += len;
        }
    }
    
    /**
     * @dev Reads the UTF-8 character starting at `offset` from `char`.
     * @param char The string containing the chararacter to read.
     * @param offset The offset to start reading at.
     * @return codepoint The Unicode codepoint at `offset`.
     * @return len The length in bytes of the unicode character just read.
     */
    function charToCodepoint(string memory char, uint256 offset) public pure returns(uint256 codepoint, uint256 len) {
        bytes memory ch = bytes(char);
        if(ch[offset] & 0x80 == 0) {
            require(ch.length >= offset + 1, "Invalid unicode chacter");
            return (uint256(uint8(ch[offset])), 1);
        }
        if(ch[offset] & 0xE0 == 0xC0) {
            require(ch.length >= offset + 2 && ch[offset + 1] & 0xC0 == 0x80, "Invalid unicode chacter");
            return ((uint256(uint8(ch[offset] & 0x1F)) << 6) | uint256(uint8(ch[offset + 1] & 0x3F)), 2);
        }
        if(ch[offset] & 0xF0 == 0xE0) {
            require(ch.length >= offset + 3 && ch[offset + 1] & 0xC0 == 0x80 && ch[offset + 2] & 0xC0 == 0x80, "Invalid unicode chacter");
            return ((uint256(uint8(ch[offset] & 0x0F)) << 12) | (uint256(uint8(ch[offset + 1] & 0x3F)) << 6) | uint256(uint8(ch[offset + 2] & 0x3F)), 3);
        }
        if(ch[offset] & 0xF8 == 0xF0) {
            require(ch.length >= offset + 4 && ch[offset + 1] & 0xC0 == 0x80 && ch[offset + 2] & 0xC0 == 0x80 && ch[offset + 3] & 0xC0 == 0x80, "Invalid unicode chacter");
            return ((uint256(uint8(ch[offset] & 0x07)) << 18) | (uint256(uint8(ch[offset + 1] & 0x3F)) << 12) | (uint256(uint8(ch[offset + 2] & 0x3F)) << 6) | uint256(uint8(ch[offset + 3] & 0x3F)), 4);
        }
        revert("Invalid unicode chacter");
    }
    
    /**
     * @dev Converts a Unicode codepoint into a single-character UTF-8 string.
     * @param cp The codepoint to convert.
     * @return The UTF-8 string.
     */
    function codepointToChar(uint256 cp) public pure returns(string memory) {
        if(cp <= 0x7F) {
            bytes memory ret = new bytes(1);
            ret[0] = bytes1(uint8(cp));
            return string(ret);
        }
        if(cp <= 0x7FF) {
            bytes memory ret = new bytes(2);
            ret[0] = bytes1(uint8(0xC0 | (cp >> 6)));
            ret[1] = bytes1(uint8(0x80 | (cp & 0x3F)));
            return string(ret);
        }
        if(cp <= 0xFFFF) {
            bytes memory ret = new bytes(3);
            ret[0] = bytes1(uint8(0xE0 | (cp >> 12)));
            ret[1] = bytes1(uint8(0x80 | ((cp >> 6) & 0x3F)));
            ret[2] = bytes1(uint8(0x80 | (cp & 0x3F)));
            return string(ret);
        }
        if(cp <= 0x10FFFF) {
            bytes memory ret = new bytes(4);
            ret[0] = bytes1(uint8(0xF0 | (cp >> 18)));
            ret[1] = bytes1(uint8(0x80 | ((cp >> 12) & 0x3F)));
            ret[2] = bytes1(uint8(0x80 | ((cp >> 6) & 0x3F)));
            ret[3] = bytes1(uint8(0x80 | (cp & 0x3F)));
            return string(ret);
        }
        revert("Invalid codepoint");
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory svgch = codepointToChar(tokenId);
        string memory jsonch = svgch;
        if(tokenId == 60) { // <
            svgch = "&lt;";
        } else if(tokenId == 38) { // &
            svgch = "&amp;";
        } else if(tokenId == 34) { // "
            jsonch = '\\"';
        }
        string memory svg = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidyMid meet" viewBox="0 0 400 400"><style>.ch { text-anchor: middle; dominant-baseline: middle; fill: white; font-family: serif; font-size: 96px; }</style><rect width="100%" height="100%" fill="black" /><text x="200" y="200" class="ch">', svgch, '</text></svg>'));
        string memory json = string(abi.encodePacked('{"name":"', jsonch, '","description":"The unicode character ', jsonch, '","attributes":[{"trait_type":"Character Type","value":"', UnicodeMap.codepointToBlock(tokenId) ,'"}],"image":"data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'));
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));
    }
}