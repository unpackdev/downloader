// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./IFaithToken.sol";
import "./Ownable.sol";

contract FaithToken is ERC20, IFaithToken, Ownable {
    uint256 private immutable _cap;
    mapping(address => bool) public authorizedAddress;

    constructor() ERC20("Faith Token", "FAITH", uint8(0)) {
        authorizedAddress[msg.sender] = true;
        _cap = 1e10;
    }

    // -- Public Functions --
    function mint(address to, uint256 amount) public virtual {
        require(
            authorizedAddress[msg.sender],
            "Unauthorized sender"
        );
        _mint(to, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 allowed = allowance[account][msg.sender]; // Saves gas for limited approvals.
        if (allowed != type(uint256).max)
            allowance[account][msg.sender] = allowed - amount;
        _burn(account, amount);
    }

    function spendToken(address account, uint256 amount) public virtual {
        require(
            authorizedAddress[msg.sender],
            "Unauthorized sender"
        );
        _burn(account, amount);
    }

    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    // -- Internal Functions --
    function _mint(address to, uint256 amount) internal virtual override {
        require(ERC20.totalSupply + amount <= cap(), "CAP_EXCEEDED");
        super._mint(to, amount);
    }

    // -- Authorization roles --
    function authorizeAddress(address _address) external onlyOwner {
        authorizedAddress[_address] = true;
    }

    function deauthorizeAddress(address _address) external onlyOwner {
        delete(authorizedAddress[_address]);
    }
}
