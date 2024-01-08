// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./ERC20.sol";
import "./Administration.sol";

contract Strip is ERC20, Administration {

    uint256 private _initialTokens = 500000000 ether;
    address public game;
    
    constructor() ERC20("STRIP", "STRIP") {
        
    }
    
    function setGameAddress(address game_) external onlyAdmin {
        game = game_;
    }
    
    function buy(uint price) external onlyAdmin {
        _burn(tx.origin, price);
    }
    
    function initialMint() external onlyAdmin {
        require(totalSupply() == 0, "ERROR: Assets found");
        _mint(owner(), _initialTokens);
    }

    function mintTokens(uint amount) public onlyAdmin {
        _mint(owner(), amount);
    }
    
    function burnTokens(uint amount) external onlyAdmin {
        _burn(tx.origin, amount);
    }
    
    function approveOwnerTokensToGame() external onlyAdmin {
        _approve(owner(), game, _initialTokens);
    }
    
    function approveHolderTokensToGame(uint amount) external {
       _approve(tx.origin, game, amount);
    }

    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
}