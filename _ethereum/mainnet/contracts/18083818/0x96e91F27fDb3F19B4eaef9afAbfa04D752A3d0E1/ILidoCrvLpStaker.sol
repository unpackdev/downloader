// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IStaker {
    function deposit_and_stake(
        address deposit,
        address lp_token,
        address gauge,
        uint256 n_coints,
        address[5] calldata coins,
        uint256[5] calldata amounts,
        uint256 min_mint_amount,
        bool use_underlying,
        address pool
    ) external payable;
}

interface IStEthGauge {
    function set_approve_deposit(address addr, bool can_deposit) external;
}
