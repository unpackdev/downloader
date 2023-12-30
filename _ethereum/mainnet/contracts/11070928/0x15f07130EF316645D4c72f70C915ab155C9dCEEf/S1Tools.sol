pragma solidity ^0.5.17;


contract S1Tools{
    

    uint256 public version = 2;
    
    function toUPPER(string memory source) public pure returns (string memory result) {
        bytes memory bufSrc = bytes(source);
        if (bufSrc.length == 0) {
            return "";
        }

        for(uint256 i=0;i<bufSrc.length;i++){
            uint8 test = uint8(bufSrc[i]);
            if(test>=97 && test<= 122)
                bufSrc[i] = byte(test - 32);
        }
        
        return string(bufSrc);

    }
    
    function toString(uint256 value) public pure returns (string memory) {
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = byte(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
    
   function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        
        assembly {
            result := mload(add(source, 32))
        }
    }
    
    
    function stringToBytes8(string memory source) public pure returns (bytes8 result) {
        
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        
        assembly {
            result := mload(add(source, 32))
        }
    }
    
    
    
    
}