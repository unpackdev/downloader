// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./IAntfarmToken.sol";

/// @title Antfarm Burner
/// @notice Anyone can trigger a burn of the ATF balance of this contract.
contract AntfarmBurner {
    address public immutable antfarmToken;

    constructor(address _antfarmToken) {
        antfarmToken = _antfarmToken;
    }

    function burn() external {
        IAntfarmToken atfContract = IAntfarmToken(antfarmToken);
        atfContract.burn(atfContract.balanceOf(address(this)));
    }
}
