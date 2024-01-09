// SPDX-License-Identifier: MIT

// :::        :::::::::: :::::::::     :::      ::::::::   ::::::::  
// :+:        :+:        :+:    :+:  :+: :+:   :+:    :+: :+:    :+: 
// +:+        +:+        +:+    +:+ +:+   +:+  +:+        +:+        
// +#+        +#++:++#   +#++:++#+ +#++:++#++: +#++:++#++ +#++:++#++ 
// +#+        +#+        +#+       +#+     +#+        +#+        +#+ 
// #+#        #+#        #+#       #+#     #+# #+#    #+# #+#    #+# 
// ########## ########## ###       ###     ###  ########   ########  
// 01100101 01100011 01100001 01101100 01101100                      

pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Burnable.sol";

contract LePass is ERC1155, Ownable, Pausable, ERC1155Burnable {
    uint256 public totalSupply = 4096;
    uint256 public maxPerWallet = 1;
    uint256 public supply = 20;
    uint256 public minted = 0;
    uint256 public cost = 1 ether;
    
    constructor() ERC1155("https://mypinata.cloud/ipfs/QmV8h5w4F4KmwtdXb2nRZZQzK2wB5zdgWo3kmMXjrCFYca") {
        mint(10);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    //only owner
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setSupply(uint256 _newSupply) public onlyOwner {
        require(_newSupply <= totalSupply, "New supply cannot exceed totalSupply");
        supply = _newSupply;
    }

    function setMaxPerWallet(uint256 _newMaxPerWallet) public onlyOwner {
        maxPerWallet = _newMaxPerWallet;
    }


    function mint(uint256 amount)
        public payable whenNotPaused
    {
        require ( minted + amount <= supply, "Not enough supply");
         if (msg.sender != owner()) {
                require(amount == 1, "You cannot mint more than one");
                uint256 passCount = balanceOf(msg.sender, 1) + amount;
                
                require(passCount < maxPerWallet + 1, "Max per wallet reached.");
                require(msg.value >= amount * cost, "Not enough ether sent");
         }
           _mint(msg.sender, 1, amount, "");
           minted += amount;
        
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
