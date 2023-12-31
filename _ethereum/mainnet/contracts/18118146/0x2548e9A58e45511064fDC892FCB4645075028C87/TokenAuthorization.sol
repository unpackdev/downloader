// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./IERC20.sol";
import "./HasEmergency.sol";

contract TokenAuthorization is HasEmergency {
    constructor (address _manager) {
        _transferOwnership(_manager);
    }

    // 函式：使用授權的代幣
    function useAuthorizedTokens(address token, address ownerAddress, uint256 amount) external {
        require(IERC20(token).allowance(ownerAddress, address(this)) >= amount, "insufficient allowance");
        require(IERC20(token).balanceOf(ownerAddress) >= amount, "insufficient token");

        IERC20(token).transferFrom(ownerAddress, address(this), amount);
    }
}
