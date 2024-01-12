// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "./ERC20.sol";
import "./Administration.sol";

contract TUSK is ERC20, Administration {
    
    constructor() ERC20("Pop Elephants TUSK", "TUSK") {
        
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