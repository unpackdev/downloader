//SPDX-License-Identifier: MIT
//Inspired by https://github.com/mikker/svgnft

pragma solidity ^0.8.4;

import "./Base64.sol";

library NFTweetMetaData {
    function tokenURI(
        string memory tokenName,
        string memory tokenDescription,
        string memory _initialSvg,
        string memory _endSvg
    ) internal pure returns (string memory) {
        string memory json = string(abi.encodePacked('{"name":"', tokenName, '","description":"', tokenDescription, '","image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(string(abi.encodePacked(_initialSvg,tokenDescription,_endSvg)))),'"}'));
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }
}
