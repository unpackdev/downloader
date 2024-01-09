// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "./IERC721MerkleDrop.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Reentrancy.sol";
import "./IERC721.sol";
import "./MirrorFeeConfig.sol";
import "./ITreasuryConfig.sol";
import "./IMirrorTreasury.sol";

/**
 * @title ERC721MerkleDrop
 * @author MirrorXYZ
 */
contract ERC721MerkleDrop is
    IERC721MerkleDrop,
    Ownable,
    Pausable,
    Reentrancy,
    IERC721Events
{
    /// @notice Address for factory that deploys clones
    address public immutable factory;

    /// @notice Address for Mirror's fee configuration
    address public immutable feeConfig;

    /// @notice Address for Mirror's treasury configuration
    address public immutable treasuryConfig;

    /// @notice Merkle root
    bytes32 public merkleRoot;

    /// @notice Claim deadline block
    uint256 public claimDeadline;

    /// @notice Funds recipient
    address public recipient;

    /// @notice ERC721 token address
    address public token;

    /// @notice ERC721 tokens holder
    address public tokenOwner;

    /// @notice Start token-id
    uint256 public startTokenId;

    /// @notice End token-id
    uint256 public endTokenId;

    /// @notice Current token-id
    uint256 public currentTokenId;

    /// @notice Map of claimed token hashes
    mapping(bytes32 => bool) public claimed;

    constructor(
        address factory_,
        address feeConfig_,
        address treasuryConfig_
    ) Ownable(address(0)) Pausable(true) {
        factory = factory_;
        feeConfig = feeConfig_;
        treasuryConfig = treasuryConfig_;
    }

    function initialize(
        address owner_,
        bool paused_,
        bytes32 merkleRoot_,
        uint256 claimDeadline_,
        address recipient_,
        address token_,
        address tokenOwner_,
        uint256 startTokenId_,
        uint256 endTokenId_
    ) external override {
        // ensure that this function is only callable by the factory
        require(msg.sender == factory, "unauthorized caller");

        // set owner
        _setOwner(address(0), owner_);

        // set pause status
        if (paused_) {
            _pause();
        }

        // set merkle-root
        merkleRoot = merkleRoot_;

        // set claim deadline
        claimDeadline = claimDeadline_;

        // set recipient
        recipient = recipient_;

        // set erc721 token address
        token = token_;

        // set address that owns the tokens
        tokenOwner = tokenOwner_;

        // set start and end token-ids
        startTokenId = startTokenId_;
        endTokenId = endTokenId_;

        // set currentTokenId
        currentTokenId = startTokenId_;
    }

    /// @notice Update claim deadline
    function setClaimDeadline(uint256 newClaimDeadline)
        external
        override
        onlyOwner
    {
        emit UpdateClaimDeadline(claimDeadline, newClaimDeadline);

        // set claim deadline
        claimDeadline = newClaimDeadline;
    }

    /// @notice Pause claiming
    function pause() external override onlyOwner {
        _pause();
    }

    /// @notice Unpause claiming
    function unpause() external override onlyOwner {
        _unpause();
    }

    /// @notice Cancel drop.
    /// @dev Pauses claiming, removes owner and withdraws
    function cancel(uint16 feePercentage_) external override onlyOwner {
        if (!paused) {
            _pause();
        }

        _renounceOwnership();

        _withdraw(feePercentage_);
    }

    /// @notice Number of claimed tokens
    function claimedTokens() external view override returns (uint256) {
        return currentTokenId - startTokenId;
    }

    /// @notice Claim tokens
    function claim(
        address account,
        uint256 allocation,
        uint256 price,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external payable whenNotPaused {
        // assert claim deadline has not passed
        require(block.number <= claimDeadline, "claim deadline has passed");

        // assert enough funds are sent to cover the cost
        require(price * allocation <= msg.value, "insufficient funds");

        // assert there are enough tokens left to claim allocation amount
        require(
            currentTokenId + allocation <= endTokenId + 1,
            "insufficient tokens"
        );

        // assert account has not claimed already
        require(!isClaimed(index, account), "already claimed");

        // store account claim
        _setClaimed(index, account);

        // assert proof is valid
        require(
            _verifyProof(
                merkleProof,
                merkleRoot,
                _getNode(index, price, account, allocation)
            ),
            "invalid proof"
        );

        // transfer tokens
        for (uint256 i = 0; i < allocation; i++) {
            IERC721(token).transferFrom(tokenOwner, account, currentTokenId++);
        }
    }

    function isClaimed(uint256 index, address account)
        public
        view
        returns (bool)
    {
        return claimed[_getClaimHash(index, account)];
    }

    /// @notice Withdraw funds
    function withdraw(uint16 feePercentage_) external override nonReentrant {
        _withdraw(feePercentage_);
    }

    // ============ Internal Functions ============
    function _withdraw(uint16 feePercentage_) internal {
        uint256 balance = address(this).balance;

        if (balance > 0) {
            // assert that the fee is valid
            require(
                IMirrorFeeConfig(feeConfig).isFeeValid(feePercentage_),
                "invalid fee"
            );

            // calculate the fee on the current balance, using the fee percentage
            uint256 fee = _feeAmount(balance, feePercentage_);

            // if the fee is not zero, attempt to send it to the treasury
            if (fee != 0) {
                IMirrorTreasury(ITreasuryConfig(treasuryConfig).treasury())
                    .contribute{value: fee}(fee);
            }
            // broadcast the withdrawal event – with balance and fee
            emit Withdrawal(recipient, address(this).balance, fee);

            // transfer the remaining balance to the recipient
            _sendEther(payable(recipient), address(this).balance);
        }
    }

    function _feeAmount(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / 10000;
    }

    function _sendEther(address payable recipient_, uint256 amount) internal {
        // Ensure sufficient balance.
        require(address(this).balance >= amount, "insufficient balance");
        // Send the value.
        (bool success, ) = recipient_.call{value: amount}("");
        require(success, "recipient reverted");
    }

    function _setClaimed(uint256 index, address account) internal {
        claimed[_getClaimHash(index, account)] = true;
    }

    function _getClaimHash(uint256 index, address account)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(index, account));
    }

    function _getNode(
        uint256 index,
        uint256 price,
        address account,
        uint256 allocation
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, allocation, price, index));
    }

    // From https://github.com/protofire/zeppelin-solidity/blob/master/contracts/MerkleProof.sol
    function _verifyProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}
