// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;
import "./DefinitiveAssets.sol";

interface IConvexDepositToken {
    function balanceOf(address _account) external view returns (uint256);

    function claimReward(
        address receiver
    ) external returns (uint256 prismaAmount, uint256 crvAmount, uint256 cvxAmount);

    function claimableReward(
        address account
    ) external view returns (uint256 prismaAmount, uint256 crvAmount, uint256 cvxAmount);

    function deposit(address receiver, uint256 amount) external returns (bool);

    function withdraw(address receiver, uint256 amount) external returns (bool);
}

// https://etherscan.io/address/0xF403C135812408BFbE8713b5A23a04b3D48AAE31#contracts
interface IBooster {
    //deposit into convex, receive a tokenized deposit.  parameter to stake immediately
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns (bool);

    //deposit all lp tokens and stake
    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    //burn a tokenized deposit to receive curve lp tokens back
    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    //withdraw all lp tokens
    function withdrawAll(uint256 _pid) external returns (bool);
}

// https://etherscan.io/address/0x9D5C5E364D81DaB193b72db9E9BE9D8ee669B652#code
interface IBaseRewardPool {
    //get balance of an address
    function balanceOf(address _account) external view returns (uint256);

    //withdraw to a convex tokenized deposit
    function withdraw(uint256 _amount, bool _claim) external returns (bool);

    //withdraw all
    function withdrawAll(bool _claim) external returns (bool);

    //withdraw directly to curve LP token, if bool false will not claim reward
    function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns (bool);

    //withdraw all to curve LP token
    function withdrawAllAndUnwrap(bool _claim) external returns (bool);

    //claim rewards
    function getReward() external returns (bool);

    //stake a convex tokenized deposit
    function stake(uint256 _amount) external returns (bool);

    //stake a convex tokenized deposit for another address(transferring ownership)
    function stakeFor(address _account, uint256 _amount) external returns (bool);

    //get accumulated reward shares count
    function earned(address account) external view returns (uint256);

    //getter for base reward token
    function rewardToken() external view returns (IERC20);

    //getter for extra rewards array length
    function extraRewardsLength() external view returns (uint256);

    //getter for extra reward tokens
    function extraRewards(uint256 index) external view returns (address);
}

// https://etherscan.io/address/0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B#code
interface IConvexToken {
    function maxSupply() external view returns (uint256);

    function totalCliffs() external view returns (uint256);

    function reductionPerCliff() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}
