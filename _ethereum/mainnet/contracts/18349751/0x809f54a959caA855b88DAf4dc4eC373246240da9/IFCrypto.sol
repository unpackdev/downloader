// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract IFCrypto is ERC20 {
    address owner;
    
    constructor() ERC20("IFCrypto", "IFG") {
        owner = msg.sender;
        mint(msg.sender, 100000 * 10 ** 18);
    
    }
    modifier onlyOwner(){
        require(msg.sender == owner, "GFT: Only owner");
        _;

    }
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }
}