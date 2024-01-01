// commit 427ad29973083a8d6910314bbe8eb781e9c80166
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.19;

import "FarmingBaseACL.sol";
import "IStargateFactory.sol";
import "StargateAddressUtils.sol";

contract StargateDepositETHAuthorizer is FarmingBaseACL {
    bytes32 public constant NAME = "StargateDepositETHAuthorizer";
    uint256 public constant VERSION = 1;

    address public immutable router;
    address public immutable stakingPool;

    constructor(address _owner, address _caller) FarmingBaseACL(_owner, _caller) {
        (stakingPool, , ) = getAddresses();
        router = getRouterETHAddresses();
    }

    function addLiquidityETH() external view onlyContract(router) {
    }

    function deposit(
        uint256 _pid,
        uint256 //amount
    ) public view onlyContract(stakingPool) {
        _checkAllowPoolId(_pid);
    }

    function contracts() public view override returns (address[] memory _contracts) {
        _contracts = new address[](2);
        _contracts[0] = router;
        _contracts[1] = stakingPool;
    }
}