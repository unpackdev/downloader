/// Good mornin'
/// Look at the valedictorian
/// Scared of the future while I hop in the DeLorean

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "./Clones.sol";
import "./Hyperobject.sol";
import "./Exchange.sol";
import "./BondingCurve.sol";

/// @title Pair Factory
/// @author neuroswish
/// @notice Factory to deploy pairs of hyperobject and exchange clones

contract PairFactory {

    // ======== Storage ========

    address public immutable hyperobjectLogic; // Hyperobject logic contract
    address public immutable exchangeLogic; // Exchange logic contract
    address public immutable bondingCurve; // Bonding curve logic contract

    // ======== Errors ========

	/// @notice Thrown when transaction share percentage is invalid
	error InvalidPercentage();

	/// @notice Thrown when reserve ratio is invalid
	error InvalidReserveRatio();

    // ======== Events ========

    /// @notice Emitted when a pair is created
	/// @param exchangeAddress Exchange logic address
    /// @param hyperobjectAddress Hyperobject logic address
    /// @param name Pair name
    /// @param symbol Pair symbol
    /// @param creator Pair creator
    event PairCreated(
        address exchangeAddress,
        address hyperobjectAddress,
        string name,
        string symbol,
        address creator
    );

    // ======== Constructor ========

    /// @notice Set bonding curve address
    /// @param _bondingCurve Bonding curve address
    constructor(address _bondingCurve) {
        bondingCurve = _bondingCurve;
        Exchange exchangeLogic_ = new Exchange(address(this), _bondingCurve);
        Hyperobject hyperobjectLogic_ = new Hyperobject(address(this));
        exchangeLogic = address(exchangeLogic_);
        hyperobjectLogic = address(hyperobjectLogic_);
        exchangeLogic_.initialize("Verse", "VERSE", 242424, 724223089680545, 0, hyperobjectLogic, address(this));
        hyperobjectLogic_.initialize("Verse", "VERSE", "verse.xyz", exchangeLogic);
    }

    // ======== Create Hyperobject Clone ========

    /// @notice Deploy a new Pair
    /// @param _name Pair name
    /// @param _symbol Pair symbol
    /// @param _reserveRatio Reserve ratio
    /// @param _slopeInit Initial slope value to determine price curve
    /// @param _transactionShare Transaction share
    /// @param _baseURI Hyperobject base URI
    /// @dev Emits a PairCreated event upon success; callable by anyone
    function create(
        string calldata _name,
        string calldata _symbol,
        uint256 _reserveRatio,
        uint256 _slopeInit,
        uint256 _transactionShare,
        string calldata _baseURI
    ) external returns (address exchange, address hyperobject) {
        if (_transactionShare > 10000) revert InvalidPercentage();
        if (_reserveRatio > 1000000) revert InvalidReserveRatio();
        exchange = Clones.clone(exchangeLogic);
        hyperobject = Clones.clone(hyperobjectLogic);
        Exchange(exchange).initialize(_name, _symbol, _reserveRatio, _slopeInit, _transactionShare, hyperobject, msg.sender);
        Hyperobject(hyperobject).initialize(_name, _symbol, _baseURI, exchange);
        emit PairCreated(exchange, hyperobject, _name, _symbol, msg.sender);
    }
}