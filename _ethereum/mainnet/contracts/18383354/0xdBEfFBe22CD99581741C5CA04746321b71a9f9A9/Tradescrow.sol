// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import "./AccessControlEnumerableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./Initializable.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./IERC20.sol";

import "./FeeManager.sol";
import "./Structs.sol";
import "./IDCounter.sol";
import "./TradeLibrary.sol";

/**
* @title Trade & Escrow v2.0.1
* @author @DirtyCajunRice
*/
contract Tradescrow is
    Initializable,
    ReentrancyGuardUpgradeable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    Structs,
    FeeManager,
    IDCounter,
    UUPSUpgradeable
{
    using TradeLibrary for Asset;
    using TradeLibrary for Trade;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Storage mapping for trades
    mapping (uint256 tradeId => Trade trade) private _trades;

    event TradeCreated(
        address indexed from,
        uint256 indexed tradeId,
        address indexed counterparty,
        Asset[] partyAssets,
        Asset[] counterpartyAssets
    );

    event TradeAccepted(address indexed from, uint256 indexed tradeId);
    event TradeRejected(address indexed from, uint256 indexed tradeId);
    event TradeCanceled(address indexed from, uint256 indexed tradeId);

    error InvalidCounterparty();
    error InvalidTradeId();
    error NotTradeParticipant();
    error TradeClosed();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Sets the initial fee
    function initialize() public initializer {
        __ReentrancyGuard_init();
        __AccessControlEnumerable_init();
        __Pausable_init();

        __FeeManager_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Propose a new trade and pay the app fee
     *
     * @dev Step 1: User proposes a trade to another address that contains any combination of
     *      NFTs (ERC721/ERC1155) and coins (ERC20) for both sides of the trade
     *
     * @param counterparty Address the sender wants to trade with
     * @param partyAssets Assets the sender is offering
     * @param counterpartyAssets Assets the sender is requesting
     */
    function createTrade(address counterparty, Asset[] calldata partyAssets, Asset[] calldata counterpartyAssets) external chargeFee {

        uint256 tradeId = newID();
        Trade storage trade = _trades[tradeId];
        trade.party = msg.sender;

        if (counterparty == address(0)) revert InvalidCounterparty();
        trade.counterparty = counterparty;

        uint256 len = partyAssets.length;
        for (uint256 i = 0; i < len; i++) {
            trade.partyAssets.push(partyAssets[i]);
        }

        len = counterpartyAssets.length;
        for (uint256 i = 0; i < len; i++) {
            trade.counterpartyAssets.push(counterpartyAssets[i]);
        }

        emit TradeCreated(msg.sender, tradeId, counterparty, partyAssets, counterpartyAssets);
    }

    /**
    * @notice Accept the proposed trade
    *
    * @dev Step 2A: Counterparty accepts the proposed trade, which transfers
    *      all assets to their intended parties. This can only be called by
    *      the counterparty of the swap
    *
    * @param tradeId ID of the trade that the counterparty wants to accept
    */
    function acceptTrade(uint256 tradeId) external releaseFee {
        if (!isValidTradeId(tradeId)) revert InvalidTradeId();
        Trade storage trade = _trades[tradeId];
        if (msg.sender != trade.counterparty) revert NotTradeParticipant();
        if (trade.status != Status.Open) revert TradeClosed();

        trade.status = Status.Accepted;
        trade.safeTransfer();

        emit TradeAccepted(msg.sender, tradeId);
    }

    /**
    * @notice Cancel / Reject the trade offer.
    * @dev Closes the trade, marking it as either canceled or rejected based on the sender
    *
    * @param tradeId ID of the trade that the participant wants to cancel
    */
    function cancelTrade(uint256 tradeId) external {
        if (!isValidTradeId(tradeId)) revert InvalidTradeId();
        Trade storage trade = _trades[tradeId];
        if (msg.sender != trade.counterparty && msg.sender != trade.party) revert NotTradeParticipant();
        if (trade.status != Status.Open) revert TradeClosed();

        trade.status = msg.sender == trade.party ? Status.Canceled : Status.Rejected;
        refundFee(trade.party);
        if (msg.sender == trade.party) {
            emit TradeCanceled(msg.sender, tradeId);
        } else {
            emit TradeRejected(msg.sender, tradeId);
        }
    }

    function getTrade(uint256 tradeId) external view returns (Trade memory) {
        if (!isValidTradeId(tradeId)) revert InvalidTradeId();
        return _trades[tradeId];
    }

    // External Owner Functions

    /**
    * @notice Update the fee charged for a trade
    * @dev Can only be called by a contract admin
    *
    * @param fee Fee in wei
    */
    function setFee(uint256 fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setFee(fee);
    }

    function setFeeToken(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setFeeToken(token);
    }

    function setFeeTreasury(address treasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setFeeTreasury(treasury);
    }

    function setFeeTokenSelfApproval() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setFeeTokenSelfApproval();
    }

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal onlyRole(DEFAULT_ADMIN_ROLE) override {}

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId) public view
    override(AccessControlEnumerableUpgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
