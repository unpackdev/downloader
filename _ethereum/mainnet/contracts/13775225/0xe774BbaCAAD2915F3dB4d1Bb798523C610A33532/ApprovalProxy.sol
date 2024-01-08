// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Address.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./IApprovalProxy.sol";

import "./console.sol";

contract ApprovalProxy is IApprovalProxy, AccessControl, Ownable {
    using Address for address;

    bytes32 private constant APPROVABLE = keccak256("APPROVABLE");
    bytes32 private constant PREAPPROVED = keccak256("PREAPPROVED");

    mapping(address => mapping(address => bool))
        private _expresslyNotApprovalSpender;
    mapping(address => mapping(address => bool)) private _contractApprovals;

    event UpdateApprovableContracts(address spender, bool approved);
    event UpdatePreapprovedContracts(address spender, bool approved);

    modifier onlyContract(address _spender) {
        require(
            _spender.isContract(),
            "ApprovalProxy: _spender must be contract"
        );
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setApprovalForAll(
        address _owner,
        address _spender,
        bool _approved
    ) public override onlyContract(_spender) {
        require(
            isApprovableContract(_spender),
            "ApprovalProxy: _spender must belong to approvable role"
        );
        _expresslyNotApprovalSpender[_owner][_spender] = !_approved;
    }

    function isApprovedForAll(
        address _owner,
        address _spender,
        bool _original
    ) public view override returns (bool) {
        if (_spender.isContract()) {
            if (isPreapprovedContract(_spender)) {
                return !_expresslyNotApprovalSpender[_owner][_spender];
            }
        }
        return _original;
    }

    // Approvable list
    function setApprovableContracts(address _spender, bool _approvable)
        public
        onlyOwner
        onlyContract(_spender)
    {
        emit UpdateApprovableContracts(_spender, _approvable);
        if (_approvable) {
            grantRole(APPROVABLE, _spender);
        } else {
            renounceRole(APPROVABLE, _spender);
        }
    }

    function isApprovableContract(address _spender) public view returns (bool) {
        return hasRole(APPROVABLE, _spender);
    }

    function setPreapprovedContracts(address _spender, bool _approval)
        public
        onlyOwner
        onlyContract(_spender)
    {
        if (_approval) {
            if (!isApprovableContract(_spender)) {
                setApprovableContracts(_spender, true);
            }
            grantRole(PREAPPROVED, _spender);
        } else {
            renounceRole(PREAPPROVED, _spender);
        }
    }

    function isPreapprovedContract(address _spender)
        public
        view
        returns (bool)
    {
        return hasRole(PREAPPROVED, _spender);
    }
}
