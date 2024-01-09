// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MetaCollar.sol";

contract MetaCollarMinter is MetaCollar {

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address[] memory payees, 
        uint256[] memory shares
    ) MetaCollar(name, symbol, baseTokenURI, payees, shares) {}
    
    /**
     * @dev Mint Logic. Presale & Public in same function
    */
    function mint(uint256 quantity) payable public virtual nonReentrant whenNotSoldOut checkMax(quantity){
        require(!paused, 'Paused');

        if(presaleLive) {
            require(isOnAWhitelist(_msgSender()), '!whitelist');
            require(msg.value >= PRESALE_PRICE * quantity, '<cost');
            require(whitelistTotals[_msgSender()] + quantity  < 9, "whitelist limit");
        }else{
            require(msg.value >= FULL_PRICE*quantity, '<cost');
        }
        
        for (uint256 i = 0; i < quantity; i++) {
            _mint(_msgSender(), currentTokenId);
            currentTokenId++;

            if(presaleLive) {
                whitelistTotals[_msgSender()]++;
            }
        }
    }

    /**
     * @dev Airdrop functionality. Owner only able to airdrop the first 800 as public starts at 801.
    */
    function mintByOwner(address to, uint256 quantity) public nonReentrant onlyOwner checkMax(quantity){
        for(uint256 i= 0; i < quantity; i++){
            _mint(to, currentAirdropId);
            currentAirdropId++;
        } 
    }

    function togglePresale() public virtual onlyOwner{
        presaleLive = !presaleLive;
    }

    function togglePause() public virtual onlyOwner{
        paused = !paused;
    }

}