// SPDX-License-Identifier: MIT

// https://kanon.art - K21
// https://daemonica.io
//
//
//                                   $@@@@@@@@@@@$$$
//                               $$@@@@@@$$$$$$$$$$$$$$##
//                           $$$$$$$$$$$$$$$$$#########***
//                        $$$$$$$$$$$$$$$#######**!!!!!!
//                     ##$$$$$$$$$$$$#######****!!!!=========
//                   ##$$$$$$$$$#$#######*#***!!!=!===;;;;;
//                 *#################*#***!*!!======;;;:::
//                ################********!!!!====;;;:::~~~~~
//              **###########******!!!!!!==;;;;::~~~--,,,-~
//             ***########*#*******!*!!!!====;;;::::~~-,,......,-
//            ******#**********!*!!!!=!===;;::~~~-,........
//           ***************!*!!!!====;;:::~~-,,..........
//         !************!!!!!!===;;::~~--,............
//         !!!*****!!*!!!!!===;;:::~~--,,..........
//        =!!!!!!!!!=!==;;;::~~-,,...........
//        =!!!!!!!!!====;;;;:::~~--,........
//       ==!!!!!!=!==;=;;:::~~--,...:~~--,,,..
//       ===!!!!!=====;;;;;:::~~~--,,..#*=;;:::~--,.
//       ;=============;;;;;;::::~~~-,,...$$###==;;:~--.
//      :;;==========;;;;;;::::~~~--,,....@@$$##*!=;:~-.
//      :;;;;;===;;;;;;;::::~~~--,,...$$$$#*!!=;~-
//       :;;;;;;;;;;:::::~~~~---,,...!*##**!==;~,
//       :::;:;;;;:::~~~~---,,,...~;=!!!!=;;:~.
//       ~:::::::::::::~~~~~---,,,....-:;;=;;;~,
//        ~~::::::::~~~~~~~-----,,,......,~~::::~-.
//         -~~~~~~~~~~~~~-----------,,,.......,-~~~~~,.
//          ---~~~-----,,,,,........,---,.
//           ,,--------,,,,,,.........
//             .,,,,,,,,,,,,......
//                ...............
//                    .........

pragma solidity ^0.8.0;

import "./Helpers.sol";


/*
 * @title Sacred contract
 * @author @0xAnimist
 * @notice Used for pseudorandomly assigning sacred names
 */
library Sacred {

  uint8 public constant tokensPerName = 4;
  uint8 public constant totalNgrams = 89;
  string public constant nameDelimiter = ".";


  /** @notice Returns a sacred syllable from a host of languages, ancient and
    * contemporary, based on the _index
    * @param _index The index value from 0-88
    * @return The sacred syllable ngram
    */
  function ngram(uint8 _index) public pure returns (string memory) {
    string[totalNgrams] memory ngrams = [
      //Sanskrit sacred seeds
      "\u0101\u1E25",//birth of the universe
      "o\u1E43",//opening syllable
      "h\u016B\u1E43",//closing syllable
      "dh\u012B\u1E25",//perfect wisdom
      "pha\u1E6D",//ancient magical word
      "au",//Sanskrit, "o"

      //Sanskrit consonants, Egyptian and Maori terms
      "akh",//Egyptian
      "ua",//Egyptian: "one who becomes eight" / "growth comes to be"
      "kh",//Egyptian: "pool of water rises up"
      "qet",//Egyptian: fire, grain, Serpent, "pedestal gives circle"
      "ka",//Sanskrit, Egypt
      "kha",//Sanskrit
      "ba",//Sanskrit, Egypt
      "bha",//Sanskrit
      "la",//Sanskrit
      "\u1E6Da",//Sanskrit
      "\u1E6Dha",//Sanskrit
      "pa",//Sanskrit, Maori
      "pha",//Sanskrit
      "ga",//Sanskrit
      "gha",//Sanskrit
      "ja",//Sanskrit
      "jha",//Sanskrit
      "\u1E0Da",//Sanskrit
      "\u1E0Dha",//Sanskrit
      "\u00F1a",//Sanskrit
      "ya",//Sanskrit, Dogon
      "ra",//Sanskrit, Egyptian
      "\u015Ba",//Sanskrit

      //Dogon
      "\u0119mm\u0119",//from female sorghum
      "p\u014D",//digitaria
      "sigi",//Sigui, Sirius
      "tolo",//star

      //Angels
      "el",
      "ael",
      "iel",
      "al",
      "iah",
      "vehu",
      "jel",
      "nik",
      "sit",
      "man",
      "leu",

      //Goetia
      "mon",
      "eth",
      "deus",
      "aga",
      "bar",
      "ast",
      "mur",
      "ion",
      "tri",
      "nab",
      "ius",

      //Faerie
      "tit",
      "mabd",
      "elf",
      "gno",
      "tua",
      "d\u00E9",
      "aos",
      "s\u00ED",

      //Q'ero
      "ayni",
      "hua",
      "nee",
      "ska",

      //Greek
      "nym",
      "pan",
      "syb",

      //Urbit
      "zod",
      "bin",
      "ryx",

      //Chinese
      "tian",
      "ren",
      "jing",
      "dao",
      "zhi",
      "ye",
      "xu",
      "shi",
      "gu\u01D0",

      //Shintoism
      "ama",
      "chi",
      "edo",
      "gi",
      "kon",
      "oni",
      "sei"
    ];

    return ngrams[_index];
  }


  /** @notice Pseudorandomly selects and punctuates an ngram
    * @param _tokenId The _tokenId of the token name to reveal
    * @param _index The index of the ngram (for names with > 1 ngram)
    * @return The resulting ngram
    */
  function pluckNGram(uint256 _tokenId, uint256 _index) public pure returns (string memory) {
      uint256 rand = Helpers.random(string(abi.encodePacked(Helpers.toString(_index), Helpers.toString(_tokenId))));
      string memory output = ngram(uint8(rand % totalNgrams));
      //punctuate pseudorandomly
      if(_index < (tokensPerName - 1)){
        uint256 daemonicPotential  = rand % 33;
        if (daemonicPotential >= 13) {
            output = string(abi.encodePacked(output, nameDelimiter));
        }
      }

      return output;
  }


  /** @notice Reveals the name of a token
    * @param _tokenId The _tokenId of the token name to reveal
    * @return The name of _tokenId
    */
  function callBy(uint256 _tokenId) public pure returns (string memory) {
    string memory name = "";

    for(uint i = 0; i < tokensPerName; i++){
      name = string(abi.encodePacked(name, pluckNGram(_tokenId, i)));
    }

    return name;
  }


}
