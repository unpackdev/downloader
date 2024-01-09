// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

import "./OrderTypes.sol";
import "./SignatureChecker.sol";

/**
 * @title LooksRareAirdrop
 * @notice It distributes LOOKS tokens with a Merkle-tree airdrop.
 */
contract LooksRareAirdrop is Pausable, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using OrderTypes for OrderTypes.MakerOrder;

    IERC20 public immutable looksRareToken;

    address public immutable MAIN_STRATEGY;
    address public immutable TRANSFER_MANAGER_ERC721;
    address public immutable TRANSFER_MANAGER_ERC1155;
    address public immutable WETH;

    bytes32 public immutable DOMAIN_SEPARATOR_EXCHANGE;

    uint256 public immutable MAXIMUM_AMOUNT_TO_CLAIM;

    bool public isMerkleRootSet;

    bytes32 public merkleRoot;

    uint256 public endTimestamp;

    mapping(address => bool) public hasClaimed;

    event AirdropRewardsClaim(address indexed user, uint256 amount);
    event MerkleRootSet(bytes32 merkleRoot);
    event NewEndTimestamp(uint256 endTimestamp);
    event TokensWithdrawn(uint256 amount);

    /**
     * @notice Constructor
     * @param _endTimestamp end timestamp for claiming
     * @param _looksRareToken address of the LooksRare token
     * @param _domainSeparator domain separator for LooksRare exchange
     * @param _transferManagerERC721 address of the transfer manager for ERC721 for LooksRare exchange
     * @param _transferManagerERC1155 address of the transfer manager for ERC1155 for LooksRare exchange
     * @param _mainStrategy main strategy ("StandardSaleForFixedPrice")
     * @param _weth wrapped ETH address
     * @param _maximumAmountToClaim maximum amount to claim per a user
     */
    constructor(
        uint256 _endTimestamp,
        uint256 _maximumAmountToClaim,
        address _looksRareToken,
        bytes32 _domainSeparator,
        address _transferManagerERC721,
        address _transferManagerERC1155,
        address _mainStrategy,
        address _weth
    ) {
        endTimestamp = _endTimestamp;
        MAXIMUM_AMOUNT_TO_CLAIM = _maximumAmountToClaim;

        looksRareToken = IERC20(_looksRareToken);

        DOMAIN_SEPARATOR_EXCHANGE = _domainSeparator;
        TRANSFER_MANAGER_ERC721 = _transferManagerERC721;
        TRANSFER_MANAGER_ERC1155 = _transferManagerERC1155;

        MAIN_STRATEGY = _mainStrategy;
        WETH = _weth;
    }

    /**
     * @notice Claim tokens for airdrop
     * @param amount amount to claim for the airdrop
     * @param merkleProof array containing the merkle proof
     * @param makerAsk makerAsk order
     * @param isERC721 whether the order is for ERC721 (true --> ERC721/ false --> ERC1155)
     */
    function claim(
        uint256 amount,
        bytes32[] calldata merkleProof,
        OrderTypes.MakerOrder calldata makerAsk,
        bool isERC721
    ) external whenNotPaused nonReentrant {
        require(isMerkleRootSet, "Airdrop: Merkle root not set");
        require(amount <= MAXIMUM_AMOUNT_TO_CLAIM, "Airdrop: Amount too high");
        require(block.timestamp <= endTimestamp, "Airdrop: Too late to claim");

        // Verify the user has claimed
        require(!hasClaimed[msg.sender], "Airdrop: Already claimed");

        // Checks on orders
        require(_isOrderMatchingRequirements(makerAsk), "Airdrop: Order not eligible for airdrop");

        // Compute the hash
        bytes32 askHash = makerAsk.hash();

        // Verify signature is legit
        require(
            SignatureChecker.verify(
                askHash,
                makerAsk.signer,
                makerAsk.v,
                makerAsk.r,
                makerAsk.s,
                DOMAIN_SEPARATOR_EXCHANGE
            ),
            "Airdrop: Signature invalid"
        );

        // Verify tokens are approved
        if (isERC721) {
            require(
                IERC721(makerAsk.collection).isApprovedForAll(msg.sender, TRANSFER_MANAGER_ERC721),
                "Airdrop: Collection must be approved"
            );
        } else {
            require(
                IERC1155(makerAsk.collection).isApprovedForAll(msg.sender, TRANSFER_MANAGER_ERC1155),
                "Airdrop: Collection must be approved"
            );
        }

        // Compute the node and verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "Airdrop: Invalid proof");

        // Set as claimed
        hasClaimed[msg.sender] = true;

        // Transfer tokens
        looksRareToken.safeTransfer(msg.sender, amount);

        emit AirdropRewardsClaim(msg.sender, amount);
    }

    /**
     * @notice Check whether it is possible to claim (it doesn't check orders)
     * @param user address of the user
     * @param amount amount to claim
     * @param merkleProof array containing the merkle proof
     */
    function canClaim(
        address user,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
        if (block.timestamp <= endTimestamp) {
            // Compute the node and verify the merkle proof
            bytes32 node = keccak256(abi.encodePacked(user, amount));
            return MerkleProof.verify(merkleProof, merkleRoot, node);
        } else {
            return false;
        }
    }

    /**
     * @notice Pause airdrop
     */
    function pauseAirdrop() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Set merkle root for airdrop
     * @param _merkleRoot merkle root
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        require(!isMerkleRootSet, "Owner: Merkle root already set");

        isMerkleRootSet = true;
        merkleRoot = _merkleRoot;

        emit MerkleRootSet(_merkleRoot);
    }

    /**
     * @notice Unpause airdrop
     */
    function unpauseAirdrop() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Update end timestamp
     * @param newEndTimestamp new endtimestamp
     * @dev Must be within 30 days
     */
    function updateEndTimestamp(uint256 newEndTimestamp) external onlyOwner {
        require(block.timestamp + 30 days > newEndTimestamp, "Owner: New timestamp too far");
        endTimestamp = newEndTimestamp;

        emit NewEndTimestamp(newEndTimestamp);
    }

    /**
     * @notice Transfer tokens back to owner
     */
    function withdrawTokenRewards() external onlyOwner {
        require(block.timestamp > (endTimestamp + 1 days), "Owner: Too early to remove rewards");
        uint256 balanceToWithdraw = looksRareToken.balanceOf(address(this));
        looksRareToken.safeTransfer(msg.sender, balanceToWithdraw);

        emit TokensWithdrawn(balanceToWithdraw);
    }

    /**
     * @notice Check whether order is matching requirements for airdrop
     * @param makerAsk makerAsk order
     */
    function _isOrderMatchingRequirements(OrderTypes.MakerOrder calldata makerAsk) internal view returns (bool) {
        return
            (makerAsk.isOrderAsk) &&
            (makerAsk.signer == msg.sender) &&
            (makerAsk.amount > 0) &&
            (makerAsk.currency == WETH) &&
            (makerAsk.strategy == MAIN_STRATEGY);
    }
}
