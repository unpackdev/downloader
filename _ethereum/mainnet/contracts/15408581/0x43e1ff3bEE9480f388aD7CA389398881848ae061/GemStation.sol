// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Potion.sol";

contract GemStation is Ownable, ReentrancyGuard {
    address public potionAddress;
 
    function setPotionAddress(address addr) public onlyOwner {
        potionAddress = addr;
    }

    function deposit() external payable {
        return;
    }

    function goldenTouch(uint256 tokenId) public nonReentrant {
        Potion potion = Potion(potionAddress);
        require(potion.ownerOf(tokenId) == msg.sender, "This is not your potion.");
        require(potion.levelOf(tokenId) >= 3, "Lv.3 or Lv.4 potion is required.");
        payable(msg.sender).transfer(address(this).balance);
    }
}
