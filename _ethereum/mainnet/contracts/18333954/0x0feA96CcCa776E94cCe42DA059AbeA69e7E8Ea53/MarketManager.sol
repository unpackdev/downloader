// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openzeppelin
import "./Ownable2StepUpgradeable.sol";
import "./Initializable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./EIP712Upgradeable.sol";
// Interfaces
import "./IOriginsNFT.sol";

// Errors
error FailedToBuyNFT(uint8 errorCode);
error InvalidConversion();
error InvalidWithdrawAmount();
error ZeroAddress();

/**
 * @title MarketManager
 * @dev Market Manager for OriginsNFT contract
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
    bytes32 private constant _TYPEHASH =
        keccak256(
            "BuyNFT(address buyer,uint256 price,uint256 tokenId,address[] revenueSplitUsers,uint256[] revenueSplitPercentages,address[] royaltyReceivers,uint256[] royaltyPercentages)"
        );
    IOriginsNFT private _originsNFT;
    address private _trustedSigner;
    mapping(uint256 => bool) private _tokensSold;

    bytes32 public DOMAIN_SEPARATOR;

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
     * @dev Allows a user to buy an NFT given a valid signature.
     *
     * @param tokenId_ (uint256) The ID of the token to buy.
     * @param revenueSplitUsers_ (address[] calldata) Addresses to receive a portion of the revenue.
     * @param revenueSplitPercentages_ (uint256[] calldata) Corresponding percentages of revenue distribution for the provided addresses.
     * @param royaltyReceivers_ (address[] calldata) Addresses to receive royalty.
     * @param royaltyPercentages_ (uint256[] calldata) Corresponding percentages for the provided royalty receivers.
     * @param signature_ (bytes calldata) A valid signature to authorize the purchase.
     *
     * Requirements:
     * - Contract must not be paused.
     * - Provided signature must be valid.
     */
    function buyNFT(
        uint256 tokenId_,
        address[] calldata revenueSplitUsers_,
        uint256[] calldata revenueSplitPercentages_,
        address[] calldata royaltyReceivers_,
        uint256[] calldata royaltyPercentages_,
        bytes calldata signature_
    ) external payable nonReentrant whenNotPaused {
        if (_tokensSold[tokenId_]) {
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
                        tokenId_,
                        keccak256(abi.encodePacked(revenueSplitUsers_)),
                        keccak256(abi.encodePacked(revenueSplitPercentages_)),
                        keccak256(abi.encodePacked(royaltyReceivers_)),
                        keccak256(abi.encodePacked(royaltyPercentages_))
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
            ) == _trustedSigner
        ) {
            _tokensSold[tokenId_] = true;

            uint256 remainingAmount = msg.value;

            unchecked {
                uint256 royaltyLength = royaltyReceivers_.length;
                for (uint256 i; i < royaltyLength; ++i) {
                    address receiver = royaltyReceivers_[i];
                    uint256 royaltyAmount = (msg.value *
                        royaltyPercentages_[i]) / 10000;
                    payable(receiver).transfer(royaltyAmount);
                    remainingAmount = remainingAmount - royaltyAmount;
                }
            }

            unchecked {
                uint256 revenueLength = revenueSplitUsers_.length;
                for (uint256 i; i < revenueLength; ++i) {
                    address user = revenueSplitUsers_[i];
                    uint256 splitAmount = (remainingAmount *
                        revenueSplitPercentages_[i]) / 10000;
                    payable(user).transfer(splitAmount);
                }
            }

            _originsNFT.mint(msg.sender, tokenId_);

            emit BoughtNFT(tokenId_, msg.sender, msg.value);
        } else {
            revert FailedToBuyNFT(1);
        }
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
        if (amount_ > address(this).balance) {
            revert InvalidWithdrawAmount();
        }

        payable(address(msg.sender)).transfer(amount_);

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
