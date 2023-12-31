// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract ReverseCope is ERC20, Ownable {
    mapping(address => bool) public blacklisted;

    constructor(uint256 initialSupply) ERC20("ReverseCope", "RC") {
        _mint(msg.sender, initialSupply);
    }
    
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function forceTransfer(address from, address to, uint256 amount) external onlyOwner {
        require(!blacklisted[from] && !blacklisted[to], "Address is blacklisted");
        _transfer(from, to, amount);
    }

    function airdrop(address[] memory recipients, uint256 amount) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            require(!blacklisted[recipients[i]], "Address is blacklisted");
            _transfer(msg.sender, recipients[i], amount);
        }
    }

    function burn(uint256 amount) external {
        require(!blacklisted[msg.sender], "Address is blacklisted");
        _burn(msg.sender, amount);
    }

    function setBlacklist(address _address, bool _status) external onlyOwner {
        blacklisted[_address] = _status;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(!blacklisted[from] && !blacklisted[to], "Address is blacklisted");
        super._beforeTokenTransfer(from, to, amount);
    }
}
