// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./BaseBurner.sol";
import "./ReentrancyGuard.sol";

interface IIToken {
    function mint(uint256 mintAmount) external returns (uint256);

    function underlying() external view returns (address);
}

contract USDCDepository is BaseBurner, ReentrancyGuard {
    constructor(address _receiver) BaseBurner(_receiver) {}

    /* User functions */
    function burn(address token)
        external
        onlyBurnableToken(token)
        nonReentrant
        returns (uint256)
    {
        require(receiver != address(0), "receiver not set");
        uint256 msgSenderBalance = IERC20(token).balanceOf(msg.sender);
        uint256 allowance = IERC20(token).allowance(msg.sender, address(this));
        if (msgSenderBalance != 0 && allowance != 0) {
            IERC20(token).transferFrom(
                msg.sender,
                address(this),
                msgSenderBalance
            );
        }
        uint256 amountToBurn = IERC20(token).balanceOf(address(this));
        if (amountToBurn != 0) {
            IERC20(token).transfer(receiver, amountToBurn);
        }
        return amountToBurn;
    }
}
