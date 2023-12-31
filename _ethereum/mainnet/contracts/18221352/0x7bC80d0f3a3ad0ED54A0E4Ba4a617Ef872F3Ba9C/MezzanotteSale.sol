//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./Math.sol";

import "./Ownable.sol";
import "./ERC721.sol";

/// @title Mezzanote Sales contract
/// @notice This contract mints Mezanote NFTs on sales started and parametrized by the owner.
contract MezzanotteSale is Ownable {
    //
    // Using Statements
    //
    using MerkleProof for bytes32[];
    using SafeERC20 for IERC20;

    //
    // Errors
    //

    /// Throws when creating/editing a sale and the start time is bigger than the finish time
    error InvalidSaleIntervalError(uint256 start, uint256 finish);

    /// Throws when creating/editing a sale and it is of type whitelist but the provided root is 0
    error InvalidWhitelistRootError();

    /// Throws when a sale with max mint is created/edited with a max mint of 0
    error InvalidSaleMaxMintError();

    /// Throws when the sale does not exist
    error SaleNotFoundError(uint256 saleId);

    /// Throws when a user wants to mint 0 tokens
    error ZeroMintQuantityError();

    /// Throws when the minting call fails
    error MintFailedError(bytes data);

    /// Throws when the current timestamp is not within the sale interval
    error NotInSalePhaseError(uint256 saleId, uint256 start, uint256 finish, uint256 current);

    /// Throws when the user is not whitelisted for the sale (wrong proof)
    error UserNotWhitelistedOrWrongProofError(uint256 saleId, address user, bytes32[] proof);

    /// Throws when the user does not send the right ether value for the mint
    error WrongValueSentForMintError(uint256 saleId, uint256 value, uint256 price, uint256 quantity);

    /// Throws when the user tries to mint more than their allowance
    error MaximumSaleLimitReachedError(uint256 saleId, address user, uint256 limit);

    /// Throws when the user tries to mint more than the max mint for a certain sale
    error MaximumSaleMintSupplyReachedError(uint256 saleId);

    /// Throws when the user tries to mint more than the max mint for all sales
    error MaximumTotalMintSupplyReachedError();

    /// Throws when the owner is changing the max mint supply and the value is the same as the previous one
    error StaleMaxMintUpdateError();

    /// Throws when an address to mint for is 0
    error ZeroAddressError();

    /// Throws when refund fails
    error EtherRefundFailedError();

    // Throws when withdraw eth fails
    error EtherWithdrawFailedError();

    //
    // Events
    //

    /*
     * @notice Emitted when the token's URI is changed
     * @param newURI The new URI
     */
    event LogSetURI(string newURI);

    /*
     * @notice Emitted when a sale is created
     * @param saleId The sale's ID
     * @param start The sale's start time
     * @param finish The sale's finish time
     * @param limit The sale's limit per user
     * @param price The sale's price
     * @param whitelist Whether the sale is of type whitelist or not
     * @param root The sale's merkle root (does not matter for public sales)
     * @param hasMaxMint Whether the sale has a max mint or not
     * @param maxMint The sale's max mint (does not matter if hasMaxMint is false)
     */
    event LogSaleCreated(
        uint256 indexed saleId,
        uint64 start,
        uint64 finish,
        uint8 limit,
        uint64 price,
        bool whitelist,
        bytes32 root,
        bool hasMaxMint,
        uint40 maxMint
    );

    /*
     * @notice Emitted when a sale is edited
     * @param saleId The sale's ID
     * @param start The sale's start time
     * @param finish The sale's finish time
     * @param limit The sale's limit per user (applicable only for public sales)
     * @param price The sale's price
     * @param whitelist Whether the sale is of type whitelist or not
     * @param root The sale's merkle root (does not matter for public sales)
     * @param hasMaxMint Whether the sale has a max mint or not
     * @param maxMint The sale's max mint (does not matter if hasMaxMint is false)
     */
    event LogSaleEdited(
        uint256 indexed saleId,
        uint64 start,
        uint64 finish,
        uint8 limit,
        uint64 price,
        bool whitelist,
        bytes32 root,
        bool hasMaxMint,
        uint40 maxMint
    );

    /*
     * @notice Emitted when tokens are sold on a sale
     * @param saleId The sale's ID
     * @param to The address that bought the token
     * @param quantity The quantity of tokens bought
     */
    event LogSale(uint256 indexed saleId, address indexed to, uint256 quantity);

    /* Emitted when the max mint supply is changed
     * @param prevMaxMint The previous max mint supply
     * @param newMaxMint The new max mint supply
     */
    event LogSetMaxMint(uint256 prevMaxMint, uint256 newMaxMint);

    event LogRefund(uint256 indexed saleId, address indexed to, uint256 value);

    //
    // Structs
    //

    /// Defines the parameters for a sale period.
    /// This is created by the contract's Sale Admin.
    /// A sale is active when block.timestamp in interval [start, finish].
    /// The limit per user of a whitelist sale is stored in the merkle root.
    /// @param root The current sale's merkle root (0 for public sales).
    /// @param whitelist True for whitelist, false for public.
    /// @param start The sale's start time.
    /// @param finish The sale's finish time.
    /// @param price The NFT price on this sale.
    /// @param limit The sale's limit per user (applicable only for public sales).
    /// @param hasMaxMint Whether the sale has a max mint or not.
    /// @param maxMint The sale's max mint (does not matter if hasMaxMint is false).
    struct Sale {
        bytes32 root;
        bool whitelist;
        uint64 start;
        uint64 finish;
        uint64 price;
        uint8 limit;
        bool hasMaxMint;
        uint40 maxMint;
    }

    //
    // Sales Variables
    //

    //
    // State
    //

    // The sales limit of NFTs per user.
    uint8 constant LIMIT = 10;

    // Default max total amount that can be minted.
    uint256 constant MAXMINT = 555;

    /// Max total mint
    uint256 public maxMint;

    /// Id of the next NFT id to mint (sequential id).
    uint256 public nextToMint = 25;

    /// List of sale phases.
    Sale[] private _sales;

    /// Token to be minted in sales.
    address private _NFTToken;

    /// Mapping of the quantity of NFTs minted to each address.
    /// Used to track and cap how many tokens an address is allowed to mint per round.
    /// current sale id => user address => number of NFTs minted
    mapping(uint256 => mapping(address => uint256)) private _minted;

    /// Mapping of the quantity of NFTs minted on each sale.
    /// Used to track and cap how many tokens are minted per sale.
    mapping(uint256 => uint256) private _mintedTotal;

    /// @param NFTToken_ Address of token to mint in sales.
    /// @param startSales_ The start of the sales.
    /// @param whitelistRoot_ For the whitelist sale, this parameter defines the merkle root to be used for verification.
    constructor(
        address NFTToken_,
        uint64 startSales_,
        bytes32 whitelistRoot_,
        uint64 whitelistSaleDuration_,
        uint64 price_
    ) Ownable(_msgSender()) {
        setMaxMint(MAXMINT);

        _NFTToken = NFTToken_;

        uint64 startPublic_ = startSales_ + whitelistSaleDuration_;

        // Whitelist Sale
        addSale(startSales_, startPublic_ - 1, LIMIT, price_, true, whitelistRoot_, false, 0);
        // Public Sale
        addSale(startPublic_, type(uint64).max, LIMIT, price_, false, 0, false, 0);
    }

    /// @notice Adds a new sale period.
    /// @dev Can only be called by the contract owner.
    /// @param start_ The start of the sale.
    /// @param finish_ The end of the sale.
    /// @param _limit The maximum number of NFTs an account can mint during this period.
    /// @param _price The price of each NFT during this period.
    /// @param whitelist_ Whether the sale is a whitelist sale
    /// @param root_ When adding a whitelist sale, this parameter defines the merkle root to be used for verification.
    /// @param hasMaxMint_ Whether the sale has a max mint
    /// @param maxMint_ The max mint for the sale
    function addSale(
        uint64 start_,
        uint64 finish_,
        uint8 _limit,
        uint64 _price,
        bool whitelist_,
        bytes32 root_,
        bool hasMaxMint_,
        uint40 maxMint_
    ) public onlyOwner {
        // sale Id does not matter when adding a sale
        _validateSaleParams(start_, finish_, whitelist_, root_, hasMaxMint_, maxMint_);

        Sale memory sale_ = Sale({
            start: start_,
            finish: finish_,
            limit: _limit,
            price: _price,
            whitelist: whitelist_,
            root: root_,
            hasMaxMint: hasMaxMint_,
            maxMint: maxMint_
        });
        _sales.push(sale_);

        emit LogSaleCreated(
            _sales.length - 1, start_, finish_, _limit, _price, whitelist_, root_, hasMaxMint_, maxMint_
        );
    }

    /// @notice Edits a Sale Phase. Can't change the hasMaxMint property, only the maxMint property.
    /// @dev Can only be called by the contract owner.
    /// @param saleId_ The unique ID of the sale to be edited
    /// @param start_ The new start time we want the sale to have
    /// @param finish_ The new end time we want the sale to have
    /// @param _limit The new limit of NFTs we want the sale to have
    /// @param _price The new price we want the NFTs to have
    /// @param whitelist_ Whether it is a whitelist sale
    /// @param root_ Defines the root to be used for whitelist verification
    /// @param maxMint_ The new max mint we want the sale to have
    /// If we want any Sale parameter to stay unchanged, send the same value as a parameter to the function
    function editSale(
        uint256 saleId_,
        uint64 start_,
        uint64 finish_,
        uint8 _limit,
        uint64 _price,
        bool whitelist_,
        bytes32 root_,
        uint40 maxMint_
    ) external onlyOwner {
        if (saleId_ >= _sales.length) revert SaleNotFoundError(saleId_);

        Sale memory sale_ = _sales[saleId_];

        _validateSaleParams(start_, finish_, whitelist_, root_, sale_.hasMaxMint, maxMint_);
        if (sale_.hasMaxMint && maxMint_ < sale_.maxMint) {
            maxMint_ = uint40(Math.max(maxMint_, _mintedTotal[saleId_]));
        }

        sale_.start = start_;
        sale_.finish = finish_;
        sale_.limit = _limit;
        sale_.price = _price;
        sale_.whitelist = whitelist_;
        sale_.root = root_;
        sale_.maxMint = maxMint_;

        _sales[saleId_] = sale_;

        emit LogSaleEdited(saleId_, start_, finish_, _limit, _price, whitelist_, root_, sale_.hasMaxMint, maxMint_);
    }

    /// @notice Withdraws any ETH sent to this contract.
    /// @dev Only callable by this contract's owner.
    /// @param to_ The address to withdraw to.
    /// @param amount_ The amount of ETH (in Wei) to withdraw.
    function withdrawEther(address to_, uint256 amount_) external onlyOwner {
        (bool success,) = payable(to_).call{ value: amount_ }("");
        if (!success) {
            revert EtherWithdrawFailedError();
        }
    }

    /// Withdraws any ERC20 tokens sent to the contract.
    /// @dev only callable by the owner.
    /// @param token_ The ERC20 token to withdraw
    /// @param to_ The address to withdraw to.
    /// @param amount_ The amount to withdraw
    function withdrawERC20(address token_, address to_, uint256 amount_) external onlyOwner {
        IERC20(token_).safeTransfer(to_, amount_);
    }

    //
    // Public Read API
    //

    /// @notice Returns the sale data for a given sale ID.
    /// @param saleId_ The ID of the sale to get data for.
    /// @return The sale data.
    function getSale(uint256 saleId_) external view returns (Sale memory) {
        return _sales[saleId_];
    }

    /// @notice Returns the number of sales.
    /// @return The number of sales.
    function getSalesCount() external view returns (uint256) {
        return _sales.length;
    }

    /// @notice Returns true if the block.timestamp is within the sale's interval.
    /// @param saleId_ The ID of the sale to check.
    /// @return True if the sale is active.
    function isSaleActive(uint256 saleId_) external view returns (bool) {
        Sale memory sale_ = _sales[saleId_];
        return block.timestamp >= sale_.start && block.timestamp <= sale_.finish;
    }

    /// @notice Returns the minted amount of a user on a sale.
    /// @param saleId_ The ID of the sale to check.
    /// @param user_ The user to check.
    /// @return The minted amount.
    function getMintedAmount(uint256 saleId_, address user_) external view returns (uint256) {
        return _minted[saleId_][user_];
    }

    //
    // Public Write API
    //

    /// @notice Sets a new total max mint supply.
    /// @dev Only callable by the owner.
    /// @param newMaxMint_ The new max mint supply.
    function setMaxMint(uint256 newMaxMint_) public onlyOwner {
        uint256 oldMaxMint = maxMint;
        if (newMaxMint_ == oldMaxMint) revert StaleMaxMintUpdateError();

        // bound max mint to next max mint, so that maxMint is never lower than nextToMint id
        if (newMaxMint_ < oldMaxMint) {
            newMaxMint_ = Math.max(newMaxMint_, nextToMint);
        }

        maxMint = newMaxMint_;
        emit LogSetMaxMint(oldMaxMint, newMaxMint_);
    }

    /// @notice Mints an NFT quantity to anyone who pays for it.
    /// @param saleId_ The ID of the sale to mint from
    /// @param user_ The user to mint to
    /// @param quantity_ The quantity of NFTs to mint
    function publicSaleMint(uint256 saleId_, address user_, uint256 quantity_) external payable {
        _saleMint(saleId_, user_, quantity_, new bytes32[](0));
    }

    /// @notice Mints an NFT quantity to someone who has been whitelisted.
    /// @param saleId_ The ID of the sale to mint from.
    /// @param user_ The user to mint to.
    /// @param quantity_ The quantity of NFTs to mint.
    /// @param proof_ The proof of the user's whitelisting.
    function whitelistSaleMint(uint256 saleId_, address user_, uint256 quantity_, bytes32[] memory proof_)
        external
        payable
    {
        _saleMint(saleId_, user_, quantity_, proof_);
    }

    function _saleMint(uint256 saleId_, address user_, uint256 quantity_, bytes32[] memory proof_) internal {
        // check if sale is registered and quantity is grater than zero
        if (saleId_ >= _sales.length) revert SaleNotFoundError(saleId_);
        if (quantity_ == 0) revert ZeroMintQuantityError();
        if (user_ == address(0)) revert ZeroAddressError();

        Sale memory sale_ = _sales[saleId_];
        if (block.timestamp < sale_.start || block.timestamp > sale_.finish) {
            revert NotInSalePhaseError(saleId_, sale_.start, sale_.finish, block.timestamp);
        }

        // validate whitelist
        if (sale_.whitelist) {
            bytes32 leaf = keccak256(abi.encodePacked(user_));
            if (!_verify(sale_.root, proof_, leaf)) {
                revert UserNotWhitelistedOrWrongProofError(saleId_, user_, proof_);
            }
        }

        // validate ETH amount send to contract
        if (msg.value != quantity_ * sale_.price) {
            revert WrongValueSentForMintError(saleId_, msg.value, sale_.price, quantity_);
        }

        // validate individual mint limit
        if (sale_.limit - _minted[saleId_][user_] < quantity_) {
            revert MaximumSaleLimitReachedError(saleId_, user_, sale_.limit);
        }

        // validate total mint limit
        uint256 mintedBefore = nextToMint;
        uint256 availableTotal_ = maxMint - mintedBefore;
        if (availableTotal_ == 0) {
            revert MaximumTotalMintSupplyReachedError();
        }

        // bound the quantity to mint and increase mint count
        uint256 quantityToMint_ = Math.min(availableTotal_, quantity_);

        if (sale_.hasMaxMint) {
            // validate max sale mint limit
            uint256 availableSale = sale_.maxMint - _mintedTotal[saleId_];
            if (availableSale == 0) {
                revert MaximumSaleMintSupplyReachedError(saleId_);
            }
            quantityToMint_ = Math.min(availableSale, quantityToMint_);
            _mintedTotal[saleId_] += quantityToMint_;
        }

        _minted[saleId_][user_] += quantityToMint_;
        nextToMint += quantityToMint_;

        // mint NFTs
        for (uint256 i; i < quantityToMint_;) {
            (bool success_, bytes memory data_) =
                _NFTToken.call(abi.encodeWithSignature("mint(address,uint256)", user_, mintedBefore + i));
            if (!success_) revert MintFailedError(data_);
            unchecked {
                ++i;
            }
        }

        // emit sale event
        emit LogSale(saleId_, user_, quantityToMint_);

        // refund leftover eth to buyer
        if (quantityToMint_ < quantity_) {
            // can fail when minting through a contract
            (bool success,) = payable(msg.sender).call{ value: sale_.price * (quantity_ - quantityToMint_) }("");
            if (!success) {
                revert EtherRefundFailedError();
            }
            emit LogRefund(saleId_, msg.sender, quantity_ - quantityToMint_);
        }
    }

    //
    // Internal
    //
    function _validateSaleParams(
        uint64 start_,
        uint64 finish_,
        bool whitelist_,
        bytes32 root_,
        bool hasMaxMint_,
        uint40 maxMint_
    ) internal pure {
        if (start_ > finish_) revert InvalidSaleIntervalError(start_, finish_);
        if (whitelist_ && root_ == bytes32(0)) revert InvalidWhitelistRootError();
        if (hasMaxMint_ && maxMint_ == 0) revert InvalidSaleMaxMintError();
    }

    /// @notice Internal merkle proof verification.
    /// @dev Verify that `proof` is valid and `leaf` occurs in the merkle tree with root hash `merkleRoot`.
    /// @param root_ The Merkle Tree Root to be used for verification
    /// @param proof_ The merkle proof.
    /// @param leaf_ The leaf node to find.
    function _verify(bytes32 root_, bytes32[] memory proof_, bytes32 leaf_) internal pure returns (bool verified) {
        verified = proof_.verify(root_, leaf_);
    }
}
