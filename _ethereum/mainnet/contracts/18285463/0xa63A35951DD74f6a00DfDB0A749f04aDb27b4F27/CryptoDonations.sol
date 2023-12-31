// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./SafeERC20.sol";
import "./Ownable.sol";

contract CryptoDonations is Ownable {
    using SafeERC20 for IERC20;
    uint256 public fee = 0; // scale 1e18
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event Donation(
        address indexed donator,
        address indexed recipient, 
        address token, 
        uint256 amount, 
        string tag,
        string memo
    );

    event FeeChanged(uint256 fee);

    function donate(
        address recipient, 
        address token, 
        uint256 amount, 
        string calldata tag,
        string calldata memo
    ) external payable {
        if (token == ETH) {
            require(msg.value == amount, "CryptoDonations: ETH amount mismatch");
            if (fee > 0) {
                uint256 feeAmount = amount * fee / 1e18;
                payable(owner()).transfer(feeAmount);
                amount -= feeAmount;
            }
            payable(recipient).transfer(amount);
        } else {
            if (fee > 0) {
                uint256 feeAmount = amount * fee / 1e18;
                IERC20(token).safeTransferFrom(msg.sender, owner(), feeAmount);
                amount -= feeAmount;
            }
            IERC20(token).safeTransferFrom(msg.sender, recipient, amount);
        }
        emit Donation(msg.sender, recipient, token, amount, tag, memo);
    }

    // config fee
    function setFee(uint256 _fee) external onlyOwner {
        require(_fee <= 5e16, "CryptoDonations: fee must be <= 5%");
        fee = _fee;
        emit FeeChanged(_fee);
    }
}
