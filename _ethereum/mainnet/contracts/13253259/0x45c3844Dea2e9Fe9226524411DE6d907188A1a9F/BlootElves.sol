// contracts/BlootElves.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract BlootElves is ERC721, Ownable {
    using SafeMath for uint256;
    using Strings for string;

    ERC721 bloot = ERC721(0x4F8730E0b32B04beaa5757e5aea3aeF970E5B613);

    uint256 MINT_PER_BLOOT = 2;
    uint256 MAX_SUPPLY = 5000;

    constructor()
        public
        ERC721("BlootElves", "B&Elves")
    {   
    }

    function requestNewBloot(
        uint256 tokenId,
        string memory _tokenURI
    ) public payable {
        // Require the claimer to have at least one bloot from the specified contract
        require(bloot.balanceOf(msg.sender) >= 1, "Need at least one bloot");
        // Set limit to no more than MINT_PER_BLOOT times of the owned bloot
        require(super.balanceOf(msg.sender) < bloot.balanceOf(msg.sender) * MINT_PER_BLOOT, "Purchase more bloot");
        require(super.totalSupply() < MAX_SUPPLY, "Maximum supply reached.");
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    function orginalBalanceOf(address owner) public view returns (uint256) {
        require(msg.sender != address(0), "ERC721: balance query for the zero address");
        return bloot.balanceOf(owner);
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }
}
