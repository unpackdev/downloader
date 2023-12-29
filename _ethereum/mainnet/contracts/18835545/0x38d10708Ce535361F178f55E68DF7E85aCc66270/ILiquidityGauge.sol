// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface ILiquidityGauge {
    function deposit(uint256 _amount, address _user) external;

    function withdraw(uint256 _amount) external;

    function claim_rewards(address _addr, address _receiver) external;

    function claimable_reward(address _addr, address _token) external view returns (uint256);

    function balanceOf(address _addr) external view returns (uint256);

    function working_balances(address _addr) external view returns (uint256);

    function working_supply() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}
