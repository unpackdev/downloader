// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openzeppelin
import "./Ownable2StepUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./MerkleProofUpgradeable.sol";

// Interfaces
import "./IOriginsNFT.sol";

// Errors
error FailedToBuyNFT(uint8 errorCode);
error InvalidConversion();
error InvalidWithdrawAmount();
error ZeroAddress();

// Error codes
// 0: Already bought
// 1: Invalid signature
// 2: Outside of allowed minting window
// 3: Invalid merkle proof
// 4: Reached to mint limit

/**
 * @title MarketManager
 * @dev Primary Sale Market Manager for Origins & Ancestries: Genesis Collection
 * @author Amberfi
 */
contract MarketManager is
    Initializable,
    IERC721ReceiverUpgradeable,
    ReentrancyGuardUpgradeable,
    Ownable2StepUpgradeable,
    PausableUpgradeable,
    EIP712Upgradeable
{
    struct TokenInfoParams {
        uint256 tokenId;
        address[] revenueSplitUsers;
        uint256[] revenueSplitPercentages;
    }

    struct MintInfoParams {
        uint48 userMintLimit;
        uint112 userStartTime;
        uint112 userEndTime;
    }

    bytes32 private constant _TYPEHASH =
        keccak256(
            "BuyNFT(address buyer,uint256 price,uint256 tokenId,address[] revenueSplitUsers,uint256[] revenueSplitPercentages)"
        );
    IOriginsNFT private _originsNFT;
    address private _trustedSigner;
    bool private _allowPublicSale;
    uint256 private _mintLimitPublicSale;
    mapping(uint256 => bool) private _tokensSold;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public MERKLE_ROOT;
    bytes32 public PHASE_STEP;
    mapping(address => bytes32) public userMintPhase;
    mapping(address => uint256) public userMintCount;

    // Events
    event OriginsNFTChanged(
        address indexed previousContract,
        address indexed newContract
    ); // Event emitted when Origins NFT contract changed
    event TrustedSignerChanged(
        address indexed previousSigner,
        address indexed newSigner
    ); // Event emitted when trusted signer changed
    event BoughtNFT(
        uint256 tokenId,
        address indexed buyer,
        uint256 paymentAmount
    ); // Event emitted when user bought NFT
    event WithdrawnETH(uint256 tokenId); // Event emitted when withdraw ETH
    event WithdrawnTokens(address indexed token, uint256 tokenId); // Event emitted when withdraw tokens

    /**
     * @dev Initializes the contract with the given OriginsNFT address and trusted signer.
     *
     * @param originsNFT_ The address of the OriginsNFT contract.
     * @param trustedSigner_ The address of the trusted signer.
     */
    function initialize(
        address originsNFT_,
        address trustedSigner_
    ) external initializer {
        __Ownable2Step_init();
        __EIP712_init("MarketManager", "1");
        setOriginsNFT(originsNFT_);
        setTrustedSigner(trustedSigner_);

        DOMAIN_SEPARATOR = _domainSeparatorV4();
    }

    /**
     * @dev Pauses all transactions on the contract.
     *
     * Requirements:
     * - The caller must be the owner of the contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing transactions.
     *
     * Requirements:
     * - The caller must be the owner of the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows a user to buy an NFT given a valid signature and a valid Merkle proof.
     *
     * @param tokenInfoParams_ Token-related parameters:
     *        tokenId (uint256) - The ID of the token to buy.
     *        revenueSplitUsers (address[] calldata) - Addresses to receive a portion of the revenue.
     *        revenueSplitPercentages (uint256[] calldata) - Corresponding percentages of revenue distribution for the provided addresses.
     *
     * @param mintInfoParams_ User-related parameters for minting:
     *        userMintLimit (uint256) - Maximum amount of tokens a user can mint.
     *        userStartTime (uint256) - Start timestamp when the user can begin minting.
     *        userEndTime (uint256) - End timestamp after which the user cannot mint.
     *        merkleProof (bytes32[] calldata) - Merkle proof corresponding to the user's minting allowance.
     *
     * @param signature_ (bytes calldata) - A valid signature to authorize the purchase.
     *
     * Requirements:
     * - Contract must not be paused.
     * - Provided signature must be valid.
     * - Provided merkle proof must be valid.
     * - User's minting time window must be valid.
     */
    function buyNFT(
        TokenInfoParams calldata tokenInfoParams_,
        bytes calldata signature_,
        MintInfoParams calldata mintInfoParams_,
        bytes32[] calldata merkleProof_
    ) external payable nonReentrant whenNotPaused {
        if (_tokensSold[tokenInfoParams_.tokenId]) {
            revert FailedToBuyNFT(0);
        }

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        _TYPEHASH,
                        msg.sender,
                        msg.value,
                        tokenInfoParams_.tokenId,
                        keccak256(
                            abi.encodePacked(tokenInfoParams_.revenueSplitUsers)
                        ),
                        keccak256(
                            abi.encodePacked(
                                tokenInfoParams_.revenueSplitPercentages
                            )
                        )
                    )
                )
            )
        );

        if (
            ecrecover(
                digest,
                uint8(signature_[64]),
                _bytesToBytes32(_sliceBytes(signature_, 0, 32)),
                _bytesToBytes32(_sliceBytes(signature_, 32, 32))
            ) != _trustedSigner
        ) {
            revert FailedToBuyNFT(1);
        }

        if (
            block.timestamp < mintInfoParams_.userStartTime ||
            block.timestamp > mintInfoParams_.userEndTime
        ) {
            revert FailedToBuyNFT(2);
        }

        if (!_allowPublicSale) {
            bytes32 leaf = keccak256(
                bytes.concat(
                    keccak256(
                        abi.encode(
                            msg.sender,
                            mintInfoParams_.userMintLimit,
                            mintInfoParams_.userStartTime,
                            mintInfoParams_.userEndTime
                        )
                    )
                )
            );

            if (
                !MerkleProofUpgradeable.verify(merkleProof_, MERKLE_ROOT, leaf)
            ) {
                revert FailedToBuyNFT(3);
            }

            uint256 userCurrentMintCount = (userMintPhase[msg.sender] ==
                PHASE_STEP)
                ? userMintCount[msg.sender]
                : 0;
            if (userCurrentMintCount >= mintInfoParams_.userMintLimit) {
                revert FailedToBuyNFT(4);
            }

            userMintCount[msg.sender] = userCurrentMintCount + 1;
            userMintPhase[msg.sender] = PHASE_STEP;
        } else {
            uint256 userCurrentMintCount = (userMintPhase[msg.sender] ==
                PHASE_STEP)
                ? userMintCount[msg.sender]
                : 0;
            if (userCurrentMintCount >= _mintLimitPublicSale) {
                revert FailedToBuyNFT(4);
            }

            userMintCount[msg.sender] = userCurrentMintCount + 1;
            userMintPhase[msg.sender] = PHASE_STEP;
        }

        _tokensSold[tokenInfoParams_.tokenId] = true;

        unchecked {
            if (msg.value > 0) {
                uint256 revenueLength = tokenInfoParams_
                    .revenueSplitUsers
                    .length;
                for (uint256 i; i < revenueLength; ++i) {
                    address user = tokenInfoParams_.revenueSplitUsers[i];
                    uint256 splitAmount = (msg.value *
                        tokenInfoParams_.revenueSplitPercentages[i]) / 10000;
                    payable(user).transfer(splitAmount);
                }
            }
        }

        _originsNFT.mint(msg.sender, tokenInfoParams_.tokenId);

        emit BoughtNFT(tokenInfoParams_.tokenId, msg.sender, msg.value);
    }

    /**
     * @dev Allows the owner to withdraw a specified amount of Ether from the contract.
     *
     * @param amount_ (uint256) Amount of Ether in wei to be withdrawn.
     *
     * Requirements:
     * - The caller must be the owner of the contract.
     * - Amount must be less than or equal to the contract's Ether balance.
     */
    function withdrawETH(uint256 amount_) external nonReentrant onlyOwner {
        if (amount_ > address(this).balance) {
            revert InvalidWithdrawAmount();
        }

        payable(address(msg.sender)).transfer(amount_);

        emit WithdrawnETH(amount_);
    }

    /**
     * @dev Allows the owner to withdraw a specified amount of a token from the contract.
     *
     * @param token_ (address) The address of the token to be withdrawn.
     * @param amount_ (uint256) The amount of tokens to be withdrawn.
     *
     * Requirements:
     * - The caller must be the owner of the contract.
     * - Amount must be less than or equal to the contract's token balance for the specified token.
     */
    function withdrawTokens(
        address token_,
        uint256 amount_
    ) external nonReentrant onlyOwner {
        uint256 contractBalance = IERC20Upgradeable(token_).balanceOf(
            address(this)
        );
        if (amount_ > contractBalance) {
            revert InvalidWithdrawAmount();
        }

        IERC20Upgradeable(token_).transfer(msg.sender, amount_);

        emit WithdrawnTokens(token_, amount_);
    }

    /**
     * @dev Sets the contract address for the OriginsNFT.
     *
     * Emits an {OriginsNFTChanged} event indicating the previous contract and the newly set contract.
     *
     * Requirements:
     * - The provided address must not be the zero address.
     *
     * @param originsNFT_ (address) The address of the OriginsNFT contract.
     */
    function setOriginsNFT(address originsNFT_) public onlyOwner {
        if (originsNFT_ == address(0)) {
            revert ZeroAddress();
        }
        IOriginsNFT prev = _originsNFT;
        _originsNFT = IOriginsNFT(originsNFT_);

        emit OriginsNFTChanged(address(prev), originsNFT_);
    }

    /**
     * @dev Sets the trusted signer's address for validating buy orders.
     *
     * Emits a {TrustedSignerChanged} event indicating the previous signer and the newly set signer.
     *
     * Requirements:
     * - The provided address must not be the zero address.
     *
     * @param trustedSigner_ (address) The address of the trusted signer.
     */
    function setTrustedSigner(address trustedSigner_) public onlyOwner {
        if (trustedSigner_ == address(0)) {
            revert ZeroAddress();
        }
        address prev = _trustedSigner;
        _trustedSigner = trustedSigner_;

        emit TrustedSignerChanged(prev, trustedSigner_);
    }

    /**
     * @notice Updates the Merkle root, phase/step, and sale configurations for the contract.
     *
     * @dev Allows the owner to set a new Merkle root, phase, and step for the drop, as well as
     * configure the public sale settings. The Merkle root represents the root of a Merkle tree,
     * which is constructed from the list of eligible users along with their specific minting limits
     * and timeframes.
     *
     * Requirements:
     * - The caller must be the owner of the contract.
     *
     * @param merkleRoot_ (bytes32) The new Merkle root for minting validation.
     * @param phaseStep_ (bytes32) The new phase and step identifier for the drop.
     * @param allowPublicSale_ (bool) A flag to indicate if public sale is allowed.
     * @param mintLimitPublicSale_ (uint256) The mint limit for the public sale.
     */
    function setMerkleRoot(
        bytes32 merkleRoot_,
        bytes32 phaseStep_,
        bool allowPublicSale_,
        uint256 mintLimitPublicSale_
    ) external onlyOwner {
        MERKLE_ROOT = merkleRoot_;
        PHASE_STEP = phaseStep_;
        _allowPublicSale = allowPublicSale_;
        _mintLimitPublicSale = mintLimitPublicSale_;
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    /**
     * @dev Extracts a slice from the provided bytes array.
     *
     * @param bytes_ (bytes memory) The bytes array from which to extract the slice.
     * @param start_ (uint256) The starting position of the slice.
     * @param length_ (uint256)The length of the slice.
     * @return (bytes memory) Returns the slice from the bytes array.
     */
    function _sliceBytes(
        bytes memory bytes_,
        uint256 start_,
        uint256 length_
    ) internal pure returns (bytes memory) {
        bytes memory data = new bytes(length_);
        for (uint256 i; i < length_; ) {
            data[i] = bytes_[start_ + i];
            unchecked {
                ++i;
            }
        }
        return data;
    }

    /**
     * @dev Converts a bytes memory array to a bytes32 variable.
     *
     * Requirements:
     * - The provided bytes array must be at least 32 bytes long.
     *
     * @param bytes_ (bytes memory) The bytes array to be converted.
     * @return data (bytes32) Returns the bytes32 representation of the provided bytes array.
     */
    function _bytesToBytes32(
        bytes memory bytes_
    ) internal pure returns (bytes32 data) {
        if (bytes_.length < 32) {
            revert InvalidConversion();
        }
        assembly {
            data := mload(add(bytes_, 32))
        }
    }
}
