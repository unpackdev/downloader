// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "./ERC20Upgradeable.sol";

contract MochiInu is ERC20Upgradeable {

    address public control;

    address public inflationDestination;

    uint256 public nextMint;

    function initialize(address _control, address _recipient, address _inflationDestination) external initializer {
        __ERC20_init("Mochi Inu", "MOCHI");
        control = _control;
        _mint(_recipient, 1000000000000000e18);
        nextMint = block.timestamp + 365*3 days;
        inflationDestination = _inflationDestination;
    }

    function transferControl(address _newControl) external {
        require(msg.sender == control, "!control");
        control = _newControl;
    }

    function changeInflationDestination(address _newDestination) external {
        require(msg.sender == control, "!control");
        inflationDestination = _newDestination;
    }

    function mint() external {
        require(block.timestamp > nextMint, "!nextmint");
        require(msg.sender == control, "!control");
        uint256 amount = totalSupply() / 100;
        _mint(inflationDestination, amount);
        nextMint += 365 days;
    }
}
