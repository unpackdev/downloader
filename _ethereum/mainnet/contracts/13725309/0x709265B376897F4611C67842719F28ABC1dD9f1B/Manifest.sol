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

import "./Base64.sol";
import "./Helpers.sol";
import "./Sacred.sol";



/** @title Daemonica Manifest library
  * @author @0xAnimist
  * @notice Manifests Daemonica entities
  */
library Manifest {

   string public constant DELIMITER = " ";


   /** @notice Packs numerical matrix values into a DELIMITER-delimited string
     * @param _theta The 8 x 8 matrix of uint8 values
     * @return String representation of the matrix
     */
   function packSvg(uint8[8][8] memory _theta) public pure returns (string memory) {
     string[17] memory parts;
     parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 666 888"><style>.en { fill: #973036; font-family: serif; font-size: 30px; letter-spacing: 3px; white-space: pre; text-align: justify; text-justify: inter-word;}</style><rect width="100%" height="100%" fill="black"/><text y="150" class="en">';

     parts[1] = Helpers.stringifyRow(_theta[0], DELIMITER);//row 0

     parts[2] = '</text><text y="195" class="en">';

     parts[3] = Helpers.stringifyRow(_theta[1], DELIMITER);//row 1

     parts[4] = '</text><text y="240" class="en">';

     parts[5] = Helpers.stringifyRow(_theta[2], DELIMITER);//row 2

     parts[6] = '</text><text y="285" class="en">';

     parts[7] = Helpers.stringifyRow(_theta[3], DELIMITER);//row 3

     parts[8] = '</text><text y="330" class="en">';

     parts[9] = Helpers.stringifyRow(_theta[4], DELIMITER);//row 4

     parts[10] = '</text><text y="375" class="en">';

     parts[11] = Helpers.stringifyRow(_theta[5], DELIMITER);//row 5

     parts[12] = '</text><text y="420" class="en">';

     parts[13] = Helpers.stringifyRow(_theta[6], DELIMITER);//row 6

     parts[14] = '</text><text y="465" class="en">';

     parts[15] = Helpers.stringifyRow(_theta[7], DELIMITER);//row 7

     parts[16] = '</text></svg>';

     string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
     output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));

     return output;
   }


   /** @notice Packs an entity's attributes into a string for rendering as metadata
     * @param _tau The dims of an entity at the given moment in 3d time
     * @param _tick The tick value of an entity at the given moment in 3d time
     */
   function packAttributes(string[] memory _tau, uint256 _tick) public pure returns (string memory) {
     string memory attributes = string(abi.encodePacked(
       '"attributes": [{ "tick": ',
       Helpers.toString(_tick),
       '},{ "trait_type": "dimensions", "value": ',
       Helpers.toString(_tau.length),
       '}'
     ));

     if(_tau.length > 0){
       for(uint8 i = 0; i < _tau.length-1; i++){
         attributes = string(abi.encodePacked(attributes, ',{ "trait_type": "dimension", "value": "', _tau[i], '"}'));
       }
       return string(abi.encodePacked(attributes, ',{ "trait_type": "dimension", "value": "', _tau[_tau.length-1], '"}],'));
     }else{
       return string(abi.encodePacked(attributes, '],'));
     }
   }


   /** @notice Manifests a Daemonica entity
     * @param _tokenId The _tokenId of the entity to render
     * @param _theta The matrix of frequency values of the entity at the given moment in 3d time
     * @param _tau The dims of an entity at the given moment in 3d time
     * @param _tick The tick value of an entity at the given moment in 3d time
     * @param _newday The corresponding block.timestamp to the given moment in 3d time
     */
   function entity(
     uint256 _tokenId,
     uint8[8][8] memory _theta,
     string[] memory _tau,
     uint256 _tick,
     uint256 _newday
   ) public pure returns (string memory) {
     string memory svg = packSvg(_theta);

     string memory attributes;

     if(_newday > 0){
       attributes = string(abi.encodePacked(
         '"manifested": ',
         Helpers.toString(_newday),
         ',',
         attributes,
         packAttributes(_tau, _tick)
       ));
     }else{
       attributes = string(abi.encodePacked('"manifested": 0,'));
     }

     string memory json = Base64.encode(
       bytes(
         string(
           abi.encodePacked(
             '{"name": "',
             Sacred.callBy(_tokenId),
             '", "description": "Daemonican entity ',
             Helpers.toString(_tokenId),
             '\u002F8888: ',
             '\u03BE = Xi, *in intentione recta*. Ludwig Wittgenstein used \u03BE as a variable in Tractatus Logico-Philosophicus to represent aspects of his \u201Cpropositions\u201D. He was a mystic who hid his incantations in his philosophy, like how 6.522 + 2.003 = 7. A Daemonican entity is also a proposition, *qualitas occulta*.',
             '", ',
             attributes,
             '"image": "data:image/svg+xml;base64,',
             Base64.encode(bytes(svg)), '"}'
           )
         )
       )
     );

     return string(abi.encodePacked('data:application/json;base64,', json));
   }

}
