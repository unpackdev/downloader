//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract VestingDispenser is Ownable {
    using SafeERC20 for IERC20;

    struct UserInfo {
      uint start;
      uint length;
      uint total;
      uint claimed;
    }

    IERC20 public token;
    mapping(address => UserInfo) public info;

    event Deposit(address user, uint start, uint length, uint total);
    event UpdateAddress(address oldAddress, address newAddress);
    event RemoveAddress(address user);
    event Claim(address user, uint amount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function updateAddress(address oldAddress, address newAddress) external onlyOwner {
        require(info[oldAddress].start > 0, "not a user");
        info[newAddress] = info[oldAddress];
        delete info[oldAddress];
        emit UpdateAddress(oldAddress, newAddress);
    }

    function removeAddress(address user) external onlyOwner {
        require(info[user].start > 0, "not a user");
        delete info[user];
        emit RemoveAddress(user);
    }

    function withdrawToken(address token, uint amount) public onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function deposit(address user, uint start, uint length, uint total) public onlyOwner {
        require(info[user].start == 0, "user exists"); 
        info[user].start = start;
        info[user].length = length;
        info[user].total = total;
        if (start == 0) {
            info[user].start = block.timestamp;
        }
        emit Deposit(user, start, length, total);
    }
    
    function claimable(address user) public view returns (uint) {
        UserInfo memory userInfo = info[user];
        if (userInfo.start == 0) {
          return 0;
        }

        uint percentVested = ((block.timestamp - userInfo.start) * 1e12) / userInfo.length;
        if (percentVested > 1e12) {
            percentVested = 1e12;
        }
        uint amount = userInfo.total * percentVested / 1e12;
        if (amount < userInfo.claimed) {
          return 0;
        }
        return amount - userInfo.claimed;
    }

    function claim() public {
        uint amount = claimable(msg.sender);
        require(amount > 0, "nothing to claim");
        info[msg.sender].claimed += amount;
        token.safeTransfer(msg.sender, amount);
        emit Claim(msg.sender, amount);
    }
}
