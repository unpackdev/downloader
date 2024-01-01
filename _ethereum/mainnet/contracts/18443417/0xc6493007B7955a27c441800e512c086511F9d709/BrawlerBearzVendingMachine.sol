// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./AccessControl.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./AccessControl.sol";
import "./ERC1155Burnable.sol";
import "./IERC1155.sol";
import "./ERC2771Context.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./NativeMetaTransaction.sol";
import "./IBrawlerBearzDynamicItems.sol";

/*******************************************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|,|@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@|,*|&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,**%@@@@@@@@%|******%&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##*****|||**,(%%%%%**|%@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@***,#%%%%**#&@@@@@#**,|@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@*,(@@@@@@@@@@**,(&@@@@#**%@@@@@@||(%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%|,****&@((@&***&@@@@@@%||||||||#%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&%#*****||||||**#%&@%%||||||||#@&%#(@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&**,(&@@@@@%|||||*##&&&&##|||||(%@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@**,%@@@@@@@(|*|#%@@@@@@@@#||#%%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#||||#@@@@||*|%@@@@@@@@&|||%%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#,,,,,,*|**||%|||||||###&@@@@@@@#|||#%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&#||*|||||%%%@%%%#|||%@@@@@@@@&(|(%&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&%%(||||@@@@@@&|||||(%&((||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%%(||||||||||#%#(|||||%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&%#######%%@@**||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
********************************************************************************/

/**************************************************
 * @title BrawlerBearzVendingMachine
 * @author @scottybmitch
 **************************************************/

contract BrawlerBearzVendingMachine is
    AccessControl,
    ERC2771Context,
    NativeMetaTransaction,
    ReentrancyGuard
{
    bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 private constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    address private constant ADDRESS_ZERO = address(0);

    struct VendingConfig {
        uint256 vendId; // Vending config id
        bool isERC721; // ERC721 or ERC1155
        address contractAddress; // Address(0) by default
        uint32 ticketItemId; // Ticket item id to burn
        uint32 tokenId; // Token id to claim
        uint64 inCount; // Tickets required
        uint64 outCount; // Typically 1
        uint64 quantity; // Amount left to vend
    }

    event CreatedVendItem(uint256 indexed vendId);

    event UpdatedVendItem(uint256 indexed vendId);

    event VendedItem(
        uint256 indexed vendId,
        address indexed requester,
        address indexed contractAddress,
        uint256 inCount,
        uint256 outCount,
        uint256 tokenId
    );

    /// @dev Running counter of the vend ids added
    uint256 public lastVendId = 0;

    /// @dev State of vending machine
    bool public isPaused = true;

    /// @dev Mapping for VendingConfig
    mapping(uint256 => VendingConfig) public vendingConfigs;

    /// @notice Vendor item contract
    IBrawlerBearzDynamicItems public vendorContract;

    constructor(
        address _vendorContractAddress,
        address _trustedForwarder
    ) ERC2771Context(_trustedForwarder) {
        // Item contract
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);
        // Contract roles
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
        _setupRole(MODERATOR_ROLE, _msgSender());
    }

    /**
     * @notice Use the vending machine
     * @dev Takes a users neo city tickets & exchanges them for an NFT based on vend id and configuration
     * @param vendId The id of the vending configuration
     */
    function vend(uint256 vendId) external nonReentrant {
        require(!isPaused, "!live");

        VendingConfig storage config = vendingConfigs[vendId];

        require(
            config.quantity > 0 && config.outCount <= config.quantity,
            "!enough"
        );

        // Decrement quantity available
        config.quantity -= config.outCount;

        address requester = _msgSender();

        // Burn ticket tokens for exchange
        vendorContract.burnItemForOwnerAddress(
            config.ticketItemId,
            config.inCount, // Number of tickets to burn up
            requester
        );

        // Handle vend
        if (config.isERC721) {
            // Transfer ERC721 NFT to user
            IERC721(config.contractAddress).transferFrom(
                address(this),
                requester,
                config.tokenId
            );
        } else if (config.contractAddress == ADDRESS_ZERO) {
            // ERC1155 items from shop contract
            vendorContract.mintItemToAddress(
                config.tokenId,
                config.outCount,
                requester
            );
        } else {
            // ERC1155 items from another 1155 contract
            IERC1155(config.contractAddress).safeTransferFrom(
                address(this),
                requester,
                config.tokenId,
                config.outCount,
                ""
            );
        }

        // Outcome event
        emit VendedItem(
            config.vendId,
            requester,
            config.contractAddress,
            config.inCount,
            config.outCount,
            config.tokenId
        );
    }

    /**
     * Owner functions
     */

    /// @notice Created a new vending machine item config
    function createVendingConfig(
        bool isERC721,
        address contractAddress,
        uint32 ticketItemId,
        uint32 tokenId,
        uint64 inCount,
        uint64 outCount,
        uint64 quantity
    ) external onlyRole(MODERATOR_ROLE) {
        require(!isERC721 || contractAddress != ADDRESS_ZERO, "!valid");
        uint256 nextVendId = lastVendId++;
        vendingConfigs[nextVendId] = VendingConfig({
            vendId: nextVendId,
            isERC721: isERC721,
            contractAddress: contractAddress,
            ticketItemId: ticketItemId,
            tokenId: tokenId,
            inCount: inCount,
            outCount: outCount,
            quantity: quantity
        });
        emit CreatedVendItem(nextVendId);
    }

    /**
     * @notice Update a vending machine config
     * @param config The configuration for the nft exchange
     */
    function updateVendingConfig(
        VendingConfig calldata config
    ) external onlyRole(MODERATOR_ROLE) {
        vendingConfigs[config.vendId] = config;
        emit UpdatedVendItem(config.vendId);
    }

    /**
     * @notice Deposit NFTs into contract (ERC721 or ERC1155)
     * @param contractAddress The address of the contract to move asset
     * @param tokenIds The token ids to add into contract
     * @param amounts The amount per token, for erc721 this is effectively ignored
     * @param isERC721 Whether the NFTs are 721 or 1155
     */
    function depositNFTs(
        address contractAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bool isERC721
    ) external onlyRole(MODERATOR_ROLE) {
        if (isERC721) {
            for (uint256 i; i < tokenIds.length; ) {
                IERC721(contractAddress).transferFrom(
                    _msgSender(),
                    address(this),
                    tokenIds[i]
                );
                unchecked {
                    ++i;
                }
            }
        } else {
            require(tokenIds.length == amounts.length, "!invalid");
            for (uint256 i; i < tokenIds.length; ) {
                IERC1155(contractAddress).safeTransferFrom(
                    _msgSender(),
                    address(this),
                    tokenIds[i],
                    amounts[i],
                    ""
                );
                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Withdraws NFTs by contract address and token id
     * @param contractAddress The address of the contract to move asset
     * @param tokenIds The token ids to add into contract
     * @param amounts The amount per token, for erc721 this is effectively ignored
     * @param isERC721 Whether the NFTs are 721 or 1155
     */
    function withdrawNFTs(
        address contractAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bool isERC721
    ) external onlyRole(MODERATOR_ROLE) {
        if (isERC721) {
            for (uint256 i; i < tokenIds.length; ) {
                IERC721(contractAddress).transferFrom(
                    address(this),
                    _msgSender(),
                    tokenIds[i]
                );
                unchecked {
                    ++i;
                }
            }
        } else {
            require(tokenIds.length == amounts.length, "!invalid");
            for (uint256 i; i < tokenIds.length; ) {
                IERC1155(contractAddress).safeTransferFrom(
                    address(this),
                    _msgSender(),
                    tokenIds[i],
                    amounts[i],
                    ""
                );
                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Sets the pause state
     * @param _isPaused The pause state
     */
    function setPaused(bool _isPaused) external onlyRole(MODERATOR_ROLE) {
        isPaused = _isPaused;
    }

    /**
     * @dev Set moderator address by owner
     * @param moderator address of moderator
     * @param approved true to add, false to remove
     */
    function setModerator(
        address moderator,
        bool approved
    ) external onlyRole(OWNER_ROLE) {
        require(moderator != address(0), "!valid");
        if (approved) {
            _grantRole(MODERATOR_ROLE, moderator);
        } else {
            _revokeRole(MODERATOR_ROLE, moderator);
        }
    }

    /**
     * @notice Returns the vending state information
     * @return bytes[]
     */
    function vendingState() external view returns (bytes[] memory) {
        bytes[] memory configs = new bytes[](lastVendId);
        VendingConfig storage config;

        uint256 i;

        for (; i < lastVendId; ) {
            config = vendingConfigs[i];

            configs[i] = abi.encode(
                i,
                config.isERC721,
                config.contractAddress,
                config.ticketItemId,
                config.tokenId,
                config.inCount,
                config.outCount,
                config.quantity
            );

            unchecked {
                ++i;
            }
        }

        return configs;
    }

    /**
     * Native meta transactions
     */

    function _msgSender()
        internal
        view
        virtual
        override(ERC2771Context, Context)
        returns (address)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ERC2771Context, Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }
}
