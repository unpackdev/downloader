// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 */
abstract contract Approvable is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    EnumerableSet.AddressSet _approvers;
    mapping(address => uint256) private _weights;
    uint256 private _totalWeight;
    uint256 private _threshold;


    struct GrantApprover {
        uint256 id;
        bool executed;
        address account;
        uint256 weight;
        uint256 approvalsWeight;
    }
    GrantApprover[] private _grantApprovers;
    mapping(address => mapping(uint256 => bool)) private _approvalsGrantApprover;


    struct ChangeApproverWeight {
        uint256 id;
        bool executed;
        address account;
        uint256 weight;
        uint256 approvalsWeight;
    }
    ChangeApproverWeight[] private _changeApproverWeights;
    mapping(address => mapping(uint256 => bool)) private _approvalsChangeApproverWeight;


    struct RevokeApprover {
        uint256 id;
        bool executed;
        address account;
        uint256 approvalsWeight;
    }
    RevokeApprover[] private _revokeApprovers;
    mapping(address => mapping(uint256 => bool)) private _approvalsRevokeApprover;


    struct ChangeThreshold {
        uint256 id;
        bool executed;
        uint256 threshold;
        uint256 approvalsWeight;
    }
    ChangeThreshold[] private _changeThresholds;
    mapping(address => mapping(uint256 => bool)) private _approvalsChangeThreshold;


    event NewGrantApprover(uint256 indexed id, address indexed account, uint256 weight);
    event VoteForGrantApprover(uint256 indexed id, address indexed voter, uint256 voterWeight, uint256 approvalsWeight);
    event ApproverGranted(address indexed account);

    event NewChangeApproverWeight(uint256 indexed id, address indexed account, uint256 weight);
    event VoteForChangeApproverWeight(uint256 indexed id, address indexed voter, uint256 voterWeight, uint256 approvalsWeight);
    event ApproverWeightChanged(address indexed account, uint256 oldWeight, uint256 newWeight);

    event NewRevokeApprover(uint256 indexed id, address indexed account);
    event VoteForRevokeApprover(uint256 indexed id, address indexed voter, uint256 voterWeight, uint256 approvalsWeight);
    event ApproverRevoked(address indexed account);

    event NewChangeThreshold(uint256 indexed id, uint256 threshold);
    event VoteForChangeThreshold(uint256 indexed id, address indexed voter, uint256 voterWeight, uint256 approvalsWeight);
    event ThresholdChanged(uint256 oldThreshold, uint256 newThreshold);

    event TotalWeightChanged(uint256 oldTotalWeight, uint256 newTotalWeight);


    function getThreshold() public view returns (uint256) {
        return _threshold;
    }

    function getTotalWeight() public view returns (uint256) {
        return _totalWeight;
    }

    function getApproversCount() public view returns (uint256) {
        return _approvers.length();
    }

    function isApprover(address account) public view returns (bool) {
        return _approvers.contains(account);
    }

    function getApprover(uint256 index) public view returns (address) {
        return _approvers.at(index);
    }

    function getApproverWeight(address account) public view returns (uint256) {
        return _weights[account];
    }


    // GrantApprovers
    function getGrantApproversCount() public view returns (uint256) {
        return _grantApprovers.length;
    }

    function getGrantApprover(uint256 id) public view returns (GrantApprover memory) {
        return _grantApprovers[id];
    }

    // ChangeApproverWeights
    function getChangeApproverWeightsCount() public view returns (uint256) {
        return _changeApproverWeights.length;
    }

    function getChangeApproverWeight(uint256 id) public view returns (ChangeApproverWeight memory) {
        return _changeApproverWeights[id];
    }

    // RevokeApprovers
    function getRevokeApproversCount() public view returns (uint256) {
        return _revokeApprovers.length;
    }

    function getRevokeApprover(uint256 id) public view returns (RevokeApprover memory) {
        return _revokeApprovers[id];
    }

    // ChangeThresholds
    function getChangeThresholdsCount() public view returns (uint256) {
        return _changeThresholds.length;
    }

    function getChangeThreshold(uint256 id) public view returns (ChangeThreshold memory) {
        return _changeThresholds[id];
    }


    // Grant Approver
    function grantApprover(address account, uint256 weight) public onlyApprover returns (uint256) {
        uint256 id = _addNewGrantApprover(account, weight);
        _voteForGrantApprover(id);
        return id;
    }

    function _addNewGrantApprover(address account, uint256 weight) private returns (uint256) {
        require(account != address(0), "Approvable: account is the zero address");
        uint256 id = _grantApprovers.length;
        _grantApprovers.push(GrantApprover(id, false, account, weight, 0));
        emit NewGrantApprover(id, account, weight);
        return id;
    }

    function _voteForGrantApprover(uint256 id) private returns (bool) {
        address msgSender = _msgSender();
        _approvalsGrantApprover[msgSender][id] = true;
        _grantApprovers[id].approvalsWeight = _grantApprovers[id].approvalsWeight.add(_weights[msgSender]);
        emit VoteForGrantApprover(id, msgSender, _weights[msgSender], _grantApprovers[id].approvalsWeight);
        return true;
    }

    function _grantApprover(address account, uint256 weight) private returns (bool) {
        if (_approvers.add(account)) {
            _changeApproverWeight(account, weight);
            _setTotalWeight(_totalWeight.add(weight));
            emit ApproverGranted(account);
            return true;
        }
        return false;
    }

    function _setupApprover(address account, uint256 weight) internal returns (bool) {
        return _grantApprover(account, weight);
    }

    function approveGrantApprover(uint256 id) public onlyApprover returns (bool) {
        require(_grantApprovers[id].executed == false, "Approvable: action has already executed");
        require(_approvalsGrantApprover[_msgSender()][id] == false, "Approvable: Cannot approve action twice");
        return _voteForGrantApprover(id);
    }

    function confirmGrantApprover(uint256 id) public returns (bool) {
        require(_grantApprovers[id].account == _msgSender(), "Approvable: only pending approver");
        require(_grantApprovers[id].executed == false, "Approvable: action has already executed");
        if (_grantApprovers[id].approvalsWeight >= _threshold) {
            _grantApprover(_grantApprovers[id].account, _grantApprovers[id].weight);
            _grantApprovers[id].executed = true;
            return true;
        }
        return false;
    }


    // Change Approver Weight
    function changeApproverWeight(address account, uint256 weight) public onlyApprover returns (uint256) {
        require(_totalWeight.sub(_weights[account]).add(weight) >= _threshold, "Approvable: The threshold is greater than new totalWeight");
        uint256 id = _addNewChangeApproverWeight(account, weight);
        _voteForChangeApproverWeight(id);
        return id;
    }

    function _addNewChangeApproverWeight(address account, uint256 weight) private returns (uint256) {
        require(account != address(0), "Approvable: account is the zero address");
        uint256 id = _changeApproverWeights.length;
        _changeApproverWeights.push(ChangeApproverWeight(id, false, account, weight, 0));
        emit NewChangeApproverWeight(id, account, weight);
        return id;
    }

    function _voteForChangeApproverWeight(uint256 id) private returns (bool) {
        address msgSender = _msgSender();
        _approvalsChangeApproverWeight[msgSender][id] = true;
        _changeApproverWeights[id].approvalsWeight = _changeApproverWeights[id].approvalsWeight.add(_weights[msgSender]);
        emit VoteForChangeApproverWeight(id, msgSender, _weights[msgSender], _changeApproverWeights[id].approvalsWeight);
        if (_changeApproverWeights[id].approvalsWeight >= _threshold) {
            _changeApproverWeight(_changeApproverWeights[id].account, _changeApproverWeights[id].weight);
            _changeApproverWeights[id].executed = true;
        }
        return true;
    }

    function _changeApproverWeight(address account, uint256 weight) private returns (bool) {
        require(_totalWeight.sub(_weights[account]).add(weight) >= _threshold, "Approvable: The threshold is greater than new totalWeight");
        emit ApproverWeightChanged(account, _weights[account], weight);
        _weights[account] = weight;
        return true;
    }

    function approveChangeApproverWeight(uint256 id) public onlyApprover returns (bool) {
        require(_changeApproverWeights[id].executed == false, "Approvable: action has already executed");
        require(_approvalsChangeApproverWeight[_msgSender()][id] == false, "Approvable: Cannot approve action twice");
        return _voteForChangeApproverWeight(id);
    }


    // Revoke Approver
    function revokeApprover(address account) public onlyApprover returns (uint256) {
        require(_totalWeight.sub(_weights[account]) >= _threshold, "Approvable: The threshold is greater than new totalWeight");
        uint256 id = _addNewRevokeApprover(account);
        _voteForRevokeApprover(id);
        return id;
    }

    function _addNewRevokeApprover(address account) private returns (uint256) {
        require(account != address(0), "Approvable: account is the zero address");
        uint256 id = _revokeApprovers.length;
        _revokeApprovers.push(RevokeApprover(id, false, account, 0));
        emit NewRevokeApprover(id, account);
        return id;
    }

    function _voteForRevokeApprover(uint256 id) private returns (bool) {
        address msgSender = _msgSender();
        _approvalsRevokeApprover[msgSender][id] = true;
        _revokeApprovers[id].approvalsWeight = _revokeApprovers[id].approvalsWeight.add(_weights[msgSender]);
        emit VoteForRevokeApprover(id, msgSender, _weights[msgSender], _revokeApprovers[id].approvalsWeight);
        if (_revokeApprovers[id].approvalsWeight >= _threshold) {
            _revokeApprover(_revokeApprovers[id].account);
            _revokeApprovers[id].executed = true;
        }
        return true;
    }

    function _revokeApprover(address account) private returns (bool) {
        uint256 newTotalWeight = _totalWeight.sub(_weights[account]);
        require(newTotalWeight >= _threshold, "Approvable: The threshold is greater than new totalWeight");
        if (_approvers.remove(account)) {
            _changeApproverWeight(account, 0);
            _setTotalWeight(newTotalWeight);
            emit ApproverRevoked(account);
            return true;
        }
        return false;
    }

    function approveRevokeApprover(uint256 id) public onlyApprover returns (bool) {
        require(_revokeApprovers[id].executed == false, "Approvable: action has already executed");
        require(_approvalsRevokeApprover[_msgSender()][id] == false, "Approvable: Cannot approve action twice");
        return _voteForRevokeApprover(id);
    }

    function renounceApprover(address account) public returns (bool) {
        require(account == _msgSender(), "Approvable: can only renounce roles for self");
        return _revokeApprover(account);
    }


    // Change Threshold
    function changeThreshold(uint256 threshold) public onlyApprover returns (uint256) {
        require(getTotalWeight() >= threshold, "Approvable: The new threshold is greater than totalWeight");
        uint256 id = _addNewChangeThreshold(threshold);
        _voteForChangeThreshold(id);
        return id;
    }

    function _addNewChangeThreshold(uint256 threshold) private returns (uint256) {
        uint256 id = _changeThresholds.length;
        _changeThresholds.push(ChangeThreshold(id, false, threshold, 0));
        emit NewChangeThreshold(id, threshold);
        return id;
    }

    function _voteForChangeThreshold(uint256 id) private returns (bool) {
        address msgSender = _msgSender();
        _approvalsChangeThreshold[msgSender][id] = true;
        _changeThresholds[id].approvalsWeight = _changeThresholds[id].approvalsWeight.add(_weights[msgSender]);
        emit VoteForChangeThreshold(id, msgSender, _weights[msgSender], _changeThresholds[id].approvalsWeight);
        if (_changeThresholds[id].approvalsWeight >= _threshold) {
            _setThreshold(_changeThresholds[id].threshold);
            _changeThresholds[id].executed = true;
        }
        return true;
    }

    function approveChangeThreshold(uint256 id) public onlyApprover returns (bool) {
        require(_changeThresholds[id].executed == false, "Approvable: action has already executed");
        require(_approvalsChangeThreshold[_msgSender()][id] == false, "Approvable: Cannot approve action twice");
        return _voteForChangeThreshold(id);
    }

    function _setThreshold(uint256 threshold) private returns (bool) {
        require(getTotalWeight() >= threshold, "Approvable: The new threshold is greater than totalWeight");
        emit ThresholdChanged(_threshold, threshold);
        _threshold = threshold;
        return true;
    }

    function _setupThreshold(uint256 threshold) internal returns (bool) {
        return _setThreshold(threshold);
    }


    // Total Weight
    function _setTotalWeight(uint256 totalWeight) private returns (bool) {
        emit TotalWeightChanged(_totalWeight, totalWeight);
        _totalWeight = totalWeight;
        return true;
    }

    modifier onlyApprover() {
        require(isApprover(_msgSender()), "Approvable: caller is not the approver");
        _;
    }
}
