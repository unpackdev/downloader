// SPDX-License-Identifier: MIT

// V1 Revenue Share Disribution Contract

// Website: https://friendsniper.tech
// Telegram: https://t.me/FrenSnipe
// Twitter: https://twitter.com/FriendSniperTch
// Email: frensniper@proton.me

pragma solidity >=0.8.10 >=0.8.0 <0.9.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./Context.sol";

contract FriendSniperRevShareDistributorV1 is Ownable {
    using SafeERC20 for IERC20;
    mapping(uint8 => mapping(address => bool)) public hasBeenDistributed;
    mapping(uint8 => uint256) public ethDistributed;
    uint8 public epoch;

    constructor(uint8 _epoch) {
        epoch = _epoch;
    }

    event DisributedRev(address[] user, uint256[] amounts);

    receive() external payable {}

    function DistributeRevenueShare(
        address[] memory users,
        uint256[] memory amounts
    ) public onlyOwner {
        require(
            users.length == amounts.length,
            "Users and amounts arrays should must have the same length"
        );

        for (uint256 i = 0; i < users.length; ++i) {
            if (hasBeenDistributed[epoch][users[i]]) {
                continue;
            }
            hasBeenDistributed[epoch][users[i]] = true;
            (bool success, ) = users[i].call{value: amounts[i]}("");
            require(success, "Transfer failed");
        }
        emit DisributedRev(users, amounts);
    }

    function RecoverToken(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(0), "Invalid address");
        require(_amount > 0, "Invalid amount");

        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    function Withdraw(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Invalid amount");
        require(_amount <= address(this).balance, "Insufficient balance");
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");
    }

    function NextEpoch() external onlyOwner {
        epoch++;
    }
}
