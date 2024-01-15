//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IStrategy {
    function _claimRewards(address _treasury) external;

    function approveStrategy(bool _approved) external;

    function deposit(uint256 _amount) external;

    function depositFor(address _caller, uint256 _amount) external;

    function withdrawAll() external;

    function withdraw(uint256 _amount) external;

    function withdrawTo(address _recipient, uint256 _amount) external;

    function name() external view returns (string memory);

    function isLSRStrategy() external view returns (bool);

    function mpr() external view returns (address);

    function liquidityModel() external view returns (address);

    function totalDeposits() external returns (uint256);

    function liquidity() external returns (uint256);

    function rewardsEarned() external returns (uint256);

    function limitOfDeposit() external returns (uint256);

    function depositStatus() external returns (bool);

    function withdrawStatus() external returns (bool);

    // function getMiningReward() external;

    // function getProfitAmount() external returns (uint256);

    // function mprQuota() external view returns (uint256);

    // function mprOutstanding() external returns (uint256 _availableQuota);
}
