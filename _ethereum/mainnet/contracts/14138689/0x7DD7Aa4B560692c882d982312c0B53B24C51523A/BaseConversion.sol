// SPDX-License-Identifier: UNKNOWN

pragma solidity ^0.8.0;

/**
 * @dev Base 32 operations.
 */
contract BaseConversion {

function _byteToUTF8(bytes1 _conv) private pure returns (string memory){
    bytes memory byteArray = new bytes(1);
    byteArray[0] = _conv;
    return string(byteArray);
}

function _get5BitsAsUint(bytes30 input, uint8 position) private pure returns (uint8){
    bytes30 temp = input;
    temp = temp << (position * 5);
    bytes30 mask = 0xf80000000000000000000000000000000000000000000000000000000000;
    temp = temp & mask;
    temp = temp >> 235;  // 32 * 8 - 5
    return uint8(uint240((temp)));
}

function _uintToChar(uint8 _conv, uint8 _addand) private pure returns (bytes1){
    if (_conv < 26){
        return bytes1(_conv + _addand);
    }
    else {
        return bytes1(_conv + 24);
    }
}

function _bytes30ToString(bytes30 input, uint8 length, bytes1 multibase) private pure returns (bytes memory){
    bytes memory bytesArray = new bytes(length);
    uint8 i = 0;
    uint8 addand = multibase == 0x42 ? 65 : 97;
    for(i = 0; i < length; i++){
        uint8 bit = _get5BitsAsUint(input, i);
        bytesArray[i] = _uintToChar(bit, addand);
    }
    return bytesArray;
}

function byteArraysToBase32String(bytes30 digest1, bytes30 digest2, bytes1 multibase, uint16 length) internal pure returns (string memory){
    if (length > 240){
        bytes memory string1 = _bytes30ToString(digest1, 48, multibase);
        bytes memory string2 = _bytes30ToString(digest2, uint8((length - 240) / 5), multibase);
        return string(bytes.concat(string1, string2));
    }
    else{
        return string(bytes.concat(_bytes30ToString(digest1, uint8(length / 5), multibase)));
    }
}

function base32stringToBytes(string memory input) internal pure returns (bytes30 digest1, bytes30 digest2, bytes1 multibase, uint16 length){
    bytes memory bytesArray =  bytes(input);
    uint i = 0;
    uint wordlength = bytesArray.length;
    
    multibase = bytesArray[0];
    uint8 firstByte = uint8(multibase);
    require(firstByte == 98 || firstByte == 66, "Invalid rfc4648 string");
    
    uint8 lower = firstByte - 2;
    uint8 upper = firstByte + 25;
    uint8 alpha = lower + 1;

    for(i = 0; i < wordlength; i++){
        uint8 thisByte = uint8(bytesArray[i]);
        
        require((thisByte > lower && thisByte < upper) || (thisByte > 49 && thisByte < 56), "Invalid base32 string");

        if (thisByte > (lower)){
            thisByte = thisByte - alpha;
        }
        else{
            thisByte = thisByte - 24;
        }

        bytes30 tempBytes = bytes30(uint240(thisByte));
        
        if (i<48){
            tempBytes = tempBytes << (5 * (47 - i));
            digest1 = digest1 | tempBytes;
        }
        else{
            tempBytes = tempBytes << (5 * (95 - i));
            digest2 = digest2 | tempBytes;
        }
        
    }
    return (digest1, digest2, multibase, uint16(wordlength * 5));
}

// Base64URL Functions

function _get6BitsAsUint(bytes30 input, uint8 position) private pure returns (uint8){
    bytes30 temp = input;
    temp = temp << (position * 6);
    bytes30 mask = 0xfc0000000000000000000000000000000000000000000000000000000000;
    temp = temp & mask;
    temp = temp >> 234;  // 32 * 8 - 6
    return uint8(uint240((temp)));
}

function _uintToChar(uint8 _conv) private pure returns (bytes1){
    if (_conv < 26){
        return bytes1(_conv + 65);
    }
    else if (_conv < 52) {
        return bytes1(_conv + 71);
    }
    else if (_conv < 62) {
        return bytes1(_conv - 4);
    }
    else if (_conv == 62) {
        return bytes1(_conv - 17);
    }
    else if (_conv == 63){
        return bytes1(_conv + 32);
    }
    else {
        revert();
    }
}

function _bytes30ToString(bytes30 input, uint8 length) private pure returns (bytes memory){
    bytes memory bytesArray = new bytes(length);
    uint8 i = 0;
    for(i = 0; i < length; i++){
        uint8 bit = _get6BitsAsUint(input, i);
        bytesArray[i] = _uintToChar(bit);
    }
    return bytesArray;
}

function byteArraysToBase64String(bytes30 digest1, bytes30 digest2, uint16 length) internal pure returns (string memory){
    if (length > 240){
        bytes memory string1 = _bytes30ToString(digest1, 40);
        bytes memory string2 = _bytes30ToString(digest2, uint8((length - 240) / 6));
        return string(bytes.concat(string1, string2));
    }
    else{
        return string(bytes.concat(_bytes30ToString(digest1, uint8(length / 6))));
    }
}

function base64URLstringToBytes(string memory input) internal pure returns (bytes30 digest1, bytes30 digest2, bytes1 multibase, uint16 length){
    bytes memory bytesArray =  bytes(input);
    uint i = 0;
    uint wordlength = bytesArray.length;
    
    multibase = 0x75;

    for(i = 0; i < wordlength; i++){
        uint8 thisByte = uint8(bytesArray[i]);
        
        if (thisByte == 95){
            thisByte = 63;
        }
        else if (thisByte == 45){
            thisByte = 62;
        }
        else if (thisByte > 96){
            thisByte = thisByte - 71;
        }
        else if (thisByte > 64) {
            thisByte = thisByte - 65;
        }
        else if (thisByte > 47 && thisByte < 58) {
            thisByte = thisByte + 4;
        }
        else {
            revert();
        }
        
        bytes30 tempBytes = bytes30(uint240(thisByte));
        
        if (i<40){
            tempBytes = tempBytes << (6 * (39 - i));
            digest1 = digest1 | tempBytes;
        }
        else{
            tempBytes = tempBytes << (6 * (79 - i));
            digest2 = digest2 | tempBytes;
        }
        
    }
    return (digest1, digest2, multibase, uint16((wordlength) * 6));
}

}