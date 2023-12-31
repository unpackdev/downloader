// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./Base64.sol";
import "./Strings.sol";

contract LogosPhasometerMetadata is Ownable {
    string public tokenDescription =
        "The Logos are a faction of androids who collect and wear logos and other memorabilia from the fallen brands of the era of humanity.\\n\\n&nbsp;\\n\\nPhasometers are unique generative artworks that draw from the Blitmap or Blitnaut artwork that powered them. Logos characters can be crafted in October. Please join the community [Discord](https://discord.gg/blitmap) for the latest information.\\n\\n&nbsp;\\n\\nLearn more about Blitmap and the Blitmap universe by viewing [our website](https://blitmap.com).";
    string public baseUri = "https://d3g6sn21m8x1w9.cloudfront.net";

    constructor() Ownable() {}

    function updateURLs(string memory newBaseUri) public onlyOwner {
        baseUri = newBaseUri;
    }

    function updateDescription(string memory newDescription) public onlyOwner {
        tokenDescription = newDescription;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string memory imageUri = string(
            abi.encodePacked(baseUri, '/', Strings.toString(tokenId), '.jpg')
        );
        string memory videoUri = string(
            abi.encodePacked(baseUri, '/', Strings.toString(tokenId), '.mp4')
        );
        string memory json = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Phasometer ',
                                Strings.toString(tokenId),
                                '", "description": "',
                                tokenDescription,
                                '", "image": "',
                                imageUri,
                                '", "animation_url": "',
                                videoUri,
                                '", "attributes": [',
                                '{ "trait_type": "Type", "value": "',
                                tokenId < 1700 ? "Blitmap" : "Blitnaut",
                                '" }',
                                ']}'
                            )
                        )
                    )
                )
            )
        );
        return json;
    }
}
