// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./ERC20.sol";
import "./Administration.sol";

contract FXY is ERC20, Administration {

    uint256 private _initialTokens = 10000000000 ether;
    
    constructor() ERC20("FXY", "FXY") {}
    
    function initialMint() external onlyAdmin {
        require(totalSupply() == 0, "ERROR: Assets found");
        _mint(owner(), _initialTokens);
    }

    function mintTokens(uint amount) public onlyAdmin {
        _mint(owner(), amount);
    }

    function mintTo(address to, uint amount) public onlyAdmin {
        _mint(to, amount);
    }
    
    function burnTokens(uint amount) external onlyAdmin {
        _burn(owner(), amount);
    }

    function buy(address from, uint amount) external onlyAdmin {
        _burn(from, amount);
    }

    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
}