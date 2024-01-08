//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./StringUtils.sol";

library ProfanityLib {
    using strings for *;

    uint private constant one_count = 28;
    uint private constant two_count = 48;
    uint private constant three_count = 147;
    uint private constant four_count = 26;
    uint private constant color_count = 13;

    string private constant one = "shit, you're a|eat shit, you|fuck, what a|oh no, a|my partner is a|my mom is a|I'd fuck that|fuck off, you|wow, what a|baby, you're a|hey, look at the|I love my|omg u|dad, I'm a|my husband is a|mom, I'm a|ngmi, you|gm, you|shit, i'm a|my dad is a|I'm a|what a|my neighbor is a|you're a|I'm married to a|ygmi, you|my wife is a|you|i spy a";
    string private constant two = "bastardized|fancy fucking|failed|big black|kinky|rim jobbing|snowballing|sodomizing|leg spreading|cum guzzling|taint licking|wet dreaming|leaking|tea bagging|throbbing|god damn|slutty|weak ass|fucking|motherfucking|bullshitting|hot ass|nasty|naked|sexy|skanky|two bit|skanky ass|slippery|slimy|well lubed|skeezy|selfish|half assed|tight ass|lazy ass|lazy fucking|crazy ass|paper handed|diamond handed|punk ass|cheap fucking|sopping wet|dripping wet|fucking irrelevant|uneducated|dumb ass|scat munching|pindicked";
    string private constant three = "titty fucker|pussy eater|cockmuncher|shit eater|fistfucker|pegger|ass clown|fudge packer|fat ass|fuck|dickhead|shit face|wanker|douche|tit fucker|cum shot|jizz slurper|buttplug|blowjob|prickhead|squirter|vibrator|bunny fucker|deep throater|whore|face fucker|jackoff|bitch|bum fuck|pussy pounder|cock|cock cowboy|cum guzzler|cockface|dildo|sodomizer|cum fest|ass kisser|ass hole|virgin breaker|cum bubble|fingerfucker|swallower|ass blaster|sloppy slut|dick for brains|nutsack|cherry popper|crack whore|cyberfucker|numbnuts|shit stain|limp dick|snatch|cum jockey|prick|ass bagger|asshole|drip dick|donkeyribber|shit fuck|dripping cunt|sperm bag|ball licker|skin flute|soaking cunt|clit|cock sucker|cunt sucker|felcher|dripping snatch|ass muncher|orgasm|cunt|slut|fannyfucker|son of a bitch|skank|jizz face|sex slave|shit dick|dumb bitch|spready puss|bumble fuck|cock block|fat fuck|pin dick|milf|shit fucker|dilf|snowballer|fuckhead|lesbian|butthole|ass puppy|sex kitten|knob|shit can|knob jocky|ass licker|whiskey dick|boner|dick|cumshot|ass fucker|stupid fuck|anus|loose slut|ass monkey|ass hat|bastard|pussy|rimjaw|ass packer|cuntlicker|juicy snatch|dipshit|dog fucker|shithouse|pig fucker|ass jockey|ass munch|ballbag|sperm hearder|cock smoker|nobhead|ass fuck|foreskin slurper|pussy licker|dripping slut|cockhead|ballsack|cum queen|butt fucker|giant cock|carpet muncher|ass man|jerk off|scrotum|motherfucker|shit head|fist fucker|ass pirate|ass cowboy|buttmunch|breast man|cock tease|dumb fuck";
    string private constant four = "suck a dick|balls|up the ass|suck my ass|fuck em|gn, assclowns|gm shitfucks|fuck me|gm fuckers, wgmi|what a shitty nft|fucking hell|suck my titties|fuck yea... wgmi|fucking nfts|fuck you|suck me|fucking jpegs|suck my dick|eat my ass|fuck off|eat shit|fuck|titties|gm fuckheads|tits|gm assholes, wagmi|shit|jizz|ass";
    string private constant colors = "#FF0000;#FFFFFF|#ff008d;#fdff00;#00ecff;#00abff;#00ff38|#264653;#2a9d8f;#e9c46a;#f4a261;#e76f51|#1a535c;#4ecdc4;#f7fff7;#ff6b6b;#ffe66d|#FFFFFF;#000000|#EF476F;#FFD166;#FFD166;#118AB2;#073B4C|#eeeeee;#e4eaec;#ecf4f2;#e3e5e5;#ccd8d7;#EF476F|#8dbd05;#00a1ae;#5e36cc;#fe318e;#ff7540|#d00000;#ffba08;#3f88c5;#032b43;#136f63|#FF0000;#149414|#eeeeee;#CCCCCC;#999999;#666666;#333333|#ef476f;#ffd166;#06d6a0;#118ab2;#073b4c|#f72585;#7209b7;#3a0ca3;#4361ee;#4cc9f0|#FE7C00;#FFD832;#00B4AB";
    
    function random(uint max, uint seed, uint tokenId) public pure returns (uint) {
        // not really random, but since we can provide variations of the user's N as seeds it will do.
        uint randomHash = uint(keccak256(abi.encode(seed, tokenId)));
        return randomHash % max;
    }

    function getStringToken(string memory input, uint256 index) private pure returns (string memory) {
        // we need to slice up delimitted strings, because storing them all in a string array on contract is
        // cost prohibitive, whereas storing within a string is far cheaper.
        strings.slice memory s = input.toSlice();
        strings.slice memory delim = "|".toSlice();

        // just iterate and throw away anything up until our target index.
        for (uint i = 0; i <= index; i++) {
            if (i == index) {
                return s.split(delim).toString();
            } else {
                s.split(delim);
            }
        }

        return "";
    }

    function getWords(uint seedOne, uint seedTwo, uint seedThree, uint seedFour, uint tokenId) public pure returns (string memory, string memory, string memory, string memory) {
        return (
            getStringToken(one, random(one_count, seedOne, tokenId)),
            getStringToken(two, random(two_count, seedTwo, tokenId)),
            getStringToken(three, random(three_count, seedThree, tokenId)),
            getStringToken(string(abi.encodePacked(three, "|", four)), random(three_count + four_count, seedFour, tokenId))
        );
    }

    function getColorScheme(uint seed, uint tokenId) public pure returns (string memory) {
        return getStringToken(colors, random(color_count, seed, tokenId));
    }

    function getFontFace() public pure returns (string memory) {
        return '@font-face {font-family: "Early GameBoy";src: url(data:application/font-woff;base64,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);}';
    }
}