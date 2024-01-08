// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;
pragma abicoder v2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";

struct RoyaltySplit {
    address payable royaltyReceiver;
    uint8 royaltyPercentage;
}

/**
 * @title Ainsoph v3
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI auto-generation
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract Ainsoph3 is
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable
{
    /** May mint assets. */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /** Used for whitelisting marketplaces. */
    bytes32 public constant MARKETPLACE_ROLE = keccak256("MARKETPLACE_ROLE");

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /** The marketplace fee on top of all royalties. */
    uint8 public constant MARKETPLACE_FEE_PERCENTAGE = 5;

    /** Address to send marketplace fees. */
    address payable public marketplaceFeeAddress;

    string private _baseTokenURI;

    /** Stores royaltyPercentage for each token. */
    struct Piece {
        address payable royaltyReceiver;
        bool openTradingAllowed;
        RoyaltySplit[] royaltySplits;
    }

    mapping(uint256 => Piece) public pieceList;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `MINTER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be auto-generated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address payable initialMarketplaceFeeAddress
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());

        marketplaceFeeAddress = initialMarketplaceFeeAddress;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI auto-generated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mintAsset(
        uint256 tokenId,
        address owner,
        address payable publicRoyaltyReceiver,
        RoyaltySplit[] memory royaltySplits
    ) public virtual whenNotPaused {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "must have minter role to mint"
        );

        // Store data about the piece.
        pieceList[tokenId].royaltyReceiver = publicRoyaltyReceiver;
        pieceList[tokenId].openTradingAllowed = false;

        uint8 totalRoyaltyPercentage = 0;

        for (uint256 i = 0; i < royaltySplits.length; i++) {
            totalRoyaltyPercentage += royaltySplits[i].royaltyPercentage;

            // Copy over royalty split.
            pieceList[tokenId].royaltySplits.push(royaltySplits[i]);
        }

        require(totalRoyaltyPercentage <= 100, "royalties cannot be > 100%");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(owner, tokenId);
    }

    /**
     * @dev Return the royalty amount and receiver for a token and price.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        Piece storage piece = pieceList[tokenId];

        uint8 totalRoyaltyPercentage = _totalRoyaltyPercentage(
            piece.royaltySplits
        );

        return (
            piece.royaltyReceiver,
            (salePrice * totalRoyaltyPercentage) / 100
        );
    }

    /**
     * Verify a set of royalties meets or exceeds the piece's royalty list.
     */
    function verifyRoyalties(
        uint256 tokenId,
        uint8 marketplaceFeePercentage,
        RoyaltySplit[] calldata royaltySplitsToVerify
    ) external view {
        Piece storage piece = pieceList[tokenId];

        require(
            marketplaceFeePercentage >= MARKETPLACE_FEE_PERCENTAGE,
            "marketplace fee is too low"
        );

        bool receiverFound;

        for (
            uint256 royaltyIndex = 0;
            royaltyIndex < piece.royaltySplits.length;
            royaltyIndex++
        ) {
            receiverFound = false;

            for (
                uint256 verifyIndex = 0;
                verifyIndex < royaltySplitsToVerify.length;
                verifyIndex++
            ) {
                if (
                    piece.royaltySplits[royaltyIndex].royaltyReceiver ==
                    royaltySplitsToVerify[verifyIndex].royaltyReceiver
                ) {
                    require(
                        piece.royaltySplits[royaltyIndex].royaltyPercentage <=
                            royaltySplitsToVerify[verifyIndex]
                            .royaltyPercentage,
                        "royalty percentage is too low"
                    );
                    receiverFound = true;
                }
            }

            require(receiverFound, "missing royalty receiver");
        }
    }

    /**
     * @dev Distribute royalties for a piece based on the royalty splits, plus the marketplace fee.
     * Send just the royalties for a sale, and have them distributed by percentage.
     */
    function distributeRoyalties(uint256 tokenId)
        external
        payable
        whenNotPaused
    {
        Piece storage piece = pieceList[tokenId];

        /** Stores the remainder sent to the marketplace as a fee. */
        uint256 marketplaceFee = msg.value;
        uint256 royaltyValue;

        /** The total price of the sale, based on the royalties sent.  */
        uint256 totalPrice = (msg.value * 100) /
            _totalRoyaltyPercentage(piece.royaltySplits);

        // Send fees to royalty receivers.
        for (uint256 i = 0; i < piece.royaltySplits.length; i++) {
            royaltyValue =
                (totalPrice * piece.royaltySplits[i].royaltyPercentage) /
                100;

            marketplaceFee -= royaltyValue;

            payable(piece.royaltySplits[i].royaltyReceiver).transfer(
                royaltyValue
            );
        }

        // Send remaining fee to marketplace.
        marketplaceFeeAddress.transfer(marketplaceFee);
    }

    /**
     * Get number of royalty receivers to enumerate over.
     */
    function royaltyReceiverCount(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        // Add +1 for the marketplace fee.
        return pieceList[tokenId].royaltySplits.length + 1;
    }

    /**
     * Get a specific royalty split.
     */
    function royaltyReceiver(uint256 tokenId, uint256 index)
        external
        view
        returns (address, uint8)
    {
        if (index == pieceList[tokenId].royaltySplits.length) {
            // The last "split" is the marketplace fee.
            return (marketplaceFeeAddress, MARKETPLACE_FEE_PERCENTAGE);
        } else {
            RoyaltySplit storage royaltySplit = pieceList[tokenId]
            .royaltySplits[index];
            return (
                royaltySplit.royaltyReceiver,
                royaltySplit.royaltyPercentage
            );
        }
    }

    function setOpenTrading(uint256 tokenId, bool openTradingAllowed)
        public
        whenNotPaused
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "must have admin role"
        );

        pieceList[tokenId].openTradingAllowed = openTradingAllowed;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "must have admin role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "must have admin role to unpause"
        );
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return
            // Supports ERC2981 Royalties
            interfaceId == _INTERFACE_ID_ERC2981 ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Change the metadata URI.
     */
    function changeBaseURI(string memory baseTokenURI) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "must have admin role"
        );

        _baseTokenURI = baseTokenURI;
    }

    /** Change the marketplace fee recipient address.  */
    function changeMarketplaceFeeRecipient(
        address payable newMarketplaceFeeAddress
    ) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "must have admin role"
        );

        marketplaceFeeAddress = newMarketplaceFeeAddress;
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`,
     *      taking the marketplace role into account.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        override
        returns (bool)
    {
        return
            // Only allow whitelisted marketplaces when openTrading is not allowed.
            (hasRole(MARKETPLACE_ROLE, spender) ||
                pieceList[tokenId].openTradingAllowed) &&
            super._isApprovedOrOwner(spender, tokenId);
    }

    function _totalRoyaltyPercentage(RoyaltySplit[] memory royaltySplits)
        internal
        pure
        returns (uint8)
    {
        // Start with the marketplace fee.
        uint8 totalRoyaltyPercentage = MARKETPLACE_FEE_PERCENTAGE;

        // Add all other royalty receivers.
        for (uint256 i = 0; i < royaltySplits.length; i++) {
            totalRoyaltyPercentage += royaltySplits[i].royaltyPercentage;
        }

        return totalRoyaltyPercentage;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
