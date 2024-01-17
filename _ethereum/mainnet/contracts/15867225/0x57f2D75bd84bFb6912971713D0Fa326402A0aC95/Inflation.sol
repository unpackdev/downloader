// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./Address.sol";
import "./IERC20.sol";

import "./IMint.sol";
import "./IReceiver.sol";

contract Inflation is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    address public immutable token;

    uint256 public totalMinted;
    uint256 public immutable targetMinted;
    uint256 public immutable periodicEmission;
    uint256 public immutable startInflationTime;
    uint256 public lastTs;
    
    uint256 public immutable periodDuration; // seconds

    mapping(address => uint256) public weights; // in points relative to sumWeight
    mapping(address => uint256) public available; 
    mapping(address => uint256) public claimed; 

    uint256 public toDistribute;

    uint256 public constant sumWeight = 10000;

    EnumerableSet.AddressSet internal receivers;

    event ReceiverAdded(address receiver, uint256 weight, uint256[] oldWeights);
    event ReceiverRemoved(address receiver, uint256[] newWeights);
    event Reconfigured(uint256[] newWeights);
    event TokenClaimed(address receiver);

    // """
    // @notice Contract constructor
    // @param _name Token full name
    // @param _symbol Token symbol
    // @param _decimals Number of decimals for token
    // @param _targetMinted max amount minted during
    // """
    constructor(
        address _token,
        uint256 _targetMinted,
        uint256 _periodsCount,
        uint256 _periodDuration
    ) {
        token = _token;
        targetMinted = _targetMinted;
        periodicEmission = _targetMinted / _periodsCount;
        periodDuration = _periodDuration;
        require(periodDuration > 0, "periodDuration=0");
        startInflationTime = block.timestamp;
    }

    // """
    // @notice Current number of tokens in existence (claimed or unclaimed)
    // """
    function availableSupply() external view returns (uint256) {
        return totalMinted;
    }

    function addReceiver(
        address _newReceiver, 
        uint256 _weightForNew, 
        bool _callConfigureForNew,
        uint256[] memory _weightsForOld,
        bool[] memory _callConfigureForOld
    )
        external
        onlyOwner
    {
        require(_weightsForOld.length == _callConfigureForOld.length && _weightsForOld.length == receivers.length(), "lengths !equal");
        require(_weightForNew > 0, "incorrect weight");
        _mint();
        require(!receivers.contains(_newReceiver), "already added");
        uint256 sum = _reconfigure(_weightsForOld, _callConfigureForOld);
        sum += _weightForNew;
        require(sum == 10000, "incorrect sum");
        receivers.add(_newReceiver);
        weights[_newReceiver] = _weightForNew;
        if (_newReceiver.isContract() && _callConfigureForNew) IReceiver(_newReceiver).configure();
        emit ReceiverAdded(_newReceiver, _weightForNew, _weightsForOld);
    }

    function reconfigureReceivers(
        uint256[] memory _weights,
        bool[] memory _callConfigureForNew
    ) onlyOwner external {
        _mint();
        require(_weights.length == _callConfigureForNew.length && _weights.length == receivers.length(), "lengths !equal");
        uint256 sum = _reconfigure(_weights, _callConfigureForNew);
        require(sum == 10000, "incorrect sum");
        emit Reconfigured(_weights);
    }

    function removeReceiver(
        address _receiver, 
        bool _callConfigure, 
        uint256[] memory _newWeights, 
        bool[] memory _newCallConfigure
    ) onlyOwner external {
        require(_newWeights.length == _newCallConfigure.length && _newWeights.length == receivers.length() - 1, "lengths !equal");
        _mint();
        uint256 amountToDistribute = toDistribute;
        for (uint256 i; i < receivers.length(); i++) {
            address receiver = receivers.at(i);
            available[receiver] = amountToDistribute * weights[receiver] / sumWeight + available[receiver];
        }
        toDistribute = 0;
        receivers.remove(_receiver);
        delete weights[_receiver];
        uint256 sum = _reconfigure(_newWeights, _newCallConfigure);
        if (_receiver.isContract() && _callConfigure) IReceiver(_receiver).configure();
        require(sum == 10000, "incorrect sum");
        emit ReceiverRemoved(_receiver, _newWeights);
    }

    function _reconfigure(
        uint256[] memory _weights, 
        bool[] memory _callConfigureForNew
    ) internal returns(uint256){
        uint256 sum;
        uint256 _amountToDistribute = toDistribute;
        for (uint256 i; i < _weights.length; i++) {
            require(_weights[i] > 0, "incorrect weight");
            sum += _weights[i];
            address receiver = receivers.at(i);
            available[receiver] = _amountToDistribute * weights[receiver] / sumWeight + available[receiver] - claimed[receiver];
            claimed[receiver] = 0;
            weights[receiver] = _weights[i];
            if (receiver.isContract() && _callConfigureForNew[i]) IReceiver(receiver).configure();
        }
        
        toDistribute = 0;
        return sum;
    }

    function getToken(address _account) external {
        _mint();
        _getToken(_account, IERC20(token));
    }

    function getToken(address[] memory _accounts) external {
        _mint();
        IERC20 token_ = IERC20(token);
        for (uint256 i; i < _accounts.length; i++) {
            _getToken(_accounts[i], token_);
        }
    }

    function getToken() external {
        _mint();
        IERC20 token_ = IERC20(token);
        for (uint256 i; i < receivers.length(); i++) {
            _getToken(receivers.at(i), token_);
        }
    }

    function _getToken(address _account, IERC20 _token) internal {
        uint256 toDistributeMember = toDistribute * weights[_account] / sumWeight;
        uint256 pendingReward = toDistributeMember + available[_account] - claimed[_account];
        claimed[_account] += toDistributeMember - claimed[_account];
        available[_account] = 0;
        if (pendingReward > 0) {
            _safeTransfer(_account, pendingReward);
            emit TokenClaimed(_account);
        }
    }

    function receiversCount() external view returns (uint256) {
        return receivers.length();
    }

    function receiverAt(uint256 index) external view returns (address) {
        return receivers.at(index);
    }

    function getAllReceivers() external view returns (address[] memory) {
        uint256 length = receivers.length();
        address[] memory receivers_ = new address[](length);
        for (uint256 i; i < length; i++) {
            receivers_[i] = receivers.at(i);
        }
        return receivers_;
    }

    function _getPeriodsPassed() internal view returns (uint256) {
        return (block.timestamp - startInflationTime) / periodDuration;
    }

    function claimable(address _receiver) public view returns(uint256) {
        uint256 total = totalMinted;
        uint256 target = targetMinted;
        uint256 dtMember = (block.timestamp - lastTs) / periodDuration * periodicEmission;
        if (dtMember + total > target) dtMember = target - total;
        uint256 dynamicMember = receivers.contains(_receiver) ? (dtMember + toDistribute) * weights[_receiver] / sumWeight : 0;
        return dynamicMember + available[_receiver] - claimed[_receiver];
    }

    function _safeTransfer(address _to, uint256 _amount) internal {
        address token_ = token;
        uint256 balance = IERC20(token_).balanceOf(address(this));
        if (balance >= _amount) {
            IERC20(token_).transfer(_to, _amount);
        } else {
            IERC20(token_).transfer(_to, balance);
        }
    }

    // """
    // @notice Mint part of available supply of tokens and assign them to approved contracts
    // @dev Emits a Transfer event originating from 0x00
    // @return bool success
    // """
    function _mint() internal returns (uint256){
        uint256 total = totalMinted;
        uint256 target = targetMinted;
        uint256 amountToPay;

        if(total < target && receivers.length() != 0) {
            // distribute prepaid amount for the upfront period
            uint256 periodsToPay = _getPeriodsPassed();
            // if we missed a payment, the amount will be multiplied
            uint256 mintForPeriods = periodsToPay * periodicEmission;
            uint256 plannedToMint = mintForPeriods > target ? target : mintForPeriods;
            amountToPay = plannedToMint - total;
            totalMinted += amountToPay;
            IMint(token).mint(address(this), amountToPay);
            lastTs = block.timestamp;
        }

        toDistribute += amountToPay;
        
        return amountToPay;
    }

}
