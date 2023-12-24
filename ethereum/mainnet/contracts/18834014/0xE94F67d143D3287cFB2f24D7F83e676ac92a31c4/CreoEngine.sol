// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract CreoEngine is ERC20Burnable, Ownable {
    mapping(address => bool) public locked;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _owner
    ) ERC20(_name, _symbol) {
        _mint(_owner, _totalSupply * (10**18));
        _transferOwnership(_owner);
    }

    function setLocked(address user, bool status) external onlyOwner {
        require(locked[user] != status, 'Duplicate');
        locked[user] = status;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!locked[from] && !locked[to], 'Transfer is not allowed');
        super._beforeTokenTransfer(from, to, amount);
    }
}
