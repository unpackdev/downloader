// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721.sol";

/*
**************************************************************
**************************************************************
*   ______   __   __________   ______   __     __     ______ *
*../  _   |.|  |.(___    ___)./  _   |.|  |...|  |.../  _   |*
*./  /.|  |.|  |.....|  |... /  /.|  |.|  |...|  |../  /.|  |*
*|  (__|  |.|  |.....|  |...|  (__|  |.|  \.../  |.|  (__|  |*
*|   __   |.|  |___ .|  |...|   __   |..\  \_/  /..|   __   |*
*|__(..(__|.|______|.|__|...|__(..(__|...\_____/...|__(..(__|*
*                                                            *
**************************************************************
*                                _   _                       *
*                               | | | |                      *
*                           __ _| |_| |_  __ _ __    __ __ _ *
*                          / _` | |_   _|/ _` |\ \  / // _` |*
*                         | (_| | | | | | (_| | \ \/ /| (_| |*
*                          \__,_|_| |_|  \__,_|  \__/  \__,_|*
**************************************************************
**************************************************************
*/

contract SecondSkinRevealFactory is Ownable {
    SecondSkinERC721 private asset;
    address private assetAddress;
    
    uint256 private arrayIndex = 0;

    string metadata = "";
    
    string[] HashData;
    uint256 _shifted = 0;

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
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory bab = bytes(ab);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

    function Reveal(uint256 _amount) public onlyOwner {
        require(HashData.length >= arrayIndex + _amount);

        asset = SecondSkinERC721(assetAddress);

        for (uint256 i = 0; i < _amount; i++) {
            asset.setTokenUri(arrayIndex+1, strConcat(metadata, getHashData(arrayIndex)));
            arrayIndex ++;
        }
    }

    function addData(string[] calldata _data) public onlyOwner {
        for (uint256 i = 0; i < _data.length; i++) {
            HashData.push(_data[i]);
        }
    }

    function shuffleData() public onlyOwner {
        for (uint256 i = 0; i < HashData.length; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp))) % (HashData.length - i);
            string memory temp = HashData[n];
            HashData[n] = HashData[i];
            HashData[i] = temp;
        }
    }

    function shiftList(uint256 _amount) public onlyOwner {
        _shifted = _amount;
    }

    function getIndexCursor() public view returns (uint256) {
        return arrayIndex;
    }

    function getMetadata() public view returns (string memory) {
        return metadata;
    }

    function setMetadata(string memory _metadata) public onlyOwner {
        metadata = _metadata;
    }

    function getAssetAddress() public view returns (address) {
        return assetAddress;
    }

    function getHashData(uint256 _index) public view returns (string memory) {
        uint256 tmp;
        if (HashData.length <= _index + _shifted) {
            tmp = _index + _shifted - HashData.length;
        } else {
            tmp = _index + _shifted;
        }
        return HashData[tmp];
    }
    function hashlength () public view returns ( uint256 ){
        return HashData.length;
    }
    function setAssetAddress(address _assetAddress) public onlyOwner {
        assetAddress = _assetAddress;
    }

    function returnAssetOwnership() public onlyOwner {
        asset = SecondSkinERC721(assetAddress);
        asset.transferOwnership(msg.sender);
    }

}