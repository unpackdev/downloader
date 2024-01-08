// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract ItemStore is Ownable {
    mapping(address => uint256) public nonces;
    mapping(uint256 => uint256) public itemPrices;

    function setPrices(uint256[] calldata ids, uint256[] calldata prices) external onlyOwner {
        require(ids.length == prices.length, "Maidverse: Length not equal");
        for(uint256 i = 0; i < ids.length; i++) {
            itemPrices[ids[i]] = prices[i];
        }
    }

    function buyItem(bytes32 hash, uint256 itemId) external payable {
        require(hash == keccak256(abi.encodePacked(msg.sender, nonces[msg.sender]++, itemId)), "Maidverse: Wrong hash");
        require(msg.value == itemPrices[itemId] && msg.value > 0, "Maidverse: Wrong price");
    }

    function buyItems(bytes32[] calldata hashes, uint256[] calldata itemIds) external payable {
        require(hashes.length == itemIds.length, "Maidverse: Length not equal");
        uint256 nonce = nonces[msg.sender];
        uint256 price;
        for(uint256 i = 0; i < hashes.length; i++) {
            require(hashes[i] == keccak256(abi.encodePacked(msg.sender, nonce++, itemIds[i])), "Maidverse: Wrong hash");
            price += itemPrices[itemIds[i]];
        }
        require(msg.value == price && price > 0, "Maidverse: Wrong price");

        nonces[msg.sender] = nonce;
    }

    function withdraw(address payable recipient, address token, uint256 amount) external onlyOwner {
        if(token == address(0)) {
            uint256 ethBal = address(this).balance;
            require(ethBal > 0, "Maidverse: Zero amount");
            if(ethBal < amount) amount = ethBal;
            recipient.transfer(amount);
        } else {
            uint256 tokenBal = IERC20(token).balanceOf(address(this));
            require(tokenBal > 0, "Maidverse: Zero amount");
            if(tokenBal < amount) amount = tokenBal;
            SafeERC20.safeTransfer(IERC20(token), recipient, amount);
        }
    }
}
