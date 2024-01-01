// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./TransferHelper.sol";
import "./IAccess.sol";

contract Escrow is Initializable, ReentrancyGuardUpgradeable {
    // Counter for trades
    uint256 public tradesCounter;
    // Address of AZX token
    address public azx;
    // Address of the wallet for receiving fees
    address public ntzcWallet;
    // Address of the access control contract
    address public accessControl;

    // Mapping of trades
    mapping(uint256 => Trade) public trades;
    // Mapping of external trade IDs to internal trade IDs
    mapping(string => uint256) public tradesIdsToTrades;

    // Trade struct
    struct Trade {
        string tradeId;
        string[] links;
        address seller;
        address buyer;
        uint256 tradeCap;
        uint256 sellersPart;
        uint256 timeToResolve;
        uint256 resolveTS;
        uint256 linksLength;
        bool valid;
        bool paid;
        bool finished;
        bool released;
    }

    // Events
    event TradeRegistered(
        address indexed signer,
        string indexed tradeId,
        address seller,
        address buyer,
        uint256 tradeCap,
        uint256 sellersPart,
        uint256 timeToResolve
    );
    event TradeValidated(string indexed tradeId);
    event TradePaid(string indexed tradeId, uint256 amount);
    event TradeFinished(string indexed tradeId);
    event TradeReleased(
        string indexed tradeId,
        address buyer,
        uint256 cap,
        uint256 sellersPart
    );
    event TradeResolved(
        address indexed signer,
        string indexed tradeId,
        bool result,
        string reason
    );
    event FeeWalletChanged(address indexed wallet);
    event TradeDeskChanged(address indexed user, bool isTradeDesk);

    modifier onlyOwner() {
        require(
            IAccess(accessControl).isOwner(msg.sender),
            "Escrow: Only the owner is allowed"
        );
        _;
    }

    modifier onlyManager() {
        require(
            IAccess(accessControl).isSender(msg.sender),
            "Escrow: Only managers are allowed"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable {
        revert("Escrow: Contract cannot handle ETH");
    }

    /**
     * @dev Initializes the contract
     * @param _azxToken Address of AZX token
     * @param _azxWallet Address of the wallet for receiving fees
     * @param _access Address of the access control contract
     */
    function initialize(
        address _azxToken,
        address _azxWallet,
        address _access
    ) public initializer {
        __ReentrancyGuard_init();
        accessControl = _access;
        azx = _azxToken;
        ntzcWallet = _azxWallet;
    }

    /**
     * @dev Change the address of the wallet for receiving fees (owner only)
     * @param _wallet Address of the wallet for receiving fees
     */
    function changeWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Escrow: Zero address is not allowed");
        ntzcWallet = _wallet;

        emit FeeWalletChanged(_wallet);
    }

    /**
     * @dev Set TradeDesk status for a user
     * @param signature Buyer's signature
     * @param token Token address
     * @param user User's address
     * @param isTradeDesk Whether the user is a TradeDesk
     */
    function setTradeDesk(
        bytes memory signature,
        bytes32 token,
        address user,
        bool isTradeDesk
    ) external onlyManager {
        bytes32 message = tradeDeskProof(token, user, isTradeDesk);
        address signer = IAccess(accessControl).preAuthValidations(
            message,
            token,
            signature
        );
        require(
            IAccess(accessControl).isSigner(signer),
            "Escrow: Signer is not a manager"
        );
        IAccess(accessControl).updateTradeDeskUsers(user, isTradeDesk);

        emit TradeDeskChanged(user, isTradeDesk);
    }

    /**
     * @dev Register a new trade (admin only)
     * @param signature Buyer's signature
     * @param token Token address
     * @param tradeId External trade ID
     * @param links Array of links related to the trade
     * @param seller Seller's address
     * @param buyer Buyer's address
     * @param tradeCap Trade price
     * @param sellersPart Part of the tradeCap for the seller
     * @param timeToResolve Time to resolve the trade
     */
    function registerTrade(
        bytes memory signature,
        bytes32 token,
        string memory tradeId,
        string[] memory links,
        address seller,
        address buyer,
        uint256 tradeCap,
        uint256 sellersPart,
        uint256 timeToResolve
    ) external onlyManager {
        require(
            tradesIdsToTrades[tradeId] == 0,
            "Escrow: Trade already exists"
        );
        bytes32 message = registerProof(
            token,
            tradeId,
            links,
            seller,
            buyer,
            tradeCap,
            sellersPart,
            timeToResolve
        );
        address signer = IAccess(accessControl).preAuthValidations(
            message,
            token,
            signature
        );
        require(
            IAccess(accessControl).isTradeDesk(signer),
            "Escrow: Signer is not a TradeDesk"
        );
        tradesCounter++;
        tradesIdsToTrades[tradeId] = tradesCounter;
        Trade storage trade = trades[tradesCounter];
        trade.tradeId = tradeId;
        trade.seller = seller;
        trade.buyer = buyer;
        trade.tradeCap = tradeCap;
        trade.sellersPart = sellersPart;
        trade.timeToResolve = timeToResolve;

        for (uint256 i = 0; i < links.length; i++) {
            if (
                keccak256(abi.encodePacked(links[i])) !=
                keccak256(abi.encodePacked(""))
            ) {
                trade.links.push(links[i]);
                trade.linksLength++;
            }
        }

        emit TradeRegistered(
            signer,
            tradeId,
            seller,
            buyer,
            tradeCap,
            sellersPart,
            timeToResolve
        );
    }

    /**
     * @dev Validate a trade
     * @param signature Buyer's signature
     * @param token Token address
     * @param tradeId External trade ID
     * @param links Array of links related to the trade
     */
    function validateTrade(
        bytes memory signature,
        bytes32 token,
        string memory tradeId,
        string[] memory links
    ) external onlyManager {
        require(
            tradesIdsToTrades[tradeId] != 0,
            "Escrow: Trade does not exist"
        );
        Trade storage trade = trades[tradesIdsToTrades[tradeId]];
        require(!trade.valid, "Escrow: Trade is already validated");
        require(!trade.finished, "Escrow: Trade is already finished");
        bytes32 message = validateProof(token, tradeId, links);
        address signer = IAccess(accessControl).preAuthValidations(
            message,
            token,
            signature
        );
        require(
            IAccess(accessControl).isSigner(signer),
            "Escrow: Signer is not a manager"
        );
        trade.valid = true;
        for (uint256 i = 0; i < links.length; i++) {
            if (
                keccak256(abi.encodePacked(links[i])) !=
                keccak256(abi.encodePacked(""))
            ) {
                trade.links.push(links[i]);
                trade.linksLength++;
            }
        }
        emit TradeValidated(tradeId);
    }

    /**
     * @dev Pay for a trade
     * @param signature Buyer's signature
     * @param token Token address
     * @param tradeId External trade ID
     * @param links Array of links related to the trade
     * @param buyer Buyer's address
     */
    function payTrade(
        bytes memory signature,
        bytes32 token,
        string memory tradeId,
        string[] memory links,
        address buyer
    ) external onlyManager nonReentrant {
        require(
            tradesIdsToTrades[tradeId] != 0,
            "Escrow: Trade does not exist"
        );
        Trade storage trade = trades[tradesIdsToTrades[tradeId]];
        require(trade.valid, "Escrow: Trade is not validated");
        require(!trade.paid, "Escrow: Trade is already paid");
        require(trade.buyer != address(0), "Escrow: Buyer is not confirmed");
        bytes32 message = payProof(token, tradeId, links, buyer);
        address signer = IAccess(accessControl).preAuthValidations(
            message,
            token,
            signature
        );
        require(
            trade.buyer == signer && trade.buyer == buyer,
            "Escrow: Signer is not the buyer"
        );
        TransferHelper.safeTransferFrom(
            azx,
            buyer,
            address(this),
            trade.tradeCap
        );
        trade.paid = true;
        for (uint256 i = 0; i < links.length; i++) {
            if (
                keccak256(abi.encodePacked(links[i])) !=
                keccak256(abi.encodePacked(""))
            ) {
                trade.links.push(links[i]);
                trade.linksLength++;
            }
        }

        emit TradePaid(tradeId, trade.tradeCap);
    }

    /**
     * @dev Finish a trade
     * @param signature Buyer's signature
     * @param token Token address
     * @param tradeId External trade ID
     * @param links Array of links related to the trade
     */
    function finishTrade(
        bytes memory signature,
        bytes32 token,
        string memory tradeId,
        string[] memory links
    ) external onlyManager {
        require(
            tradesIdsToTrades[tradeId] != 0,
            "Escrow: Trade does not exist"
        );
        Trade storage trade = trades[tradesIdsToTrades[tradeId]];
        require(!trade.finished, "Escrow: Trade is already finished");
        require(trade.paid, "Escrow: Trade is not paid");
        bytes32 message = finishProof(token, tradeId, links);
        address signer = IAccess(accessControl).preAuthValidations(
            message,
            token,
            signature
        );
        require(
            IAccess(accessControl).isTradeDesk(signer),
            "Escrow: Signer is not a TradeDesk"
        );
        trade.finished = true;
        trade.resolveTS = block.timestamp + trade.timeToResolve;
        for (uint256 i = 0; i < links.length; i++) {
            if (
                keccak256(abi.encodePacked(links[i])) !=
                keccak256(abi.encodePacked(""))
            ) {
                trade.links.push(links[i]);
                trade.linksLength++;
            }
        }

        emit TradeFinished(tradeId);
    }

    /**
     * @dev Release a trade (only for admin)
     * @param signature Buyer's signature
     * @param token Token address
     * @param tradeId External trade ID
     * @param links Array of links related to the trade
     * @param buyer Buyer's address
     */
    function releaseTrade(
        bytes memory signature,
        bytes32 token,
        string memory tradeId,
        string[] memory links,
        address buyer
    ) external nonReentrant onlyManager {
        require(
            tradesIdsToTrades[tradeId] != 0,
            "Escrow: Trade does not exist"
        );
        Trade storage trade = trades[tradesIdsToTrades[tradeId]];
        require(trade.buyer != address(0), "Escrow: Buyer is not confirmed");
        bytes32 message = releaseProof(token, tradeId, links, buyer);
        address signer = IAccess(accessControl).preAuthValidations(
            message,
            token,
            signature
        );
        require(
            trade.buyer == signer && trade.buyer == buyer,
            "Escrow: Signer is not the buyer"
        );
        require(!trade.released, "Escrow: Trade is already released");
        require(trade.finished, "Escrow: Trade is not finished");
        TransferHelper.safeTransfer(azx, trade.seller, trade.sellersPart);
        TransferHelper.safeTransfer(
            azx,
            ntzcWallet,
            trade.tradeCap - trade.sellersPart
        );
        trade.released = true;
        for (uint256 i = 0; i < links.length; i++) {
            if (
                keccak256(abi.encodePacked(links[i])) !=
                keccak256(abi.encodePacked(""))
            ) {
                trade.links.push(links[i]);
                trade.linksLength++;
            }
        }

        emit TradeReleased(tradeId, buyer, trade.tradeCap, trade.sellersPart);
    }

    /**
     * @dev Resolve a trade (only for admin). Used for resolving disputes.
     * @param signature Buyer's signature
     * @param token Token address
     * @param tradeId External trade ID
     * @param links Array of links related to the trade
     * @param result Result of the trade
     * @param reason Reason for the trade resolution
     */
    function resolveTrade(
        bytes memory signature,
        bytes32 token,
        string memory tradeId,
        string[] memory links,
        bool result,
        string memory reason
    ) external nonReentrant {
        require(
            tradesIdsToTrades[tradeId] != 0,
            "Escrow: Trade does not exist"
        );
        Trade storage trade = trades[tradesIdsToTrades[tradeId]];
        require(!trade.released, "Escrow: Trade is already released");
        require(
            block.timestamp >= trade.resolveTS,
            "Escrow: Too early to resolve"
        );

        bytes32 message = resolveProof(token, tradeId, links, result, reason);
        address signer = IAccess(accessControl).preAuthValidations(
            message,
            token,
            signature
        );
        require(
            IAccess(accessControl).isSigner(signer),
            "Escrow: Signer is not a manager"
        );

        if (trade.paid) {
            if (result) {
                TransferHelper.safeTransfer(
                    azx,
                    trade.seller,
                    trade.sellersPart
                );
                TransferHelper.safeTransfer(
                    azx,
                    ntzcWallet,
                    trade.tradeCap - trade.sellersPart
                );
            } else {
                TransferHelper.safeTransfer(azx, trade.buyer, trade.tradeCap);
            }
        }

        trade.released = true;
        for (uint256 i = 0; i < links.length; i++) {
            if (
                keccak256(abi.encodePacked(links[i])) !=
                keccak256(abi.encodePacked(""))
            ) {
                trade.links.push(links[i]);
                trade.linksLength++;
            }
        }

        emit TradeResolved(signer, tradeId, result, reason);
    }

    /**
     * @dev Get the trade details by external trade ID
     * @param tradeId External trade ID
     */
    function getTrade(
        string memory tradeId
    )
        external
        view
        returns (
            string[] memory links,
            address seller,
            address buyer,
            uint256 linksLength,
            uint256 tradeCap,
            uint256 sellersPart,
            bool valid,
            bool paid,
            bool finished,
            bool released
        )
    {
        Trade storage trade = trades[tradesIdsToTrades[tradeId]];
        links = trade.links;
        linksLength = trade.linksLength;
        seller = trade.seller;
        buyer = trade.buyer;
        tradeCap = trade.tradeCap;
        sellersPart = trade.sellersPart;
        valid = trade.valid;
        paid = trade.paid;
        finished = trade.finished;
        released = trade.released;
    }

    /**
     * @dev Get the ID of the executing chain
     * @return uint256 value
     */
    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * @dev Get the message hash for signing the validation of TradeDesk status
     */
    function tradeDeskProof(
        bytes32 token,
        address user,
        bool isTradeDesk
    ) public view returns (bytes32 message) {
        message = keccak256(
            abi.encodePacked(getChainID(), token, user, isTradeDesk)
        );
    }

    /**
     * @dev Get the message hash for signing the registration of a trade
     */
    function registerProof(
        bytes32 token,
        string memory tradeId,
        string[] memory links,
        address seller,
        address buyer,
        uint256 tradeCap,
        uint256 sellersPart,
        uint256 timeToResolve
    ) public view returns (bytes32 message) {
        if (links.length == 0) links[0] = "";
        message = keccak256(
            abi.encodePacked(
                getChainID(),
                token,
                tradeId,
                links[0],
                seller,
                buyer,
                tradeCap,
                sellersPart,
                timeToResolve
            )
        );
    }

    /**
     * @dev Get the message hash for signing the validation of a trade
     */
    function validateProof(
        bytes32 token,
        string memory tradeId,
        string[] memory links
    ) public view returns (bytes32 message) {
        if (links.length == 0) links[0] = "";
        message = keccak256(
            abi.encodePacked(getChainID(), token, tradeId, links[0])
        );
    }

    /**
     * @dev Get the message hash for signing the payment of a trade
     */
    function payProof(
        bytes32 token,
        string memory tradeId,
        string[] memory links,
        address buyer
    ) public view returns (bytes32 message) {
        if (links.length == 0) links[0] = "";
        message = keccak256(
            abi.encodePacked(getChainID(), token, tradeId, links[0], buyer)
        );
    }

    /**
     * @dev Get the message hash for signing the finish of a trade
     */
    function finishProof(
        bytes32 token,
        string memory tradeId,
        string[] memory links
    ) public view returns (bytes32 message) {
        if (links.length == 0) links[0] = "";
        message = keccak256(
            abi.encodePacked(token, links[0], tradeId, getChainID())
        );
    }

    /**
     * @dev Get the message hash for signing the release of a trade
     */
    function releaseProof(
        bytes32 token,
        string memory tradeId,
        string[] memory links,
        address buyer
    ) public view returns (bytes32 message) {
        if (links.length == 0) links[0] = "";
        message = keccak256(
            abi.encodePacked(buyer, getChainID(), links[0], token, tradeId)
        );
    }

    /**
     * @dev Get the message hash for signing the resolution of a trade
     */
    function resolveProof(
        bytes32 token,
        string memory tradeId,
        string[] memory links,
        bool result,
        string memory reason
    ) public view returns (bytes32 message) {
        if (links.length == 0) links[0] = "";
        message = keccak256(
            abi.encodePacked(
                getChainID(),
                token,
                links[0],
                tradeId,
                result,
                reason
            )
        );
    }
}
