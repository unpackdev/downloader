// SPDX-License-Identifier: CC0-1.0
/// @title The Helms (for Loot) Metadata

import "./Ownable.sol";
import "./base64.sol";
import "./LootInterfaces.sol";
import "./Strings.sol";

pragma solidity ^0.8.0;

interface IHelmsMetadata {
    function uri(uint256 tokenId) external view returns (string memory);
}

contract HelmsMetadata is Ownable, IHelmsMetadata {
    string public description;
    string public baseUri;
    string private imageUriSuffix = ".gif";
    string private animationUriSuffix = ".glb";
    ILmart private lmartContract;

    constructor(ILmart lmart, string memory IpfsUri) Ownable() {
        description = "Helms (for Loot) is the first 3D interpretation of the helms of Loot. Adventurers, builders, and artists are encouraged to reference Helms (for Loot) to further expand on the imagination of Loot.";
        lmartContract = lmart;
        baseUri = IpfsUri;
    }

    function setDescription(string memory desc) public onlyOwner {
        description = desc;
    }

    function setbaseUri(string calldata newbaseUri) public onlyOwner {
        baseUri = newbaseUri;
    }

    function setUriSuffix(
        string calldata newImageUriSuffix,
        string calldata newAnimationUriSuffix
    ) public onlyOwner {
        imageUriSuffix = newImageUriSuffix;
        animationUriSuffix = newAnimationUriSuffix;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory name = lmartContract.tokenName(tokenId);
        bytes memory tokenUri = abi.encodePacked(
            baseUri,
            "/",
            Strings.toString(tokenId)
        );
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "',
                        name,
                        '", ',
                        '"description": ',
                        '"Helms (for Loot) is the first 3D interpretation of the helms of Loot. Adventurers, builders, and artists are encouraged to reference Helms (for Loot) to further expand on the imagination of Loot.", ',
                        '"image": ',
                        '"',
                        tokenUri,
                        imageUriSuffix,
                        '", '
                        '"animation_url": ',
                        '"',
                        tokenUri,
                        animationUriSuffix,
                        '"'
                        "}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
