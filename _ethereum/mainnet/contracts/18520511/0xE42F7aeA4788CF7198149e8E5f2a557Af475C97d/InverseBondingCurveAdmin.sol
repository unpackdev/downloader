// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.18;

import "./Ownable2Step.sol";
import "./Pausable.sol";
import "./Constants.sol";
import "./Enums.sol";

import "./InverseBondingCurveFactory.sol";
import "./InverseBondingCurve.sol";

contract InverseBondingCurveAdmin is Ownable2Step, Pausable {
    address private _weth;

    address private _router;
    address private _factory;
    address private _curveImplementation;
    address private _protocolFeeOwner;

    uint256[MAX_ACTION_COUNT] private _lpFeePercent = [LP_FEE_PERCENT, LP_FEE_PERCENT, LP_FEE_PERCENT, LP_FEE_PERCENT];
    uint256[MAX_ACTION_COUNT] private _stakingFeePercent =
        [STAKE_FEE_PERCENT, STAKE_FEE_PERCENT, STAKE_FEE_PERCENT, STAKE_FEE_PERCENT];
    uint256[MAX_ACTION_COUNT] private _protocolFeePercent =
        [PROTOCOL_FEE_PERCENT, PROTOCOL_FEE_PERCENT, PROTOCOL_FEE_PERCENT, PROTOCOL_FEE_PERCENT];

    /**
     * @notice  Emitted when protocol fee owner changed
     * @dev
     * @param   feeOwner : New fee owner of protocol fee
     */
    event FeeOwnerChanged(address feeOwner);

    /**
     * @notice  Emitted when router changed
     * @dev
     * @param   router : New router address
     */
    event RouterChanged(address router);

    /**
     * @notice  Emitted when curve implementation changed
     * @dev
     * @param   implementation : New curve implementation
     */
    event CurveImplementationChanged(address implementation);

    /**
     * @notice  Emmitted when fee configuration changed
     * @dev
     * @param   actionType : The action type of the changed fee configuration. (Buy/Sell/Add liquidity/Remove liquidity)
     * @param   lpFee : Fee reward percent for LP
     * @param   stakingFee : Fee reward percent for Staker
     * @param   protocolFee : Fee reward percent for Protocol
     */
    event FeeConfigChanged(ActionType actionType, uint256 lpFee, uint256 stakingFee, uint256 protocolFee);

    /**
     * @notice  Constructor of Admin contract
     * @dev
     * @param   wethAddress : WrapETH contract address
     * @param   routerAddress : Router contract address which handle the native asset wrap/unwrap
     * @param   protocolFeeOwner : Protocol fee owner address
     */
    constructor(address wethAddress, address routerAddress, address protocolFeeOwner) Ownable2Step() {
        if (wethAddress == address(0) || routerAddress == address(0) || protocolFeeOwner == address(0)) revert EmptyAddress();
        _weth = wethAddress;
        _router = routerAddress;
        _protocolFeeOwner = protocolFeeOwner;

        _curveImplementation = address(new InverseBondingCurve());

        _createFactory();
    }

    /**
     * @notice  Pause all curve contract
     * @dev     
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice  Unpause all curve contract
     * @dev     
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice  Update fee config
     * @dev
     * @param   actionType : Fee configuration for : Buy/Sell/Add liquidity/Remove liquidity)
     * @param   lpFee : The percent of fee reward to LP
     * @param   stakingFee : The percent of fee reward to staker
     * @param   protocolFee : The percent of fee reward to protocol
     */
    function updateFeeConfig(ActionType actionType, uint256 lpFee, uint256 stakingFee, uint256 protocolFee) external onlyOwner {
        if ((lpFee + stakingFee + protocolFee) >= MAX_FEE_PERCENT) revert FeePercentOutOfRange();
        if (uint256(actionType) >= MAX_ACTION_COUNT) revert InvalidInput();

        _lpFeePercent[uint256(actionType)] = lpFee;
        _stakingFeePercent[uint256(actionType)] = stakingFee;
        _protocolFeePercent[uint256(actionType)] = protocolFee;

        emit FeeConfigChanged(actionType, lpFee, stakingFee, protocolFee);
    }

    /**
     * @notice  Update protocol fee owner
     * @dev
     * @param   protocolFeeOwner : The new owner of protocol fee
     */
    function updateFeeOwner(address protocolFeeOwner) external onlyOwner {
        if (protocolFeeOwner == address(0)) revert EmptyAddress();

        _protocolFeeOwner = protocolFeeOwner;

        emit FeeOwnerChanged(protocolFeeOwner);
    }

    /**
     * @notice  Update router contract address
     * @dev
     * @param   routerAddress : Router contract address
     */
    function updateRouter(address routerAddress) external onlyOwner {
        if (routerAddress == address(0)) revert EmptyAddress();

        _router = routerAddress;

        emit RouterChanged(routerAddress);
    }

    /**
     * @notice  Upgrade curve implementation contract
     * @dev     .
     * @param   implementation : New curve contract implementation
     */
    function upgradeCurveTo(address implementation) external onlyOwner {
        if (implementation == address(0)) revert EmptyAddress();
        _curveImplementation = implementation;

        emit CurveImplementationChanged(implementation);
    }

    /**
     * @notice  Query fee configuration
     * @dev     Each fee config array contains configuration for four actions(Buy/Sell/Add liquidity/Remove liquidity)
     * @return  lpFee : The percent of fee reward to LP
     * @return  stakingFee : The percent of fee reward to staker
     * @return  protocolFee : The percent of fee reward to protocol
     */
    function feeConfig(ActionType actionType) external view returns (uint256 lpFee, uint256 stakingFee, uint256 protocolFee) {
        lpFee = _lpFeePercent[uint256(actionType)];
        stakingFee = _stakingFeePercent[uint256(actionType)];
        protocolFee = _protocolFeePercent[uint256(actionType)];
    }
    
    /**
     * @notice  Get factory contract address
     * @dev
     * @return  address : Factory contract address
     */
    function factoryAddress() external view returns (address) {
        return _factory;
    }

    /**
     * @notice  Query protocol fee owner
     * @dev
     * @return  address : protocol fee owner
     */
    function feeOwner() external view returns (address) {
        return _protocolFeeOwner;
    }

    /**
     * @notice  Wrap eth contract address
     * @dev
     * @return  address : Wrap eth contract address
     */
    function weth() external view returns (address) {
        return _weth;
    }

    /**
     * @notice  Query router contract address
     * @dev
     * @return  address : router contract address
     */
    function router() external view returns (address) {
        return _router;
    }

    /**
     * @notice  Get curve implementation
     * @dev
     * @return  address : curve implementation contract
     */
    function curveImplementation() external view returns (address) {
        return _curveImplementation;
    }

    /**
     * @notice  Create curve factory
     * @dev
     */
    function _createFactory() private {
        _factory = address(new InverseBondingCurveFactory(address(this)));
    }
}
