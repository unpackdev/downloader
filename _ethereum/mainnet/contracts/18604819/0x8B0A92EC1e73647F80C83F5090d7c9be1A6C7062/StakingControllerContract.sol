//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./NFTContract.sol";
import "./errors.sol";

contract StakingControllerContract {
    uint8 public immutable numApprovalsRequired;
    address public nftContractAddress;

    address[] public owners;
    mapping(address => bool) public isOwner;

    // Staking
    StakingAddressProposal[] public stakingAddresses;
    mapping(uint16 => mapping(address => bool)) public isStakingApproved;

    event SubmitStakingProposal(uint16 _stakingId);
    event ApproveStakingProposal(address _owner, uint16 _stakingId);
    event ExecuteStakingProposal(uint16 _stakingId);
    event RevokeStakingProposal(address _owner, uint16 _stakingId);


    struct StakingAddressProposal {
        uint16 id;
        address new_address;
        bool executed;
    }

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) {
            revert("SC: Not owner");
        }
        _;
    }

    modifier stakingExist(uint16 _stakingId) {
        if (_stakingId >= stakingAddresses.length) {
            revert("SC: Does not exist");
        }
        _;
    }

    modifier stakingNotApproved(uint16 _stakingId) {
        if (isStakingApproved[_stakingId][msg.sender]) {
            revert("SC: Already approved");
        }
        _;
    }

    modifier stakingNotExecuted(uint16 _stakingId) {
        if (stakingAddresses[_stakingId].executed) {
            revert("SC: Already executed");
        }
        _;
    }

    constructor(address[] memory _owners, uint8 _required)
    {
        if (_owners.length == 0 || _required > _owners.length) {
            revert StakingController_WrongArgumentsCount();
        }
        if (_required == 0) {
            revert StakingController_WrongInputUint();
        }

        for (uint8 _i = 0; _i < _owners.length; ++_i) {
            address _owner = _owners[_i];
            if (_owner == address(0)) {
                revert("SC: Invalid owner");
            }
            if (isOwner[_owner]) {
                revert("SC: Owner not unique");
            }

            isOwner[_owner] = true;
            owners.push(_owner);
        }

        numApprovalsRequired = _required;
    }

    // ----------- Public/External ------------

    function contractsList()
    external view
    returns (StakingAddressProposal[] memory)
    {
        return stakingAddresses;
    }

    function setNFTContractAddress(address _address)
    external
    {
        if (_address == address(0)) {
            revert StakingController_WrongInputAddress();
        }
        if (nftContractAddress != address(0)) {
            revert("SC: Contract address already set");
        }
        nftContractAddress = _address;
    }

    // --------------- Add Staking Address ----------------

    function submitNewStakingAddress(address _address)
    external
    onlyOwner
    {
        if (_address == address(0)) {
            revert StakingController_WrongInputAddress();
        }

        uint16 _stakingId = uint16(stakingAddresses.length);
        stakingAddresses.push(StakingAddressProposal({
            id: _stakingId,
            new_address: _address,
            executed: false
        }));

        emit SubmitStakingProposal(_stakingId);
    }

    function approveStakingProposal(uint16 _stakingId)
    external
    onlyOwner
    stakingExist(_stakingId)
    stakingNotApproved(_stakingId)
    stakingNotExecuted(_stakingId)
    {
        isStakingApproved[_stakingId][msg.sender] = true;
        emit ApproveStakingProposal(msg.sender, _stakingId);

        if (getStakingApprovals(_stakingId) == numApprovalsRequired) {
            StakingAddressProposal storage stakingProposal = stakingAddresses[_stakingId];
            NFTContract _nftContract = NFTContract(nftContractAddress);
            _nftContract.setDefaultStaking(stakingProposal.new_address);
            stakingProposal.executed = true;

            emit ExecuteStakingProposal(_stakingId);
        }
    }

    function revokeStakingApproval(uint16 _stakingId)
    external
    onlyOwner
    stakingExist(_stakingId)
    stakingNotExecuted(_stakingId)
    {
        if (!isStakingApproved[_stakingId][msg.sender]) {
            revert("SC: Not approved");
        }

        isStakingApproved[_stakingId][msg.sender] = false;
        emit RevokeStakingProposal(msg.sender, _stakingId);
    }

    function getStakingApprovals(uint16 _stakingId)
    public view
    stakingExist(_stakingId)
    returns (uint8)
    {
        uint8 _count = 0;
        for (uint8 _i = 0; _i < owners.length; ++_i) {
            if (isStakingApproved[_stakingId][owners[_i]]) {
                _count++;
            }
        }

        return _count;
    }

}