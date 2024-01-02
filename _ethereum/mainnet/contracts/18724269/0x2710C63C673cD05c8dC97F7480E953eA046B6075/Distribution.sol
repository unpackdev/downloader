// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "./MerkleProofLib.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract Distribution is Ownable {
    error InvalidProof();
    error ZeroClaimable();
    error ClaimStillActive();

    bytes32 private _root;
    mapping(address => uint256) public previouslyClaimedAmount;

    uint256 private immutable _CLAIM_START;
    uint256 private immutable _VESTING_START;
    uint256 private constant _CLIFF = 60 days;
    uint256 private constant _VESTING_DURATION = 547.92 days; // ~18 months
    uint256 private constant _GRACE_PERIOD = 365 days; // 1 year

    address public constant INSPECT_TOKEN = 0x186eF81fd8E77EEC8BfFC3039e7eC41D5FC0b457;

    constructor(bytes32 root, uint256 claimStart) {
        _initializeOwner(tx.origin);
        _root = root;
        _CLAIM_START = claimStart;
        unchecked { _VESTING_START = claimStart + _CLIFF; }
    }

    function setRoot(bytes32 _newRoot) external onlyOwner {
        _root = _newRoot;
    }

    function withdrawUnclaimedTokens() external onlyOwner {
        uint256 claimExpiry;

        unchecked {
            claimExpiry = _VESTING_START + _VESTING_DURATION + _GRACE_PERIOD;
        }

        if (block.timestamp < claimExpiry) revert ClaimStillActive();

        uint256 balance = IERC20(INSPECT_TOKEN).balanceOf(address(this));
        IERC20(INSPECT_TOKEN).transfer(msg.sender, balance);
    }

    function claim(address _recipient, uint256 _totalAllocation, bytes32[] calldata _proof) external {
        bytes32 leaf = keccak256(abi.encode(_recipient, _totalAllocation));
        if (!MerkleProofLib.verifyCalldata(_proof, _root, leaf)) revert InvalidProof();

        uint256 _previouslyClaimed = previouslyClaimedAmount[_recipient];
        uint256 _claimableAmount = _totalClaimable(_totalAllocation, _previouslyClaimed);

        if (_claimableAmount == 0) revert ZeroClaimable();
        unchecked { previouslyClaimedAmount[_recipient] += _claimableAmount; }

        IERC20(INSPECT_TOKEN).transfer(_recipient, _claimableAmount);
    }

    function claimableAmount(address _recipient, uint256 _totalAllocation) external view returns (uint256) {
        uint256 _previouslyClaimed = previouslyClaimedAmount[_recipient];

        return _totalClaimable(_totalAllocation, _previouslyClaimed);
    }

    function _totalClaimable(uint256 _totalAllocation, uint256 _previouslyClaimed) internal view returns (uint256) {
        if (block.timestamp < _CLAIM_START) return 0;
        if (block.timestamp <= _VESTING_START) return _totalAllocation / 10 - _previouslyClaimed;
        if (block.timestamp > _VESTING_START + _VESTING_DURATION) return _totalAllocation - _previouslyClaimed;

        uint256 _initialClaimableAmount;
        uint256 _vestingBalance;
        uint256 _timeElapsed;

        unchecked {
            _initialClaimableAmount = _totalAllocation / 10;
            _vestingBalance = _totalAllocation - _initialClaimableAmount;
            _timeElapsed = block.timestamp - _VESTING_START;
        }

        return _initialClaimableAmount + (_timeElapsed * _vestingBalance / _VESTING_DURATION) - _previouslyClaimed;
    }
}
