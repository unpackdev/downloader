// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./IERC20.sol";
import "./IRewardDistributor.sol";
import "./IBSLendingPair.sol";
import "./UUPSProxiable.sol";
import "./IRewardDistributorManager.sol";

abstract contract RewardDistributorManagerStorageV1 is UUPSProxiable, IRewardDistributorManager {
    /// @dev admin
    address public owner;

    /// @dev newAdmin
    address internal newOwner;

    /// @dev approvedistributions
    mapping(IRewardDistributor => bool) public approvedDistributors;

    /// @dev receipt token address => distributor
    mapping(address => IRewardDistributor[]) public tokenRewardToDistributors;
}

contract RewardDistributorManager is RewardDistributorManagerStorageV1 {
    modifier onlyOwner {
        require(owner == msg.sender, "ONLY_OWNER");
        _;
    }

    /// @notice initialize
    /// @param _owner owner to perform owner functions
    function initialize(address _owner) external initializer {
        require(_owner != address(0), "INVALID_OWNER");

        owner = _owner;

        emit Initialized(_owner, block.timestamp);
    }

    /// @dev Accumulates rewards for users
    /// @param _from user address
    /// @param _to user address
    function accumulateRewards(address _from, address _to) external override {
        IRewardDistributor[] memory distributors = tokenRewardToDistributors[msg.sender];
        uint256 size = distributors.length;

        if (size == 0) return;

        /// We need to manage the size of the rewards to prevent
        /// astronomical increase in gas cost
        for (uint256 i = 0; i < size; i++) {
            if (_from != address(0)) distributors[i].accumulateReward(msg.sender, _from);
            if (_to != address(0)) distributors[i].accumulateReward(msg.sender, _to);
        }
    }

    /// @dev approves a distributor contract for a token
    /// @param _distributor The distributor contract address
    /// @param _approve the status of the distributor contract
    function setDistributorStatus(IRewardDistributor _distributor, bool _approve)
        external
        onlyOwner
    {
        approvedDistributors[_distributor] = _approve;
        emit DistributorStatusUpdated(_distributor, _approve, block.timestamp);
    }

    /// @dev Enables a distributor contract to activate reward for a token
    /// @param _tokenAddr the token the distributor contract is adding a reward for
    function activateReward(address _tokenAddr) external override {
        require(
            approvedDistributors[IRewardDistributor(msg.sender)] == true,
            "ONLY_APPROVED_DISTRIBUTOR"
        );

        IRewardDistributor[] storage distributors = tokenRewardToDistributors[_tokenAddr];

        require(
            findRewardDistributor(distributors, IRewardDistributor(msg.sender)) == -1,
            "DISTRIBUTOR_EXISTS"
        );

        distributors.push(IRewardDistributor(msg.sender));

        emit AddReward(_tokenAddr, IRewardDistributor(msg.sender), block.timestamp);
    }

    /// @dev Remove  a reward distributor
    /// @param _tokenAddr address of the receipt token
    /// @param _distributor distributor contract
    function removeReward(address _tokenAddr, IRewardDistributor _distributor)
        external
        override
        onlyOwner
    {
        IRewardDistributor[] storage distributors = tokenRewardToDistributors[_tokenAddr];
        uint256 size = distributors.length;

        int256 rewardIndex = findRewardDistributor(distributors, _distributor);
        if (rewardIndex == -1) return;

        distributors[uint256(rewardIndex)] = distributors[size - 1];
        // used pop instead of delete because pop reduces array length
        distributors.pop();

        emit RemoveReward(_tokenAddr, _distributor, block.timestamp);
    }

    function findRewardDistributor(
        IRewardDistributor[] memory distributors,
        IRewardDistributor _distributor
    ) internal pure returns (int256 index) {
        index = -1;
        uint256 size = distributors.length;
        for (uint256 i = 0; i < size; i++) {
            if (address(distributors[i]) == address(_distributor)) {
                index = int256(i);
                break;
            }
        }
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "INVALID_NEW_OWNER");
        newOwner = _newOwner;
        emit TransferControl(_newOwner, block.timestamp);
    }

    function acceptOwnership() external {
        require(msg.sender == newOwner, "invalid owner");

        // emit event before state change to do not trigger null address
        emit OwnershipAccepted(owner, newOwner, block.timestamp);

        owner = newOwner;
        newOwner = address(0);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // UUPSProxiable
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function proxiableUUID() public pure override returns (bytes32) {
        return keccak256("org.warp.contracts.warprewards.implementation");
    }

    function updateCode(address newAddress) external override onlyOwner {
        _updateCodeAddress(newAddress);
    }
}
