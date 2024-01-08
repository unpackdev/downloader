// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract RewardKeeper is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(address => bool) private _actionAddresses;

    event AddToActionList(address indexed actionAddress);
    event RemoveFromActionList(address indexed actionAddress);

    event RewardSent(address erc20TokenAddress, address indexed recipient, uint256 amount, address indexed actionAddress);

    constructor () {}

    function isActionAddress(address actionAddress_) external view returns (bool) {
        return _actionAddresses[actionAddress_];
    }

    function sendReward(address erc20TokenAddress_, address recipient_, uint256 amount_) external nonReentrant returns (bool) {
        require(_actionAddresses[_msgSender()], "RewardKeeper: msgSender has no permissions");
        IERC20 erc20Token = IERC20(erc20TokenAddress_);
        erc20Token.safeTransfer(recipient_, amount_);
        emit RewardSent(erc20TokenAddress_, recipient_, amount_, _msgSender());
        return true;
    }

    function addToActionList(address actionAddress_) external onlyOwner {
        _actionAddresses[actionAddress_] = true;
        emit AddToActionList(actionAddress_);
    }

    function removeFromActionList(address actionAddress_) external onlyOwner {
        _actionAddresses[actionAddress_] = false;
        emit RemoveFromActionList(actionAddress_);
    }

    function withdrawAnyErc20(address erc20TokenAddress_, address recipient_, uint256 amount_) external nonReentrant onlyOwner returns (bool)
    {
        IERC20 erc20Token = IERC20(erc20TokenAddress_);
        erc20Token.safeTransfer(recipient_, amount_);
        return true;
    }
}
