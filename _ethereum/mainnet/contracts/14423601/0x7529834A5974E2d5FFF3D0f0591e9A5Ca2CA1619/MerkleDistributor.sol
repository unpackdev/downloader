// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./MerkleProof.sol";
import "./SafeERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IMerkleDistributor.sol";
import "./PausableUpgradeable.sol";

contract MerkleDistributor is
    IMerkleDistributor,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    address public override token;
    bool public isMerkleRootSet;
    bytes32 public override merkleRoot;
    uint256 public endTimestamp;
    mapping(bytes32 => mapping(address => bool)) public claimed;
    address public constant TREASURY =
        address(0x472FcC65Fab565f75B1e0E861864A86FE5bcEd7B);

    function initialize(address _token) external initializer {
        __Pausable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        token = _token;
    }

    function pauseAirdrop() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpauseAirdrop() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Set merkle root for airdrop
     * @param _merkleRoot merkle root
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        isMerkleRootSet = true;
        merkleRoot = _merkleRoot;
        emit MerkleRootSet(_merkleRoot);
    }

    /**
     * @notice Update end timestamp
     * @param _endTimestamp new endtimestamp
     */
    function setEndTimestamp(uint256 _endTimestamp) external onlyOwner {
        require(
            block.timestamp < _endTimestamp,
            "Owner: Can't set past timestamp."
        );
        endTimestamp = _endTimestamp;

        emit EndTimestampSet(_endTimestamp);
    }

    function _isClaimed(bytes32 _merkleRoot, address _account)
        internal
        view
        returns (bool)
    {
        bool _claimed = claimed[_merkleRoot][_account];
        return _claimed;
    }

    function isClaimed(address _account) public view override returns (bool) {
        require(isMerkleRootSet, "MerkleDistributor: Merkle root not set.");
        return _isClaimed(merkleRoot, _account);
    }

    function _setClaimed(bytes32 _merkleRoot, address _account) private {
        claimed[_merkleRoot][_account] = true;
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override whenNotPaused nonReentrant {
        require(
            !account.isContract(),
            "MerkleDistributor: Smart contract claims not allowed."
        );
        require(
            block.timestamp <= endTimestamp,
            "MerkleDistributor: Too late to claim."
        );
        require(
            !isClaimed(account),
            "MerkleDistributor: Drop already claimed."
        );

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        // Mark it claimed and send the token.
        _setClaimed(merkleRoot, account);
        IERC20Upgradeable(token).safeTransfer(account, amount);

        emit Claimed(merkleRoot, index, account, amount);
    }

    /**
     * @notice Transfer tokens back
     */
    function withdrawTokenRewards() external override onlyOwner {
        require(
            block.timestamp > (endTimestamp + 1 days),
            "Owner: Too early to remove rewards."
        );
        uint256 balanceToWithdraw = IERC20Upgradeable(token).balanceOf(
            address(this)
        );
        IERC20Upgradeable(token).safeTransfer(TREASURY, balanceToWithdraw);

        emit TokensWithdrawn(balanceToWithdraw);
    }
}
