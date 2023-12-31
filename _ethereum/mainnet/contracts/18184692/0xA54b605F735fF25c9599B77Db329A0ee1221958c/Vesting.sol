// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Ownable.sol";

contract Vesting is Ownable {

    struct UserInfo {
        address user;
        uint256 totalValue;
        uint256 claimedValue;
    }

    struct UserInfoPayload {
        address user;
        uint256 totalValue;
    }

    uint256 constant public VESTING_PERIOD = 90 days;
    uint256 constant public VESTING_AMOUNT = 650_000_000 ether;

    IERC20 private DOMINI;

    uint256 public vestingStartTimestamp;

    mapping(address => UserInfo) public userInfo;

    event Claim(address account, uint256 value);

    function setDominiToken(IERC20 domini) external onlyOwner {
        DOMINI = domini;
    }

    function whitelistUsers(UserInfoPayload[] memory users) external onlyOwner {
        uint256 length = users.length;

        for (uint256 i; i < length;) {
            userInfo[users[i].user] =  UserInfo(users[i].user, users[i].totalValue, 0);
            unchecked {
                i++;
            }
        }
    }

    function startVesting() external onlyOwner {
        vestingStartTimestamp = block.timestamp;
    }

    function claim() external {
        require(vestingStartTimestamp != 0, "[claim]: vesting is not started");

        address sender = msg.sender;
        require(userInfo[sender].totalValue > 0, "[claim]: user is not whitelisted");

        uint256 passedTime = block.timestamp - vestingStartTimestamp >= VESTING_PERIOD ? VESTING_PERIOD : block.timestamp - vestingStartTimestamp;

        uint256 valueToClaim = userInfo[sender].totalValue * passedTime / VESTING_PERIOD - userInfo[sender].claimedValue;

        DOMINI.transfer(sender, valueToClaim);
        userInfo[sender].claimedValue += valueToClaim;

        emit Claim(sender, valueToClaim);
    }

}