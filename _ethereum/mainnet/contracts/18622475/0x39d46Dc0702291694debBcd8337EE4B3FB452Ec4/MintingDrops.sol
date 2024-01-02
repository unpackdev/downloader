// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC11554KController.sol";
import "./IERC11554KDrops.sol";
import "./IGuardians.sol";

/**
 * @dev MintingDrops manages minting drops for a collection.
 */
contract MintingDrops is Ownable {
    using SafeERC20 for IERC20;

    /// @notice Minting Drops types
    enum DropType {
        /// @notice ERC-721 (ERC-1155 with each id having single item) random minting drop
        NFT,
        /// @notice Users choose set of items and randomly mint items in each set
        SEMI,
        /// @notice Users choose which item to mint
        DETERMINED
    }

    /// @notice Is minting drop private or public.
    bool public immutable isPrivate;
    /// @notice Collection contract.
    IERC11554KDrops public immutable collection;
    /// @notice Controller contract.
    IERC11554KController public immutable controller;
    /// @notice Maximum number of items, independant of id, per user.
    uint256 public immutable maxItemsPerUser;
    /// @notice Maximum items to mint per ID for collection.
    uint256 public immutable maxItemsPerID;
    /// @notice Maximum items to mint in the drop.
    uint256 public immutable maxItems;
    /// @notice A pre-set amount of guardian fee that each item would have.
    uint256 public immutable guardianFeeAmountPerItem;
    /// @notice A pre-set guardian class index where items will be stored.
    uint256 public immutable guardianClassIndex;
    /// @notice A pre-set amount of service fee that each item's minting will provide.
    uint256 public immutable serviceFeePerItem;
    /// @notice Items variations in case of non-NFT drop.
    uint256 public immutable variations;
    /// @notice Drop type.
    DropType public immutable dropType;
    /// @notice Guardian that vaults items during drop.
    address public immutable managingGuardian;
    /// @notice Allowlist merkle root for checking if user in allowlist or not.
    bytes32 public allowlistMerkleRoot;
    /// @notice Minted items.
    uint256 public mintedItems;
    /// @notice ETH drop minting fee.
    uint256 public dropFee;
    /// @notice Minting Drop start time. Can only be set once.
    uint256 public startTime;
    /// @notice Minting Drop end time. Can only be set once.
    uint256 public endTime;
    /// @notice Which user owns item with URI ID
    mapping(uint256 => address) public uriIDUser;
    /// @notice Items minted for each URI ID.
    mapping(uint256 => uint256) public itemsIDMinted;
    /// @notice Mapped URI IDs to collection item IDs.
    mapping(uint256 => uint256) public uriIDItemID;
    /// @notice How many items a user has minted.
    mapping(address => uint256) public itemsPerUser;

    /// @notice Helper initial state of URI ids for NFT random minting drop
    uint256[] public helperIdsList;
    /// @notice Items classes variations prefix sums. i-th element is sum of classes variations from 0-th to i-th.
    uint256[] public prefixSumsVariations;

    /// @notice Minted drop
    event MintedDrop(
        uint256 id,
        uint256 randomUriID,
        uint256 amount,
        address minter
    );

    error AccessDenied();
    error NotPrivate();
    error EqualItems();
    error InvalidAmount();
    error AlreadySet();
    error MintingLimitExceeded();
    error UserMintingLimitExceeded();
    error AlreadyMinted();
    error ETHTransferFailed();
    error LowSentETH();
    error NotNFTDrop();
    error NotSEMIDrop();
    error NotManagingGuardian();
    error NotStarted();
    error InvalidItemID();
    error HasEnded();

    /**
     * @dev Only guardian modifier.
     */
    modifier onlyManagingGuardian() {
        if (managingGuardian != _msgSender()) {
            revert NotManagingGuardian();
        }
        _;
    }

    constructor(
        IERC11554KController controller_,
        IERC11554KDrops collection_,
        bool isPrivate_,
        uint256 maxItemsPerUser_,
        uint256 maxItemsPerID_,
        uint256 maxItems_,
        uint256 variations_,
        address managingGuardian_,
        DropType dropType_,
        uint256 serviceFeePerItem_,
        uint256 guardianFeeAmountPerItem_,
        uint256 guardianClassIndex_
    ) {
        controller = controller_;
        collection = collection_;
        isPrivate = isPrivate_;
        maxItemsPerUser = maxItemsPerUser_;
        maxItemsPerID = maxItemsPerID_;
        maxItems = maxItems_;
        variations = variations_;
        managingGuardian = managingGuardian_;
        dropType = dropType_;
        serviceFeePerItem = serviceFeePerItem_;
        guardianFeeAmountPerItem = guardianFeeAmountPerItem_;
        guardianClassIndex = guardianClassIndex_;
        controller_.paymentToken().approve(
            address(controller_),
            type(uint256).max
        );
        controller_.paymentToken().approve(
            IGuardians(controller_.guardians()).feesManager(),
            type(uint256).max
        );
    }

    /**
     * @notice Fallback ETH receive function.
     */
    receive() external payable {}

    /**
     * @notice Withdraws ETH to receiver.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param amount ETH amount to withdraw.
     * @param receiver address to send ETH.
     */
    function withdrawEther(
        uint256 amount,
        address payable receiver
    ) external payable onlyOwner {
        (bool success, ) = receiver.call{value: amount}(""); // solhint-disable-line avoid-low-level-calls
        if (!success) {
            revert ETHTransferFailed();
        }
    }

    /**
     * @notice Withdraws payment token asset to receiver.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param amount ETH amount to withdraw.
     * @param receiver address to send ETH.
     */
    function withdrawPaymentToken(
        uint256 amount,
        address receiver
    ) external payable onlyOwner {
        IERC20(address(controller.paymentToken())).safeTransfer(
            receiver,
            amount
        );
    }

    /**
     * @notice Sets helper ids list for NFT random drop. Can do it only once.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     */
    function setHelperIdsList() external onlyOwner {
        if (helperIdsList.length > 0) {
            revert AlreadySet();
        }
        if (dropType != DropType.NFT) {
            revert NotNFTDrop();
        }
        uint256 maxItems_ = maxItems;
        for (uint256 i = 1; i <= maxItems_; ++i) {
            helperIdsList.push(i);
        }
    }

    /**
     * @notice Sets items classes variations if they are different by class in case of SEMI drop.
     * Calculates prefix sums of classes variations to later on derive exact URI ID of an item.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * 2) Variations list length must be a number of classes.
     */
    function setClassesVariations(
        uint256[] calldata variationsList
    ) external onlyOwner {
        if (prefixSumsVariations.length > 0) {
            revert AlreadySet();
        }
        if (dropType != DropType.SEMI) {
            revert NotSEMIDrop();
        }
        for (uint256 i = 0; i < variationsList.length; ++i) {
            // Calculate next prefix variations sum of first i claases by taking (i-1)-th prefix sum and adding i-th variations.
            prefixSumsVariations.push(
                (i > 0 ? prefixSumsVariations[i - 1] : 0) + variationsList[i]
            );
        }
    }

    /**
     * @notice Sets dropFee to dropFee_.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param dropFee_ New drops fee
     */
    function setDropFee(uint256 dropFee_) external onlyOwner {
        dropFee = dropFee_;
    }

    /**
     * @notice Sets startTime to startTime_.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param startTime_ New start time
     */
    function setStartTime(uint256 startTime_) external onlyOwner {
        if (startTime != 0) {
            revert AlreadySet();
        }
        startTime = startTime_;
    }

    /**
     * @notice Sets endTime to endTime_.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param endTime_ New end time
     */
    function setEndTime(uint256 endTime_) external onlyOwner {
        if (endTime != 0) {
            revert AlreadySet();
        }
        endTime = endTime_;
    }

    /**
     * @notice Sets allowlist root if drop is private
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param allowlistMerkleRoot_ Allowlist merkle root
     */
    function setAllowlistMerkleRoot(
        bytes32 allowlistMerkleRoot_
    ) external onlyOwner {
        if (!isPrivate) {
            revert NotPrivate();
        }
        allowlistMerkleRoot = allowlistMerkleRoot_;
    }

    /**
     * @notice Sets collection status to vaulted.
     *
     * Requirements:
     *
     * 1) The caller must be a managing guardian.
     **/
    function setVaulted() external virtual onlyManagingGuardian {
        collection.setVaulted();
    }

    /**
     * @notice Does minting drop for user based on IERC11554KController requestMint.
     *
     * Requirements:
     *
     * 1) Must satisfy all controller.requestMint() and controller.mint() conditions
     * 2) Sender should be in allowlist if the drop is private.
     * 3) Amount items to mint cannot exceed maxItemsPerMint.
     * 4) Must send enough ETH to cover dropFee * amount and to cover all additional fees
     * @param amount Amount of items to mint.
     * @param itemId If minting drop allows users to mint to any id then just means URI item id (regardless of whether we have variations or not),
     * in case of semi-random items sets with variations allows to mint to specific items class. If its random NFT minting then fully ignored.
     * @param allowlistProof, merkle proof list of user inclusing in drop allowlist, used if drop is private.
     * @return id
     */
    function mint(
        uint256 amount,
        uint256 itemId,
        bytes32[] calldata allowlistProof
    ) external payable virtual returns (uint256 id, uint256 uriID) {
        if (startTime != 0 && startTime > block.timestamp) {
            revert NotStarted();
        }
        if (endTime != 0 && endTime < block.timestamp) {
            revert HasEnded();
        }
        if (
            isPrivate &&
            !MerkleProof.verifyCalldata(
                allowlistProof,
                allowlistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) {
            revert AccessDenied();
        }
        if (amount > 1 && dropType == DropType.NFT) {
            revert InvalidAmount();
        }

        if (itemsPerUser[msg.sender] + amount > maxItemsPerUser) {
            revert UserMintingLimitExceeded();
        }

        if (mintedItems + amount > maxItems) {
            revert MintingLimitExceeded();
        }
        if (msg.value != dropFee * amount) {
            revert LowSentETH();
        }
        if (
            dropType == DropType.SEMI &&
            prefixSumsVariations.length > 0 &&
            itemId > prefixSumsVariations.length
        ) {
            revert InvalidItemID();
        }
        if (dropType == DropType.DETERMINED) {
            uriID = itemId;
        } else {
            if (dropType == DropType.NFT) {
                uint256 curHelperLen = helperIdsList.length - mintedItems;
                uriID = uint256(blockhash(block.number)) % curHelperLen;
                uint256 realIDValue = helperIdsList[uriID];
                if (curHelperLen > 1) {
                    helperIdsList[uriID] = helperIdsList[curHelperLen - 1];
                    helperIdsList[curHelperLen - 1] = realIDValue;
                }
                uriID = realIDValue;
            } else {
                // 2 cases, if variations are different per class or if they are equal "variations".
                if (prefixSumsVariations.length > 0) {
                    // Take previous class variations (itemIds are numbered from 1 instead of 0, so substract -1 additionally everywhere).
                    uint256 prevClassVariations = (
                        itemId > 1 ? prefixSumsVariations[itemId - 2] : 0
                    );
                    // Calculate random variation for class itemId.
                    // URI IDs start from prefixSumsVariations[itemId - 2] + 1 until prefixSumsVariations[itemId - 1].
                    // So we need to have a random number in range from [0; prefixSumsVariations[itemId - 1] - prefixSumsVariations[itemId - 2] - 1].
                    uriID =
                        uint256(blockhash(block.number)) %
                        (prefixSumsVariations[itemId - 1] -
                            prevClassVariations);
                    // Add up URI IDs shift for itemId class.
                    uriID += prevClassVariations + 1;
                } else {
                    uriID = uint256(blockhash(block.number)) % variations;
                    uriID += variations * (itemId - 1) + 1;
                }
            }
        }
        if (itemsIDMinted[uriID] + amount > maxItemsPerID) {
            revert MintingLimitExceeded();
        }
        mintedItems += amount; //total items overall
        itemsPerUser[msg.sender] += amount; //total items per user
        itemsIDMinted[uriID] += amount; //total items per id
        id = controller.requestMint(
            collection,
            dropType == DropType.NFT ? 0 : uriIDItemID[uriID], // If dropType is NFT drop then mint new item, otherwise take mapped URI ID to actual collection item id.
            managingGuardian,
            amount,
            serviceFeePerItem * amount,
            dropType == DropType.NFT ? false : true,
            msg.sender,
            guardianClassIndex,
            guardianFeeAmountPerItem * amount
        );
        // If drop type is not NFT type then map URI ID to collection item id.
        if (dropType != DropType.NFT && uriIDItemID[uriID] == 0) {
            uriIDItemID[uriID] = id;
        }
        controller.mint(collection, id);
        collection.setItemUriID(id, uriID);
        emit MintedDrop(id, uriID, amount, msg.sender);
    }
}
