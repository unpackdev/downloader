// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20.sol";
import "./ReentrancyGuard.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Carrot is ERC20, ReentrancyGuard {
    IERC721 private constant HB =
        IERC721(0x700B4b9F39Bb1Faf5D0D16a20488F2733550bFf4);

    mapping(uint256 => bool) public claimed;

    constructor() ERC20("Carrot", "HBC") {}

    function claim(uint256 tokenId) external nonReentrant {
        require(!claimed[tokenId], "Already claimed");
        require(HB.ownerOf(tokenId) == msg.sender, "Not owner");
        claimed[tokenId] = true;
        _mint(msg.sender, 7777000000000000000000);
    }

    function batchClaim(uint256[] memory tokenIds) external nonReentrant {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(!claimed[tokenIds[i]], "Already claimed");
            require(HB.ownerOf(tokenIds[i]) == msg.sender, "Not owner");
            claimed[tokenIds[i]] = true;
        }
        _mint(msg.sender, 7777000000000000000000 * tokenIds.length);
    }
}
