// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/***************************************************************\
 .    . . . . . . .... .. ...................... . . . .  .   .+
   ..  .   . .. . ............................ ... ....  . .. .+
 .   .  .. .. ....... ..;@@@@@@@@@@@@@@@@@@@;........ ... .  . +
  .   .  .. ...........X 8@8X8X8X8X8X8X8X8X@ 8  ....... .. .. .+
.  .. . . ... ... .:..% 8 88@ 888888888888@%..8  .:...... . .  +
 .  . ... . ........:t:88888888@88888@8@888 ;  @......... .. ..+
.  . . . ........::.% 8 888@888888X888888  .   88:;:.:....... .+
.   . .. . .....:.:; 88888888@8888888@88      S.88:.:........ .+
 . . .. .......:.:;88 @8@8@888888@@88888.   .888 88;.:..:..... +
.  .. .......:..:; 8888888888888@88888X :  :Xt8 8 :S:.:........+
 .  .......:..:.;:8 8888888%8888888888 :. .888 8 88:;::::..... +
 . .. .......:::tS8@8888888@88%88888X ;. .@.S 8  %:  8:..:.....+
. .........:..::8888@S888S8888888888 ;. :88SS 8t8.    @::......+
 . . .....:.::.8@ 88 @88 @8 88@ 88 @::  8.8 8 8@     88:.:.....v
. . .......:.:;t8 :8 8 88.8 8:8.:8 t8..88 8 8 @ 8   88;::.:....+
.. .......:.:::;.%8 @ 8 @ .8:@.8 ;8;8t8:X@ 8:8X    88t::::.....+
. .. ......:..:::t88 8 8 8 t8 %88 88.@8 @ 888 X 8 XX;::::.::...+
..........:::::::;:X:8 :8 8 ;8.8.8 @ :88 8:@ @   8X;::::::.:...+
  . .......:.:::::; 8 8.:8 8 t8:8 8 8.;88 XX  8 88t;:::::......+
.. .......:.:.:::::; @:8.;8 8.t8 8 tt8.%8@. 8  88t;:;::::.:....+
 ... ....:.:.:.::;::; 8:8 ;8 8 t8 8:8 8.t8S. 888;;:;::::.:..:..+
.  ........::::::::;:;.t 8 ;8 8 ;88:;8.8 ;88 88S:::::::.:.:....+
 .. .. .....:.:.:::::;; 888X8S8 X@XSSS88 888X:t;;;::::::.:.....+
 .. ........:..:::::;::;%;:   .t. ;ttS:;t. .  :;;:;:::.::......+
 . . ......:.:..::::::;;;t;;:;;;;;;;;t;;;;;:: :;:;:::.:........+
/***************************************************************/

library LibSignature {

  function recoverSigner(
    bytes32 _ethSignedMessageHash,
    bytes memory _signature
  ) internal pure returns (address) {        
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);    
    return ecrecover(_ethSignedMessageHash, v, r, s);
  }

  function splitSignature(
    bytes memory sig
  ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
    require(sig.length == 65, "invalid signature length");

    assembly {
      /*
      First 32 bytes stores the length of the signature

      add(sig, 32) = pointer of sig + 32
      effectively, skips first 32 bytes of signature

      mload(p) loads next 32 bytes starting at the memory address p into memory
      */

      // first 32 bytes, after the length prefix
      r := mload(add(sig, 32))
      // second 32 bytes
      s := mload(add(sig, 64))
      // final byte (first byte of the next 32 bytes)
      v := byte(0, mload(add(sig, 96)))
    }

    // implicitly return (r, s, v)
  }

}