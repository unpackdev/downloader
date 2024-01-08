pragma solidity ^0.6.12;

library StringsUtil {
  // via https://github.com/provable-things/ethereum-api/blob/master/provableAPI_0.6.sol
    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
  } 

  function equal(string memory a, string memory b) internal pure returns (bool) {
      return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

   // NOTE! If you don't make library functions internal, then you have to do annoying linking steps during migration

   /**
   * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
   */
  function validateName(string memory str) internal pure returns (bool){
      bytes memory b = bytes(str);
      if(b.length < 1 ||
         b.length > 25 || // Cannot be longer than 25 characters
         b[0] == 0x20 || // Leading space
        // Trailing space
         b[b.length - 1] == 0x20) {

        return false; 
      }
           

      bytes1 lastChar = b[0];

      for(uint i; i<b.length; i++){
          bytes1 char = b[i];

          if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

          if(
              !(char >= 0x30 && char <= 0x39) && //9-0
              !(char >= 0x41 && char <= 0x5A) && //A-Z
              !(char >= 0x61 && char <= 0x7A) && //a-z
              !(char == 0x20) //space
          )
              return false;

          lastChar = char;
      }

      return true;
  }


  function toLower(string memory str) internal pure returns (string memory){
       bytes memory bStr = bytes(str);
       bytes memory bLower = new bytes(bStr.length);
       for (uint i = 0; i < bStr.length; i++) {
           // Uppercase character
           if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
               bLower[i] = bytes1(uint8(bStr[i]) + 32);
           } else {
               bLower[i] = bStr[i];
           }
       }
       return string(bLower);
  }

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
       if (_i == 0) {
           return "0";
       }
       uint j = _i;
       uint len;
       while (j != 0) {
           len++;
           j /= 10;
       }
       bytes memory bstr = new bytes(len);
       uint k = len - 1;
       while (_i != 0) {
           bstr[k--] = byte(uint8(48 + _i % 10));
           _i /= 10;
       }
       return string(bstr);
  }
}
