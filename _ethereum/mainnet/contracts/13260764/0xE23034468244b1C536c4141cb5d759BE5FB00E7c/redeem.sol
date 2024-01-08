// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

interface IRedeemPool {
    event RedeemStart(address indexed starter, uint256 reward);
    event DepositBond(address indexed owner, uint256 amount);
    event RewardClaimed(address indexed owner, uint256 amount);
    event ReCharge(
        address indexed owner,
        address indexed token,
        uint256 indexed rid,
        uint256 amount
    );
    event ReChargeETH(
        address indexed owner,
        uint256 indexed rid,
        uint256 amount
    );
    event Withdrawal(
        address indexed from,
        address indexed to,
        uint256 indexed at
    );

    function rechargeCash(uint256 _rid, uint256 _amount) external;
    function cashToClaim() external view returns (uint256); 
}