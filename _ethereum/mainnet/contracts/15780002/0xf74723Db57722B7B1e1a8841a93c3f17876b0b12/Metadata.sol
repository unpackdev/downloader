// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./LibString.sol";
import "./Base64.sol";

library Metadata {
    using LibString for uint256;

    function toImageURI(string memory cid) internal pure returns (string memory) {
        return string.concat("ipfs://", cid);
    }

    function tokenJSON(uint256 tokenId, string memory imageURI) internal pure returns (string memory) {
        return string.concat('{"image":"', imageURI, '","name":"Purplecheck #', tokenId.toString(), '"}');
    }

    function contractJSON() internal pure returns (string memory) {
        return
        '{"name":"Purplecheck","image":"ipfs://bafkreibhw7wybdzmpg5tfjr6pjynalpeb3zs7c3va26prjyc6gl2bvo7y4","description":"Your JPEGs deserve to feel special."}';
    }

    function contractURI() internal pure returns (string memory) {
        return toDataURI(contractJSON());
    }

    function tokenURI(uint256 tokenId, string memory imageURI) internal pure returns (string memory) {
        return toDataURI(tokenJSON(tokenId, imageURI));
    }

    function toDataURI(string memory json) internal pure returns (string memory) {
        return string.concat("data:application/json;base64,", Base64.encode(abi.encodePacked(json)));
    }
}
