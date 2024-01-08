// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "./IHotPotV3FundFactory.sol";
import "./IHotPotV3FundController.sol";
import "./HotPotV3FundDeployer.sol";

/// @title The interface for the HotPotFunds V3 Factory
/// @notice The HotPotV3Funds Factory facilitates creation of HotPot V3 fund
contract HotPotV3FundFactory is IHotPotV3FundFactory, HotPotV3FundDeployer {
    /// @inheritdoc IHotPotV3FundFactory
    address public override immutable WETH9;
    /// @inheritdoc IHotPotV3FundFactory
    address public override immutable uniV3Factory;
    /// @inheritdoc IHotPotV3FundFactory
    address public override immutable uniV3Router;
    /// @inheritdoc IHotPotV3FundFactory
    address public override immutable controller;
    mapping(bytes32 => address) private _fund;

    constructor(
        address _controller, 
        address _weth9,
        address _uniV3Factory, 
        address _uniV3Router
    ){
        require(_controller != address(0));
        require(_weth9 != address(0));
        require(_uniV3Factory != address(0));
        require(_uniV3Router != address(0));

        controller = _controller;
        WETH9 = _weth9;
        uniV3Factory = _uniV3Factory;
        uniV3Router = _uniV3Router;
    }

    /// @inheritdoc IHotPotV3FundFactory
    function getFund(address manager, address token, uint lockPeriod, uint baseLine, uint managerFee) external view override returns (address fund){
        return _fund[keccak256(abi.encode(manager, token, lockPeriod, baseLine, managerFee))];
    }
    
    /// @inheritdoc IHotPotV3FundFactory
    function createFund(address token, bytes calldata descriptor, uint lockPeriod, uint baseLine, uint managerFee) external override returns (address fund){
        bytes32 fundKey = keccak256(abi.encode(msg.sender, token, lockPeriod, baseLine, managerFee));
        require(IHotPotV3FundController(controller).verifiedToken(token));
        require(_fund[fundKey] == address(0));
        require(lockPeriod <= 1095 days);
        require(managerFee <= 45);

        fund = deploy(WETH9, uniV3Factory, uniV3Router, controller, msg.sender, token, descriptor, lockPeriod, baseLine, managerFee);
        _fund[fundKey] = fund;

        emit FundCreated(msg.sender, token, fund);
    }
}