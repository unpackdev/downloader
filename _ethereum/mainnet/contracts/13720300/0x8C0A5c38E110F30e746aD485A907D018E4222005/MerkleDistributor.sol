// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor {
    address private immutable _token;
    address private immutable _governance;
    bytes32 private immutable _merkleRoot;
    uint256 private immutable _unlockTimestamp;
    uint256 private immutable _clawbackTimestamp;
    uint256 private immutable _amountToClaim;

    mapping(bytes32 => bool) private _claimed;

    error ClaimLocked();
    error ClawbackLocked();
    error AlreadyClaimed();
    error InvalidProof();
    error NotGovernance();
    error NotGovernanceOrSelf();
    error ClawbackFailed();
    error ClaimFailed();

    modifier unlocked() {
        if (block.timestamp < _unlockTimestamp) revert ClaimLocked();
        _;
    }

    modifier clawbackAllowed() {
        if (block.timestamp < _clawbackTimestamp) revert ClawbackLocked();
        _;
    }

    modifier notClaimed(uint256 index, address account) {
        if (isClaimed(index, account)) revert AlreadyClaimed();
        _;
    }

    modifier validProof(
        uint256 index,
        address account,
        bytes32[] memory merkleProof
    ) {
        bool result = verifyMerkleProof(
            index,
            account,
            merkleProof
        );
        if (!result) revert InvalidProof();
        _;
    }

    modifier isGovernance() {
        if (msg.sender != _governance) revert NotGovernance();
        _;
    }

    constructor(
        address token_,
        uint256 amountToClaim_,
        bytes32 merkleRoot_,
        address governance_,
        uint256 unlockTimestamp_,
        uint256 clawbackTimestamp_
    ) {
        _token = token_;
        _amountToClaim = amountToClaim_;
        _merkleRoot = merkleRoot_;
        _governance = governance_;
        _unlockTimestamp = unlockTimestamp_;
        _clawbackTimestamp = clawbackTimestamp_;
    }

    // Claim the given amount of the token to self. Reverts if the inputs are invalid.
    function claim(
        uint256 index,
        bytes32[] calldata merkleProof
    )
        external
        override
        unlocked
    {
        _claim(index, msg.sender, merkleProof);
    }

    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claimByGovernance(
        uint256 index,
        address account,
        bytes32[] calldata merkleProof
    )
        external
        override
        isGovernance
        unlocked
    {
        _claim(index, account, merkleProof);
    }

    // Clawback the given amount of the token to the given address.
    function clawback()
        external
        override
        isGovernance
        clawbackAllowed
    {
        emit Clawback();

        uint256 balance = IERC20(_token).balanceOf(address(this));
        bool result = IERC20(_token).transfer(_governance, balance);
        if (!result) revert ClawbackFailed();
    }

    // Returns the address of the token distributed by this contract.
    function token() external view override returns (address) {
        return _token;
    }

    // Returns the amount of the token distributed by this contract.
    function amountToClaim() external view override returns (uint256) {
        return _amountToClaim;
    }

    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view override returns (bytes32) {
        return _merkleRoot;
    }

    // Returns the unlock block timestamp
    function unlockTimestamp() external view override returns (uint256) {
        return _unlockTimestamp;
    }

    // Returns the clawback block timestamp
    function clawbackTimestamp() external view override returns (uint256) {
        return _clawbackTimestamp;
    }

    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index, address account) public view override returns (bool) {
        return _claimed[_node(index, account)] == true;
    }

    // Verify the merkle proof.
    function verifyMerkleProof(
        uint256 index,
        address account,
        bytes32[] memory merkleProof
    )
        public
        view
        override
        returns (bool)
    {
        bytes32 node = _node(index, account);
        return MerkleProof.verify(merkleProof, _merkleRoot, node);
    }

    function _claim(
        uint256 index,
        address account,
        bytes32[] memory merkleProof
    )
        private
        notClaimed(index, account)
        validProof(index, account, merkleProof)
    {
        // Mark it claimed and send the token.
        _setClaimed(index, account);
        emit Claimed(index, account);

        bool result = IERC20(_token).transfer(account, _amountToClaim);
        if (!result) revert ClaimFailed();
    }

    function _setClaimed(uint256 index, address account) private {
        _claimed[_node(index, account)] = true;
    }

    function _node(uint256 index, address account) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(index, account));
    }
}
