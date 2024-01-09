// SPDX-License-Identifier: MIT
/*
        ___    ___                  ___                                                          ___        ___      
       (   )  (   )                (   )                                                        (   )      (   )     
  .---. | |_   | |_    .---.  .--.  | |   ___   .--.    .-..   .--. ___ .-.  ___ .-. .-.   .--.  | |___  ___| |.-.   
 / .-, (   __)(   __) / .-, \/    \ | |  (   )/  _  \  /    \ /    (   )   \(   )   '   \ /    \ | (   )(   | /   \  
(__) ; || |    | |   (__) ; |  .-. ;| |  ' / . .' `. ;' .-,  |  .-. | ' .-. ;|  .-.  .-. |  .-. ;| || |  | ||  .-. | 
  .'`  || | ___| | ___ .'`  |  |(___| |,' /  | '   | || |  . |  | | |  / (___| |  | |  | |  |(___| || |  | || |  | | 
 / .'| || |(   | |(   / .'| |  |    | .  '.  _\_`.(___| |  | |  |/  | |      | |  | |  | |  |    | || |  | || |  | | 
| /  | || | | || | | | /  | |  | ___| | `. \(   ). '. | |  | |  ' _.| |      | |  | |  | |  | ___| || |  | || |  | | 
; |  ; || ' | || ' | ; |  ; |  '(   | |   \ \| |  `\ || |  ' |  .'.-| |      | |  | |  | |  '(   | || |  ; '| '  | | 
' `-'  |' `-' ;' `-' ' `-'  '  `-' || |    \ ; '._,' '| `-'  '  `-' | |      | |  | |  | '  `-' || |' `-'  /' `-' ;  
`.__.'_. `.__.  `.__.`.__.'_.`.__,'(___ ) (___'.___.' | \__.' `.__.(___)    (___)(___)(___`.__,'(___)'.__.'  `.__.   
                                                      | |                                                            
                                                     (___)                                                           
*/     
pragma solidity ^0.8.0;

library SpermString {
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }
}