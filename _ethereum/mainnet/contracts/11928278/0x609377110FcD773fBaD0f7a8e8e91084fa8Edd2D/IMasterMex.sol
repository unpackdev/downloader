// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

abstract contract IMasterMex is Ownable, ReentrancyGuard {
    enum GroupType { Up, Down }

    struct UserInfo {
        uint256 amount;                 // Deposit amount of user
        uint256 profitDebt;             // Profit Debt amount of user
        uint256 lossDebt;               // Loss Debt amount of user
        GroupType voteGroup;            // Group where the user bets
    }

    struct GroupInfo {
        uint256 deposit;                // Deposited ETH amount into the group
        uint256 holding;                // Currently holding ETH amount
        uint256 shareProfitPerETH;
        uint256 shareLossPerETH;
    }

    struct PoolInfo {
        address tokenPair;
        uint256 prevReserved;
        uint256 maxChangeRatio;
        uint256 minFund;
    }

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public decimals = 12;
    address payable STAKING_VAULT;
    address payable TREASURY_VAULT;
    address payable BUYBACK_VAULT;
    uint256 public STAKING_FEE;
    uint256 public TREASURY_FEE;
    uint256 public BUYBACK_FEE;

    PoolInfo[] public poolInfo;
    mapping(address => UserInfo) public pendingUserInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => mapping(GroupType => GroupInfo)) public groupInfo;
}