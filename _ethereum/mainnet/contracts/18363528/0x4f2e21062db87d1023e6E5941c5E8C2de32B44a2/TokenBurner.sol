// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IBeamToken.sol";

contract TokenBurner {

    IBeamToken public immutable token;

    event Burn(address indexed burner, uint256 amount);

    constructor(address _token) {
        require(_token != address(0), "Token cannot be zero address");
        token = IBeamToken(_token);
    }

    function burn() external {
        uint256 burnAmount = token.balanceOf(address(this));
        token.burn(address(this), burnAmount);
        emit Burn(msg.sender, burnAmount);
    }

}
