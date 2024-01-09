// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./BumperAccessControl.sol";
import "./StakeRewards.sol";

contract Vesting is PausableUpgradeable, BumperAccessControl {
    using SafeERC20 for IERC20;

    struct VestingInfo {
        uint256 start; // timestamp of start vesting
        uint256 end; // timestamp of end vesting
        uint256 cliff; // timestamp of cliff vesting
        uint256 vestingPerSec; // token release rate
        uint256 totalAmount; // total vested amount in current schedule
        uint256 onStartAmount; // amount is available immediately after start
        uint256 previousAmount; // amount from previous shedule
        uint256 claimedV1;  // claimed amount from first version vesting
    }

    address public tokenBUMP;
    bytes32 public merkleRoot;

    // Deprecated. This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    // Deprecated. Pause list of investors
    mapping(address => bool) private investorPause;

    // Total claimed for recipient
    mapping(address => uint256) public recipientClaimed;

    address public staking;
    
    // This event is triggered whenever a call to #claim succeeds.
    // The index field is used for the staking amount
    event Claimed(uint256 index, address indexed account, uint256 amount, uint256 timestamp);

    modifier verifyProofs(
        address account, 
        VestingInfo memory vestingInfo,
        bytes32[] memory merkleProof
    ) { 
        bytes32 node = keccak256(
            abi.encodePacked(
                account,
                vestingInfo.start,
                vestingInfo.end,
                vestingInfo.cliff,
                vestingInfo.vestingPerSec,
                vestingInfo.totalAmount,
                vestingInfo.onStartAmount,
                vestingInfo.previousAmount,
                vestingInfo.claimedV1
                )
        );
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Invalid proof"
        );

        _;
    }

    ///@notice Will initialize state variables of this contract
    ///@param _whitelistAddresses Array of white list addresses
    function initialize(
        address _token,
        bytes32 _merkleRoot,
        address[] calldata _whitelistAddresses,
        address _staking
    ) 
        public 
        initializer 
    {
        __Pausable_init();
        _BumperAccessControl_init(_whitelistAddresses);
        // token should NOT be 0 address
        require(_token != address(0), "address(0)");
        tokenBUMP = _token;
        merkleRoot = _merkleRoot;
        if(_staking != address(0)) {
            staking = _staking;
            IERC20(tokenBUMP).safeApprove(staking, type(uint256).max);
        }
        // contract is paused by default
        _pause();
    }

    /// @notice Claim amount of tokens.
    /// @dev Can only be invoked if the contract is NOT paused.
    /// @param account Investor address to which funds will be transferred
    /// @param vestingInfo Vesting schedule info
    /// @param merkleProof Proof of data accuracy
    function claim(
        address account, 
        VestingInfo memory vestingInfo,
        bytes32[] memory merkleProof
    )
        external 
        whenNotPaused
        verifyProofs(account, vestingInfo, merkleProof)
    {   
        _restoreClaimedV1(account, vestingInfo);

        uint256 amount = getClaimableAmountFor(account, vestingInfo);

        require(
            amount > 0,
            "Nothing to claim"
        );

        recipientClaimed[account] +=  amount;

        IERC20(tokenBUMP).safeTransfer(account, amount);
        emit Claimed(0, account, amount, block.timestamp);
    }

    /// @notice Stake vested tokens.
    /// @dev Can only be invoked if the contract is NOT paused.
    /// @dev If claimAmount equal stakingAmount then all amount will be staked.
    /// @dev If claimAmount is bigger stakingAmount then stakingAmount will be staked,
    /// @dev difference will be transfer to account.
    /// @param account Investor address
    /// @param vestingInfo Vesting schedule info
    /// @param stakingOption Staking option
    /// @param autorenew - auto-renewal staking when its finished
    /// @param claimAmount - amount to be claimed
    /// @param stakingAmount - amount to be staked
    /// @param merkleProof Proof of data accuracy
    function stakeVestedTokens(
        address account,
        VestingInfo memory vestingInfo,
        uint16 stakingOption,
        bool autorenew,
        uint256 claimAmount,
        uint256 stakingAmount,
        bytes32[] memory merkleProof
    )
        external
        whenNotPaused
        verifyProofs(account, vestingInfo, merkleProof)
    {
        _restoreClaimedV1(account, vestingInfo);

        uint256 amount = getClaimableAmountFor(account, vestingInfo);

        require(
            amount > 0,
            "Nothing to claim"
        );
        
        require(
            amount >= claimAmount,
            "Wrong claimAmount"
        );

        require(
            claimAmount >= stakingAmount,
            "Wrong stakingAmount"
        );

        recipientClaimed[account] +=  claimAmount;

        StakeRewards(staking).stakeFor(stakingAmount, stakingOption, account, autorenew);

        if (claimAmount > stakingAmount) {
            IERC20(tokenBUMP).safeTransfer(account, claimAmount - stakingAmount);
        }
        
        emit Claimed(stakingAmount, account, claimAmount, block.timestamp);
    }

    /// @notice Staking own and vested tokens with permit.
    /// @dev Can only be invoked if the contract is NOT paused.
    /// @param account Investor address
    /// @param vestingInfo Vesting schedule info
    /// @param stakingOption Staking option
    /// @param autorenew - auto-renewal staking when its finished
    /// @param ownAmount - own amount to be staked
    /// @param merkleProof Proof of data accuracy
    function stakeOwnAndVestedTokensWithPermit(
        address account,
        VestingInfo memory vestingInfo,
        uint16 stakingOption,
        bool autorenew,
        uint256 ownAmount,
        bytes32[] memory merkleProof,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        whenNotPaused
        verifyProofs(account, vestingInfo, merkleProof)
    {
        IERC20Permit(tokenBUMP).permit(
            account,
            address(this),
            ownAmount,
            deadline,
            v,
            r,
            s
        );

        _stakeOwnedAndVestedTokens(account, vestingInfo, stakingOption, autorenew, ownAmount);
    }

    /// @notice Staking own and vested tokens with approve.
    /// @dev Can only be invoked if the contract is NOT paused.
    /// @param account Investor address
    /// @param vestingInfo Vesting schedule info
    /// @param stakingOption Staking option
    /// @param autorenew - auto-renewal staking when its finished
    /// @param ownAmount - own amount to be staked
    /// @param merkleProof Proof of data accuracy
    function stakeOwnAndVestedTokensWithApprove(
        address account,
        VestingInfo memory vestingInfo,
        uint16 stakingOption,
        bool autorenew,
        uint256 ownAmount,
        bytes32[] memory merkleProof
    )
        external
        whenNotPaused
        verifyProofs(account, vestingInfo, merkleProof)
    {
        _stakeOwnedAndVestedTokens(account, vestingInfo, stakingOption, autorenew, ownAmount);
    }


    function _stakeOwnedAndVestedTokens(
        address account,
        VestingInfo memory vestingInfo,
        uint16 stakingOption,
        bool autorenew,
        uint256 ownAmount
    )
        internal
    {
        _restoreClaimedV1(account, vestingInfo);

        uint256 amount = getClaimableAmountFor(account, vestingInfo);

        require(
            amount > 0,
            "Nothing to claim"
        );
        
        recipientClaimed[account] +=  amount;

        IERC20(tokenBUMP).safeTransferFrom(account, address(this), ownAmount);

        StakeRewards(staking).stakeFor(ownAmount + amount, stakingOption, account, autorenew);

        emit Claimed(ownAmount + amount, account, amount, block.timestamp);
    }

    /// @notice Restores balances for investors of the first version of vesting.
    /// @param account Investor address to which funds will be transferred
    /// @param vestingInfo Vesting schedule info
    function _restoreClaimedV1(
        address account, 
        VestingInfo memory vestingInfo
    ) 
        internal 
    { 
        if (vestingInfo.claimedV1 > recipientClaimed[account]) {
            recipientClaimed[account] = vestingInfo.claimedV1;
        }
    }

    /// @notice Get amount of tokens that can be claimed by a recipient at the current timestamp.
    /// @param account A non-terminated recipient address.
    /// @param vestingInfo Vesting schedule info
    /// @return Amount of tokens that can be claimed by a recipient at the current timestamp.
    function getClaimableAmountFor(
        address account, 
        VestingInfo memory vestingInfo
    )
        public
        view
        returns (uint256)
    {
        uint256 totalClaimed = recipientClaimed[account];
        if (vestingInfo.claimedV1 > totalClaimed) {
            totalClaimed = vestingInfo.claimedV1;
        }
        
        uint256 locked = totalLockedOf(vestingInfo);
        
        if (vestingInfo.totalAmount + vestingInfo.previousAmount > locked + totalClaimed) {
            return vestingInfo.totalAmount + vestingInfo.previousAmount -
                (locked + totalClaimed);
        } else {
            return 0;
        }
    }

    /// @notice Get total locked tokens of a specific recipient.
    /// @param vestingInfo Vesting schedule info
    /// @return Total locked tokens of a specific recipient.
    function totalLockedOf(VestingInfo memory vestingInfo)
        public
        view
        returns (uint256)
    {
        // We know that vestingPerSec is constant for a recipient for entirety of their vesting period
        // lockedTokens = vestingPerSec*(endTime-(startTime+cliffDuration))

        if (block.timestamp >= vestingInfo.end) {
            // If the period has passed nothing to block
            return 0;
        } else if (
            block.timestamp >= vestingInfo.start + vestingInfo.cliff
        ) {
            // If the period has not yet passed block diff, OnStartVesting not blocked
            return (vestingInfo.end - block.timestamp) * vestingInfo.vestingPerSec;
        } else {
            // Everything will be blocked
            return vestingInfo.totalAmount;
        }
    }

    function setStakingContract(address _staking) 
        external 
        onlyGovernanceOrOwner
    {
        staking = _staking;
        IERC20(tokenBUMP).safeApprove(staking, type(uint256).max);
    }

    /// @notice Transfer tokens from the contract to the address.
    /// @dev Only owner of the vesting escrow can invoke this function.
    function withdraw(
        address to,
        address token,
        uint256 amount
    ) 
        external 
        onlyGovernanceOrOwner 
    {
        IERC20(token).safeTransfer(to, amount);
    }

    /// @notice Set Merkle root
    /// @dev Only owner of the vesting escrow can invoke this function.
    function setMerkleRoot(bytes32 root) 
        external 
        onlyGovernanceOrOwner 
    {
        merkleRoot = root;
    }

    /// @notice Pause vesting contract
    /// @dev Only owner of the vesting escrow can invoke this function.
    function pause() 
        external 
        onlyGovernanceOrOwner 
        whenNotPaused 
    {
        _pause();
    }

    /// @notice Unpause vesting contract
    /// @dev Only owner of the vesting escrow can invoke this function.
    function unpause() 
        external 
        onlyGovernanceOrOwner 
        whenPaused 
    {
        _unpause();
    }
}
