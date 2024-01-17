// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./ERC721A.sol";

/**
 * @author bagelface.eth (@0xbagelface)
 */
contract BagelBlock is ERC721A {
    uint256 public numOfLoops;
    uint256 public ticks;

    constructor(uint256 _numOfLoops) ERC721A("BagelBlockers", "BAGEL") {
        numOfLoops = _numOfLoops;
    }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    function setNumOfLoops(uint256 _numOfLoops) public {
        numOfLoops = _numOfLoops;
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override {
        for (uint256 i; i < numOfLoops; ++i) {
            ticks++;
        }

        ERC721A.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override {
        for (uint256 i; i < numOfLoops; ++i) {
            ticks++;
        }

        ERC721A.safeTransferFrom(from, to, tokenId, data);
    }
}