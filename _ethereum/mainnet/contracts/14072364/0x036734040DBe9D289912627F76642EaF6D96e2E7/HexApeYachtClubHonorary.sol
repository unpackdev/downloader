// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Base64.sol";

contract HexApeYachtClubHonorary is ERC721Enumerable, ReentrancyGuard, Ownable {
    constructor() ERC721("HexApeYachtClubHonorary", "HAYCHONOR") Ownable() {}

    /// Token URI
    function tokenURI(uint256 tokenId)
        public
        pure
        override
        returns (string memory)
    {
        string memory output = string(
            abi.encodePacked(
                "https://gateway.pinata.cloud/ipfs/QmbQWzUxnb4DmwytWo7bVmsdibRa5Lg3XDvx7Q5kp8oYq5/",
                Strings.toString(tokenId+1),
                ".png"
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "HAYC Honorary #',
                        Strings.toString(tokenId + 1),
                        '", "description": "HAYC Honorary Membership is given to those who brought awareness to HAYC.", "image": "',
                        output,
                        '"}'
                    )
                )
            )
        );

        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return output;
    }

    /// Reserve for Owner
    function reserveForOwner() public onlyOwner returns (uint256) {
        for (uint256 i = 0; i < 20; i++) {
            _safeMint(msg.sender, i);
        }
        return totalSupply();
    }

    /// Withdraw for owner
    function withdraw() public onlyOwner returns (bool) {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        return true;
    }
}
