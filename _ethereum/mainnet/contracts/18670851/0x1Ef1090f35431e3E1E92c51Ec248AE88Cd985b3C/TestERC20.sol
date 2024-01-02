// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./ERC20.sol";

/**
 * @notice A mintable ERC20. Used for testing.
 */
contract TestERC20 is ERC20 {
    uint8 decimalsToUse;

    constructor(
        uint256 _totalSupply,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
        decimalsToUse = _decimals;
    }

    function decimals() public view virtual override returns (uint8) {
        return decimalsToUse;
    }

    function mintTo(address receiver, uint256 _amount) public {
        _mint(receiver, _amount);
    }
}
