// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

// Single Admin
contract WellAdmin {
    uint256 private _totalSuperAdmins; // Total number of superadmins
    uint256 private _totalSuperAdminsAdded; // +1 everytime a superadmin is added. Never decreased.
    address public admin;
    mapping(address => uint256) public _superAdminIndex; // starts at 1

    mapping(bytes32 => uint256) operationVotes;
    mapping(bytes32 => uint256) adminOperationMask;

    event NewSuperAdmin(address admin_);
    event RemoveSuperAdmin(address admin_);
    event VoteAdded(address _voter, bytes32 operation);

    constructor() {
        _totalSuperAdmins = 0;
        _totalSuperAdminsAdded = 0;

        _addSuperAdmin(msg.sender);
        setAdmin(msg.sender);
    }

    modifier isAdmin() {
        require(admin == msg.sender, 'is not Admin');
        _;
    }

    modifier isSuperAdmin() {
        require(_superAdminIndex[msg.sender] != 0, 'is not Superadmin');
        _;
    }

    /**
      * Checks if operation has enough votes. Will reset votes if enough votes are reached for the operation
      */
    function _hasEnoughVotes(bytes32 operation) internal returns(bool) {
        if(_totalSuperAdmins < 2 || (operationVotes[operation] > (_totalSuperAdmins / 2))) { 
            // Reset votes
            delete operationVotes[operation];
            delete adminOperationMask[operation];

            return true;
        } else
            return false;
    }

    function _addVote(bytes32 operation, address admin_) internal {
        if(_totalSuperAdmins > 1) {
            // Check that superadmin hasn't already voted.
            require( adminOperationMask[operation] & (2 ** (_superAdminIndex[admin_] - 1)) == 0, 'Duplicate vote');

            operationVotes[operation]++;
            adminOperationMask[operation] |= (2 ** (_superAdminIndex[admin_] - 1));
            emit VoteAdded(msg.sender, operation);
        }
    }

    function _addSuperAdmin(address _newSuperAdmin) private {
        require(_superAdminIndex[_newSuperAdmin] == 0, 'Superadmin already exists');
        require(_totalSuperAdmins < 5);

        bytes32 op = keccak256(msg.data);

        _addVote(op, msg.sender);

        if(_hasEnoughVotes(op)) {
            _totalSuperAdmins++;
            _totalSuperAdminsAdded++;
            _superAdminIndex[_newSuperAdmin] = _totalSuperAdminsAdded;

            emit NewSuperAdmin(_newSuperAdmin);
        }
    }

    function setAdmin(address _newAdmin) public isSuperAdmin {
        bytes32 op = keccak256(msg.data);

        _addVote(op, msg.sender);

        if(_hasEnoughVotes(op)) {
            admin = _newAdmin;
        }
    }

    function removeAdmin() external isSuperAdmin {
        bytes32 op = keccak256(msg.data);

        _addVote(op, msg.sender);

        if(_hasEnoughVotes(op)) {
            admin = address(0);
        }
    }

    function addSuperAdmin(address _newAdmin) external isSuperAdmin {
        _addSuperAdmin(_newAdmin);
    }

    function removeSuperAdmin(address _adminToRemove) external isSuperAdmin {
        require(_totalSuperAdmins > 1, 'too few superadmins');
        require(_superAdminIndex[_adminToRemove] != 0, 'admin already removed');

        bytes32 op = keccak256(msg.data);
        _addVote(op, msg.sender);

        if(_hasEnoughVotes(op)) {
            delete _superAdminIndex[_adminToRemove];
            _totalSuperAdmins--;

            emit RemoveSuperAdmin(_adminToRemove);
        }
    }
}
