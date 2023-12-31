pragma solidity ^0.7.3;

import "./MixinOwnable.sol";
import "./LibString.sol";

contract MixinTokenURI is Ownable {
    using LibString for string;

    string public baseMetadataURI = "";

    function setBaseMetadataURI(string memory newBaseMetadataURI) public onlyOwner() {
        baseMetadataURI = newBaseMetadataURI;
    }

    function uri(uint256 _id) public view returns (string memory) {
        return LibString.strConcat(
        baseMetadataURI,
        LibString.uint2hexstr(_id)
        );
    }
}