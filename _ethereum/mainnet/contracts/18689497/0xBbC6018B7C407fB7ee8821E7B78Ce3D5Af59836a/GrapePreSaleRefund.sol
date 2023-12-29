// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Pausable.sol";
import "./BitMaps.sol";
import "./GrapePreSale.sol";

contract GrapePreSaleRefund is Ownable, Pausable {
    /// @dev Library for managing uint256 to bool mapping in a compact and efficient way
    using BitMaps for BitMaps.BitMap;

    /// @notice Merkle root of wallets that DID NOT win in the raffle
    bytes32 public refundMerkleRoot;

    /// @notice The GrapePreSale contract
    GrapePreSale public immutable grapePreSale;

    /// @dev Wallets that already claimed their refund
    BitMaps.BitMap private _refundedWallets;

    /// @notice Emitted when a refund is claimed
    event RefundClaimed(address indexed wallet, uint256 amount);

    /// @notice Returned when the wallet is already refunded
    error AlreadyRefunded();

    /// @notice Returned when the wallet did not participate in the pre-sale
    error NothingToRefund();

    /// @notice Returned when the provided merkle proof is invalid or the merkle root is not set
    error InvalidMerkleProof();

    /// @notice Returned when the transfer of the refund failed, mostly due because this contract doesn't have enough ETH
    error RefundFailed();

    /// @notice Returned when the refund Merkle root is already set
    error RefundMerkleRootAlreadySet();

    /// @notice Returned when the withdraw all ETH fails
    error WithdrawAllFailed();

    /// @notice Initializes the contract with a given owner.
    /// @dev The constructor sets the initial owner, then puts the contract into a paused state.
    ///      It inherits from the Ownable contract using the provided initial owner.
    /// @param initialOwner_ The address of the initial owner of the contract.
    /// @param grapePreSale_ The address of the pre-sale contract.
    constructor(
        address initialOwner_,
        address grapePreSale_
    ) Ownable(initialOwner_) {
        grapePreSale = GrapePreSale(grapePreSale_);

        // default to paused
        _pause();
    }

    /// @notice This function allows users to claim a refund based on a valid Merkle proof.
    /// @dev The function first verifies the Merkle proof, checks if the wallet has already collected the refund,
    ///      and then processes the refund to prevent reentrancy attacks. It interacts with the `GrapePreSale` contract.
    /// @param merkleProof_ An array of bytes32, the Merkle Proof
    function claimRefund(
        bytes32[] calldata merkleProof_
    ) external whenNotPaused {
        // verify referral code is valid
        if (!verifyMerkleProof(msg.sender, merkleProof_))
            revert InvalidMerkleProof();

        // check if the wallet has already collected
        if (_refundedWallets.get(uint160(msg.sender))) revert AlreadyRefunded();

        // log as claimed before paying to prevent reentrancy attacks
        _refundedWallets.set(uint160(msg.sender));

        // get amount to be refunded
        uint256 refundAmount = grapePreSale.referralPurchases(msg.sender);

        // check if the wallet participated in the pre-sale
        if (refundAmount == 0) revert NothingToRefund();

        // emit refund claimed event
        emit RefundClaimed(msg.sender, refundAmount);

        // transfer refund
        (bool sent, ) = payable(msg.sender).call{value: refundAmount}('');

        // check transfer was successful
        if (!sent) revert RefundFailed();
    }

    /// @notice Verifies if a given referral code is valid for a specific wallet address.
    /// @dev Uses a Merkle proof to verify if the provided referral code is part of the Merkle tree
    ///      represented by the referralCodeMerkleRoot. This is used to validate the authenticity of the referral codes.
    /// @param wallet_ The address of the wallet for which the referral code is being verified.
    /// @param merkleProof_ Merkle Proof to check against.
    /// @return bool True if the referral code is valid for the given wallet address, false otherwise.
    function verifyMerkleProof(
        address wallet_,
        bytes32[] calldata merkleProof_
    ) public view returns (bool) {
        // check refundMerkleRoot is set
        if (refundMerkleRoot == bytes32(0)) return false;

        return
            MerkleProof.verify(
                merkleProof_,
                refundMerkleRoot,
                keccak256(bytes.concat(keccak256(abi.encode(wallet_))))
            );
    }

    /// @notice Pause the purchase functions, only owner can call this function
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the purchase functions, only owner can call this function
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Withdraw all ETH from the contract. Only owner can execute this function.
    /// @param to_ The address to send the ETH to.
    function withdrawAll(address payable to_) external onlyOwner {
        (bool sent, ) = to_.call{value: address(this).balance}('');
        if (!sent) revert WithdrawAllFailed();
    }

    /// @notice Set the refund Merkle root. Only owner can execute this function.
    /// @param refundMerkleRoot_ The Merkle root used for verifying refund wallets.
    function setRefundMerkleRoot(bytes32 refundMerkleRoot_) external onlyOwner {
        // prevent setting the Merkle root if already set
        if (refundMerkleRoot != bytes32(0)) revert RefundMerkleRootAlreadySet();

        refundMerkleRoot = refundMerkleRoot_;
    }

    /// @notice Function to allow contract to receive ETH
    receive() external payable {}
}
