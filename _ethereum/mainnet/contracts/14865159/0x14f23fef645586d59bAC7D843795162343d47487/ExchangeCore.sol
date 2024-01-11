pragma solidity 0.8.12;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IRoyaltyFeeManager.sol";
import "./ICollectionRegistry.sol";

import "./IRewards.sol";
import "./Errors.sol";
import "./IWETH.sol";

contract ExchangeCore is Ownable, Pausable, ReentrancyGuard, Errors {
    // Wrapped ETH
    address public immutable WETH;
    // Genesis jumy nft collection
    address public immutable JUMY_COLLECTION;

    // Jumy royalty fee manager and registry
    IRoyaltyFeeManager public royaltyManager;

    // Jumy creator collections registry
    ICollectionRegistry public collectionRegistry;

    // Jumy token rewards
    IRewards public rewardsManager;

    address public protocolFeesRecipient;
    uint256 public protocolFeesPercentage = 500; // 5%, {100_00}Base

    // Allowed collection to be listed
    mapping(address => bool) public whitelistedCustomCollection;

    // Not Allowed collection from been listed
    mapping(address => bool) public blackListedCollection;

    // Not Allowed users from listing
    mapping(address => bool) public blackListedUser;

    // Defines a different service fees percentage than the global one for some specific collections (e.g., Brands)
    mapping(address => uint256) public specialProtocolFeesPercentage;

    // Withdrawable ETH of failed transfers
    mapping(address => uint256) public failedEthTransfer;

    event RoyaltySent(
        address indexed to,
        address collection,
        uint256 tokenId,
        uint256 amount
    );

    event ServiceFeesCollected(address indexed to, uint256 amount);

    event FailedToSendEth(address to, uint256 amount);

    event FailedEthWithdrawn(address from, address to, uint256 amount);

    event StuckEthWithdrawn(uint256 amount);

    event StuckERC721Transferred(
        address collection,
        uint256 tokenId,
        address to
    );

    event StuckERC1155Transferred(
        address collection,
        uint256 tokenId,
        uint256 amount,
        address to
    );

    modifier onlyNonBlacklistedUsers() {
        if (blackListedUser[msg.sender]) revert BlacklistedUser();
        _;
    }

    modifier onlyAllowedToBeListed(address collection) {
        if (!_isAllowedToBeListed(collection))
            revert Exchange_UnAuthorized_Collection();
        _;
    }

    constructor(
        address weth,
        address jumyNftCollection,
        address royaltyManagerContract,
        address collectionRegistryContract,
        address protocolFeesRecipientWallet
    ) {
        if (protocolFeesRecipientWallet == address(0))
            revert RejectedNullishAddress();

        if (weth == address(0)) revert RejectedNullishAddress();

        if (jumyNftCollection == address(0)) revert RejectedNullishAddress();

        WETH = weth;
        JUMY_COLLECTION = jumyNftCollection;
        royaltyManager = IRoyaltyFeeManager(royaltyManagerContract);
        collectionRegistry = ICollectionRegistry(collectionRegistryContract);
        protocolFeesRecipient = protocolFeesRecipientWallet;
    }

    function isAllowedToBeListed(address collection)
        external
        view
        returns (bool)
    {
        return _isAllowedToBeListed(collection);
    }

    function getProtocolFeesPercentage(address collection)
        external
        view
        returns (uint256)
    {
        return _getProtocolFeesPercentage(collection);
    }

    /**
     * @dev Get the service fees percentage 10_000 base (500 ==> 5%, 50 ==> 0.5%).
     * @notice function will check if there's any manually custom fees percentage.
     * set for a specific collection in the `specialProtocolFeesPercentage` mapping
     * if there's no custom collection specific fees it returns the global fees percentage `protocolFeesPercentage`.
     */
    function _getProtocolFeesPercentage(address collection)
        internal
        view
        returns (uint256)
    {
        uint256 percentage = specialProtocolFeesPercentage[collection];

        if (percentage == 0) return protocolFeesPercentage;
        return percentage;
    }

    /**
     * @dev Calculate the service fees amount.
     * @notice Take the total amount and calculate the service fees amount
     * by getting the fees percentage and divide by 10,000.
     */
    function _calculateProtocolFeesAmount(uint256 amount, address collection)
        internal
        view
        returns (uint256)
    {
        return (amount * _getProtocolFeesPercentage(collection)) / 10_000;
    }

    /**
     * @dev define the whitelist collection logic.
     * @notice the whitelisted collections are:
     * - genesis collection `JUMY_COLLECTION`.
     * - creators collections registered in `collectionRegistry`.
     * - custom manually imported collections.
     * @notice all manually blacklisted collection are rejected.
     */
    function _isAllowedToBeListed(address collection)
        internal
        view
        returns (bool)
    {
        return ((!blackListedCollection[collection] &&
            // must not be blacklisted
            // if it's genesis jumy collection
            // if it's jumy collection created via factory
            // if it's any other collection added bya admin
            (collection == JUMY_COLLECTION)) ||
            collectionRegistry.isJumyCollection(collection) ||
            whitelistedCustomCollection[collection]);
    }

    /**
     * @dev Split and Send ETH or FAIL.
     * @notice ETH amount will be split to:
     * - #1 Service fees, Will be sent to {protocolFeesRecipient}.
     * - #2 Royalty fees, Will be sent to royalty recipient.
     * - #3 Remaining funds (total - #1 - #2), Will be sent to {to}.
     *
     * @notice If any of the above failed to send ETH, transaction will revert.
     */
    function _executeETHPayment(
        address collection,
        uint256 tokenId,
        address to,
        uint256 amount
    ) internal {
        (address royaltyFeesRecipient, uint256 royaltyCut) = royaltyManager
            .calculateRoyaltyFeeAndGetRecipient(collection, tokenId, amount);

        uint256 serviceCut = _calculateProtocolFeesAmount(amount, collection);

        uint256 recipientCut = amount - serviceCut - royaltyCut;

        payable(to).transfer(recipientCut);
        payable(protocolFeesRecipient).transfer(serviceCut);

        if (royaltyFeesRecipient != address(0)) {
            payable(royaltyFeesRecipient).transfer(royaltyCut);
            emit RoyaltySent(
                royaltyFeesRecipient,
                collection,
                tokenId,
                royaltyCut
            );
        }
    }

    /**
     * @dev Split and Send ETH and save for withdraw if FAIL.
     * @notice ETH amount will be split to:
     * - #1 Service fees, Will be sent to {protocolFeesRecipient}.
     * - #2 Royalty fees, Will be sent to royalty recipient.
     * - #3 Remaining funds (total - #1 - #2), Will be sent to {to}.
     *
     * @notice If any of the above failed to send ETH, ETH amount will
     * be stored and made available to withdraw by the recipient.
     */
    function _executeETHPaymentWithFallback(
        address collection,
        uint256 tokenId,
        address to,
        uint256 amount
    ) internal {
        (address royaltyFeesRecipient, uint256 royaltyCut) = royaltyManager
            .calculateRoyaltyFeeAndGetRecipient(collection, tokenId, amount);

        uint256 serviceCut = _calculateProtocolFeesAmount(amount, collection);

        uint256 recipientCut = amount - serviceCut - royaltyCut;

        payable(protocolFeesRecipient).transfer(serviceCut);

        if (!payable(to).send(recipientCut)) {
            failedEthTransfer[to] = recipientCut;
            emit FailedToSendEth(to, recipientCut);
        }

        if (royaltyFeesRecipient != address(0)) {
            if (!payable(royaltyFeesRecipient).send(royaltyCut)) {
                failedEthTransfer[royaltyFeesRecipient] = royaltyCut;
                emit FailedToSendEth(royaltyFeesRecipient, royaltyCut);
                return;
            }
            emit RoyaltySent(
                royaltyFeesRecipient,
                collection,
                tokenId,
                royaltyCut
            );
        }
    }

    /**
     * @dev Withdraw WETH then Split Send ETH or FAIL.
     * @notice WETH will be transferred from {from} then withdrawn (WETH => ETH).
     * @notice ETH amount will be split to:
     * - #1 Service fees, Will be sent to {protocolFeesRecipient}.
     * - #2 Royalty fees, Will be sent to royalty recipient.
     * - #3 Remaining funds (total - #1 - #2), Will be sent to {to}.
     *
     * @notice If any of the above failed to send ETH, transaction will revert.
     */
    function _executeWETHPayment(
        address collection,
        uint256 tokenId,
        address from,
        address to,
        uint256 amount
    ) internal {
        (address royaltyFeesRecipient, uint256 royaltyCut) = royaltyManager
            .calculateRoyaltyFeeAndGetRecipient(collection, tokenId, amount);

        uint256 serviceCut = _calculateProtocolFeesAmount(amount, collection);

        uint256 recipientCut = amount - serviceCut - royaltyCut;

        IWETH(WETH).transferFrom(from, address(this), amount);

        IWETH(WETH).withdraw(amount);

        payable(to).transfer(recipientCut);
        payable(protocolFeesRecipient).transfer(serviceCut);

        if (royaltyFeesRecipient != address(0)) {
            payable(royaltyFeesRecipient).transfer(royaltyCut);
            emit RoyaltySent(
                royaltyFeesRecipient,
                collection,
                tokenId,
                royaltyCut
            );
        }
    }

    /**
     * @dev Send ETH or save for withdraw on FAIL
     * @notice If FAILED to send ETH, ETH amount will be stored and made available
     * for withdraw.
     */
    function _sendEthWithFallback(address to, uint256 amount) internal {
        if (!payable(to).send(amount)) {
            failedEthTransfer[to] = amount;
            emit FailedToSendEth(to, amount);
            return;
        }
    }

    function withdrawETH(address to) external nonReentrant {
        uint256 amount = failedEthTransfer[msg.sender];

        if (amount == 0) revert();

        delete failedEthTransfer[msg.sender];

        payable(to).transfer(amount);

        emit FailedEthWithdrawn(msg.sender, to, amount);
    }
}
