// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IMetadataHandler.sol";


contract MetadataHandler is Ownable, IMetadataHandler{

    string public uri;
    string public renderURI;

    constructor(string memory _uri) Ownable() {
        uri = _uri;
    }

    function getTokenURI(uint fnftId) external view override returns (string memory ) {
        return string(abi.encodePacked(uri,uint2str(fnftId)));
    }

    function setTokenURI(uint fnftId, string memory _uri) external override {
        uri = _uri;
    }

    function getRenderTokenURI(
        uint tokenId,
        address owner
    ) external view override returns (string memory baseRenderURI, string[] memory parameters) {
        string[] memory arr;
        return (renderURI, arr);
    }

    function setRenderTokenURI(
        uint tokenID,
        string memory baseRenderURI
    ) external override {
        renderURI = baseRenderURI;
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

}
