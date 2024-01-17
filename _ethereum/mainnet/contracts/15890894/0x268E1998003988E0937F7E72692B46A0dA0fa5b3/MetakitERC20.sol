// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./AccessControl.sol";

contract MetakitERC20 is ERC20 {
    address public adminAddress;
    address public owner;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialBalance_,
        address _adminAddress
    ) payable ERC20(name_, symbol_) {
        require(initialBalance_ > 0, 'Meta_ERC20: supply cannot be zero');
        owner = msg.sender;
        adminAddress = _adminAddress;

        _mint(address(this), initialBalance_);
    }

    function exportTokens(address playerAddress, uint256 amount)
        public
        onlyMetakit
        returns (bool)
    {
        _transfer(address(this), playerAddress, amount);
        return true;
    }

    function importTokens(address playerAddress, uint256 amount)
        public
        onlyMetakit
        returns (bool)
    {
        _transfer(playerAddress, address(this), amount);
        return true;
    }

    modifier onlyMetakit() {
        require(msg.sender == adminAddress, 'Only MetaKit Service can call.');
        _; // Otherwise, it continues.
    }

    function changeAdmin(address newAdmin) public {
        require(
            (msg.sender == owner ),
            'Only Owner can change this address'
        );
        adminAddress = newAdmin;
    }
}
