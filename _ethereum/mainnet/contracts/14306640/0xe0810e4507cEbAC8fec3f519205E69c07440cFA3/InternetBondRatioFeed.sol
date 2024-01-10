// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "./OwnableUpgradeable.sol";
import "./IInternetBondRatioFeed.sol";

contract InternetBondRatioFeed is OwnableUpgradeable, IInternetBondRatioFeed {

    event OperatorAdded(address operator);
    event OperatorRemoved(address operator);

    mapping(address => bool) _isOperator;
    mapping(address => uint256) private _ratios;

    function initialize(address operator) public initializer {
        __Ownable_init();
        _isOperator[operator] = true;
    }

    function updateRatioBatch(address[] calldata addresses, uint256[] calldata ratios) public override onlyOperator {
        require(addresses.length == ratios.length, "corrupted ratio data");
        for (uint256 i = 0; i < addresses.length; i++) {
            _ratios[addresses[i]] = ratios[i];
        }
    }

    function getRatioFor(address token) public view override returns (uint256) {
        return _ratios[token];
    }

    function addOperator(address operator) public onlyOwner {
        require(operator != address(0x0), "operator must be non-zero");
        require(!_isOperator[operator], "already operator");
        _isOperator[operator] = true;
        emit OperatorAdded(operator);
    }

    function removeOperator(address operator) public onlyOwner {
        require(_isOperator[operator], "not an operator");
        delete _isOperator[operator];
        emit OperatorRemoved(operator);
    }

    modifier onlyOperator() {
        require(msg.sender == owner() || _isOperator[msg.sender], "Operator: not allowed");
        _;
    }
}