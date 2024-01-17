// SPDX-License-Identifier: MIT
/*
https://watchchain.com/
*/
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./SignatureChecker.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ERC1155Holder.sol";
import "./Watch721.sol";
import "./Watch1155.sol";

interface Metadata {
    function decimals() external view returns (uint8);
}

contract WatchChain is
    ERC1155Holder,
    Ownable,
    EIP712("Watch Chain Limit Order", "1")
{
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    enum Status {
        NotExist,
        Waiting,
        Presale,
        Trading,
        Sold,
        Canceled
    }

    enum OrderError {
        NoError,
        UnknownMaker,
        Expired,
        Closed,
        BadOrderAmounts,
        InvalidSignature,
        NotEnoughRemaining,
        InsufficientAllowance,
        AmountExceedsBalance,
        BadWatchStatus
    }

    event OrderFilled(
        address taker,
        uint256 shares,
        bytes32 orderHash,
        uint256 remaining,
        uint256 timestamp
    );
    event OrderCanceled(address maker, bytes32 orderHash);
    event AddWatch(
        uint256 watchId,
        uint256 price,
        bytes32 ref,
        uint256 startTime
    );
    event BuyShares(uint256 watchId, address user, uint256 amount);
    event TradeAllowed(uint256 watchId);
    event ProposalCreated(
        uint256 watchId,
        uint256 proposalId,
        address proposer,
        uint256 price
    );
    event ProposalCanceled(uint256 watchId, uint256 proposalId, uint256 shares);
    event ReadyToSell(
        uint256 watchId,
        uint256 minProposalPrice,
        address user,
        uint256 userShares,
        uint256 remainingShares
    );
    event SaleCanceled(uint256 watchId, address user, uint256 remainingShares);
    event ProposalAccepted(
        uint256 watchId,
        uint256 proposalId,
        uint256 price,
        address proposer
    );
    event SwapSharesToQuoteToken(uint256 watchId, uint256 usdtAmount);

    event EditWatch(
        uint256 watchId,
        uint256 price,
        bytes32 ref,
        uint256 startTime
    );

    event RevertFunding(uint256 watchId, address user, uint256 shares);

    struct WcnBalance {
        uint256 id;
        uint256 balance;
        uint256 auction;
        bool isSoleOwner;
        Status status;
    }

    struct WatchInfo {
        bool tradeAllowed;
        address owner;
        uint256 fundingStartTime;
        uint256 price;
        uint256 soldPrice;
        uint256 shares;
        bytes32 ref;
    }

    struct Watch {
        uint256 pid;
        uint256 fundingStartTime;
        uint256 initialPrice;
        uint256 soldPrice;
        uint256 shares;
        uint256 proposalId;
        address proposer;
        uint256 proposalPrice;
        uint256 proposalShares;
        uint256 proposalUnlockTime;
        Status status;
        bytes32 ref;
    }

    struct Propose {
        uint256 id;
        address proposer;
        uint256 price;
        uint256 shares;
        uint256 unlockTime;
    }

    struct Order {
        uint256 salt;
        uint8 orderType;
        uint256 watchId;
        address maker;
        address taker; //address(0) if available to everyone
        uint256 shares;
        uint256 price;
        uint256 expiration;
    }
    struct UserLockUp {
        uint256 proposalId;
        uint256 shares;
        uint256 unlockTime;
    }

    uint256 private constant _ORDER_NEVER_FILLED = 0;
    uint256 private constant _ORDER_CLOSED = 1;
    uint256 private constant _MAX_SHARE_PRICE = 10000000;
    uint256 private constant _SHARES_AMOUNT_STEP = 100;

    uint256 public constant FUNDING_PERIOD = 10 days;
    uint256 public constant TRADING_FEE_BP = 35; //0.35%
    uint256 public constant AUCTION_FEE_BP = 300; //3.00%
    uint8 public constant BUY_LIMIT = 0;
    uint8 public constant SELL_LIMIT = 1;

    bytes32 public constant LIMIT_ORDER_TYPEHASH =
        keccak256(
            "Order(uint256 salt,uint8 orderType,uint256 watchId,address maker,address taker,uint256 shares,uint256 price,uint256 expiration)"
        );

    mapping(bytes32 => uint256) private _remaining;
    IERC20 public immutable quoteToken;
    address public wcnFeeAddress;
    uint256 public immutable quoteTokenDelimiter;
    Watch1155 public erc1155;
    Watch721 public erc721;
    WatchInfo[] public watches;
    mapping(bytes32 => bool) public watchExistence;
    mapping(uint256 => Propose) public proposalsToBuyAll;
    mapping(address => mapping(uint256 => UserLockUp)) public userLockUpInfo;

    modifier status(uint256 watchId, Status st) {
        require(watchStatus(watchId) == st, "disallowed by the current status");
        _;
    }

    modifier checkMultiplicity(uint256 amount) {
        require(
            amount % _SHARES_AMOUNT_STEP == 0,
            "bad amount, should be a multiple of 100"
        );
        _;
    }

    modifier isEOA() {
        require(
            address(msg.sender).code.length == 0 && msg.sender == tx.origin,
            "Only for human"
        );
        _;
    }

    constructor(
        address _quoteToken,
        address _wcnFeeAddress
    ) {
        quoteTokenDelimiter = 10**(Metadata(_quoteToken).decimals());
        quoteToken = IERC20(_quoteToken);
        wcnFeeAddress = _wcnFeeAddress;

        bytes32 deploymentSalt = keccak256(
            abi.encodePacked(address(this), block.number)
        );
        erc1155 = new Watch1155{salt: deploymentSalt}();
        erc721 = new Watch721{salt: deploymentSalt}();
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @param  orderHash - bytes32 order hash
     * @return unfilled amount for order +1. Never filled - if return 0, Closed - if return 1
     */
    function remaining(bytes32 orderHash) external view returns (uint256) {
        return _remaining[orderHash];
    }

    /**
     * @dev cancels order by setting remaining amount to 1 (Closed),the caller should be an order owner
     */
    function cancelOrder(Order memory order) external {
        require(order.maker == msg.sender, "Access denied");
        bytes32 orderHash = hashOrder(order);
        require(_remaining[orderHash] != _ORDER_CLOSED, "already filled");
        _remaining[orderHash] = _ORDER_CLOSED;
        emit OrderCanceled(msg.sender, orderHash);
    }

    /**
     * @param  order - order for checking
     * @param  signature - order maker signature
     * @param  shares - a desired shares amount of order or zero(for all shares)
     * @return enum OrderError, 0- if no error
     */
    function checkOrderError(
        Order memory order,
        bytes calldata signature,
        uint256 shares
    ) external view checkMultiplicity(shares) returns (OrderError) {
        if (order.maker == address(0)) {
            return OrderError.UnknownMaker;
        }

        bool expiration = (order.expiration > block.timestamp);
        if (!expiration) {
            return OrderError.Expired;
        }

        bytes32 orderHash = hashOrder(order);

        uint256 remainingOrderAmount = _remaining[orderHash];

        if (remainingOrderAmount == _ORDER_CLOSED) {
            return OrderError.Closed;
        }

        if (watchStatus(order.watchId) != Status.Trading) {
            return OrderError.BadWatchStatus;
        }

        if (remainingOrderAmount == _ORDER_NEVER_FILLED) {
            // First fill: validate order
            uint256 maxShares = watches[order.watchId].price /
                quoteTokenDelimiter;
            if (
                order.shares < _SHARES_AMOUNT_STEP ||
                order.shares > maxShares ||
                (order.shares % _SHARES_AMOUNT_STEP) != 0 ||
                order.price == 0 ||
                order.price > (_MAX_SHARE_PRICE * quoteTokenDelimiter)
            ) {
                return OrderError.BadOrderAmounts;
            }
            if (
                !SignatureChecker.isValidSignatureNow(
                    order.maker,
                    orderHash,
                    signature
                )
            ) {
                return OrderError.InvalidSignature;
            }
            remainingOrderAmount = order.shares;
        } else {
            unchecked {
                remainingOrderAmount -= 1;
            }
        }

        if (shares > remainingOrderAmount) {
            return OrderError.NotEnoughRemaining;
        }

        bool allowance = (
            order.orderType == 0
                ? quoteToken.allowance(order.maker, address(this)) >=
                    (remainingOrderAmount * order.price)
                : erc1155.isApprovedForAll(order.maker, address(this))
        );
        if (!allowance) {
            return OrderError.InsufficientAllowance;
        }

        if (order.orderType == 0) {
            uint256 balanceQuote = quoteToken.balanceOf(order.maker);
            if (
                balanceQuote <
                (
                    shares > 0
                        ? (shares * order.price)
                        : (remainingOrderAmount * order.price)
                )
            ) {
                return OrderError.AmountExceedsBalance;
            }
        } else {
            uint256 balanceShares = erc1155.balanceOf(
                order.maker,
                order.watchId
            );
            if (balanceShares < (shares > 0 ? shares : remainingOrderAmount)) {
                return OrderError.AmountExceedsBalance;
            }
        }

        return OrderError.NoError;
    }

    /**
     * @param order order quote to fill
     * @param signature order maker signature to confirm quote ownership
     * @param shares NFT-share desired selling amount(for SELL_LIMIT order) or buying amount(for BUY_LIMIT order)
     * should be a multiple of 100 ex: 100 200 300 etc.
     */
    function fillOrder(
        Order memory order,
        bytes calldata signature,
        uint256 shares
    )
        external
        status(order.watchId, Status.Trading)
        checkMultiplicity(shares)
        checkMultiplicity(order.shares)
        isEOA
    {
        require(order.expiration > block.timestamp, "order expired");

        require(
            order.taker == address(0) || order.taker == msg.sender,
            "private order"
        );

        require(order.maker != msg.sender, "filling own order disallowed");

        bytes32 orderHash = hashOrder(order);

        uint256 remainingOrderAmount = _remaining[orderHash];

        require(remainingOrderAmount != _ORDER_CLOSED, "order closed");

        if (remainingOrderAmount == _ORDER_NEVER_FILLED) {
            // First fill: validate order
            require(
                order.shares >= _SHARES_AMOUNT_STEP &&
                    order.price > 0 &&
                    order.price < (_MAX_SHARE_PRICE * quoteTokenDelimiter),
                "bad order amount"
            );
            require(
                SignatureChecker.isValidSignatureNow(
                    order.maker,
                    orderHash,
                    signature
                ),
                "bad signature"
            );
            remainingOrderAmount = order.shares;
        } else {
            unchecked {
                remainingOrderAmount -= 1;
            }
        }

        if (shares > remainingOrderAmount || shares == 0) {
            shares = remainingOrderAmount;
        }

        uint256 quoteTokenAmount = shares * order.price;
        uint256 fee = (quoteTokenAmount * TRADING_FEE_BP) / 10000;
        // Update remaining shares amount in storage
        unchecked {
            remainingOrderAmount -= shares;
            _remaining[orderHash] = remainingOrderAmount + 1;
        }

        if (order.orderType == BUY_LIMIT) {
            erc1155.safeTransferFrom(
                msg.sender,
                order.maker,
                order.watchId,
                shares,
                ""
            );
            if (fee > 0) {
                quoteToken.safeTransferFrom(order.maker, wcnFeeAddress, fee);
                unchecked {
                    quoteTokenAmount -= fee;
                }
            }
            quoteToken.safeTransferFrom(
                order.maker,
                msg.sender,
                quoteTokenAmount
            );
        } else if (order.orderType == SELL_LIMIT) {
            erc1155.safeTransferFrom(
                order.maker,
                msg.sender,
                order.watchId,
                shares,
                ""
            );
            if (fee > 0) {
                quoteToken.safeTransferFrom(msg.sender, wcnFeeAddress, fee);
            }
            quoteToken.safeTransferFrom(
                msg.sender,
                order.maker,
                quoteTokenAmount
            );
        } else {
            revert("unknown order type");
        }

        emit OrderFilled(
            msg.sender,
            shares,
            orderHash,
            remainingOrderAmount,
            block.timestamp
        );
    }

    function hashOrder(Order memory order) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        LIMIT_ORDER_TYPEHASH,
                        order.salt,
                        order.orderType,
                        order.watchId,
                        order.maker,
                        order.taker,
                        order.shares,
                        order.price,
                        order.expiration
                    )
                )
            );
    }

    function numberOfwatches() external view returns (uint256) {
        return watches.length;
    }

    function set1155URI(string memory _newuri) external onlyOwner {
        erc1155.setURI(_newuri);
    }

    function set721BaseURI(string memory _baseURIstring) external onlyOwner {
        erc721.setBaseURI(_baseURIstring);
    }

    function setWcnFeeAddress(address _wcnFeeAddress) external onlyOwner {
        wcnFeeAddress=_wcnFeeAddress;
    }

    function editWatch(
        uint256 watchId,
        uint256 startTime,
        uint256 price,
        bytes32 ref
    )
        external
        status(watchId, Status.Waiting)
        checkMultiplicity(price / quoteTokenDelimiter)
        onlyOwner
    {
        WatchInfo storage watch = watches[watchId];
        require(watchExistence[ref] == false, "this watch already exist");
        startTime = (startTime > block.timestamp ? startTime : block.timestamp);
        uint256 shares = price / quoteTokenDelimiter;
        require(shares > 0, "price is too small");
        watch.fundingStartTime = startTime;
        watch.price = price;
        watch.shares = shares;
        watchExistence[watch.ref] = false;
        watch.ref = ref;
        watchExistence[ref] = true;
        emit EditWatch(watchId, price, ref, startTime);
    }

    /**
     * @param win-hash of Watch Identification Number
     * @param  watchId - ID
     */
    function checkWIN(uint256 watchId, string memory win)
        external
        view
        returns (bool)
    {
        WatchInfo memory watch = watches[watchId];
        return watch.ref == keccak256(abi.encodePacked(win));
    }

    /**
     * @dev add new watch
     * @param  watchOwner - watch owner
     * @param  price - initial watch price
     * @param winHash-hash of Watch Identification Number
     * @param  startTime - pre-sales start time
     */
    function addWatch(
        address watchOwner,
        uint256 price,
        bytes32 winHash,
        uint256 startTime
    ) external checkMultiplicity(price / quoteTokenDelimiter) onlyOwner {
        require(watchExistence[winHash] == false, "this watch already exist");
        uint256 shares = price / quoteTokenDelimiter;
        require(shares > 0, "price is too small");

        startTime = (startTime > block.timestamp ? startTime : block.timestamp);

        watches.push(
            WatchInfo({
                tradeAllowed: false,
                owner: watchOwner,
                fundingStartTime: startTime,
                price: price,
                soldPrice: 0,
                shares: shares,
                ref: winHash
            })
        );

        watchExistence[winHash] = true;
        emit AddWatch(watches.length - 1, price, winHash, startTime);
    }

    /**
     * @dev buying shares at the pre-sale stage
     * @param  amount - amount of shares, should be a multiple of 100 ex: 100 200 300 etc.
     * @param  watchId - ID
     */
    function buyShares(uint256 amount, uint256 watchId)
        external
        status(watchId, Status.Presale)
        checkMultiplicity(amount)
        isEOA
    {
        require(amount > 0, "amount is zero!");
        WatchInfo storage watch = watches[watchId];
        if (amount > watch.shares) {
            amount = watch.shares;
        }

        quoteToken.safeTransferFrom(
            msg.sender,
            address(this),
            amount * quoteTokenDelimiter
        );
        unchecked {
            watch.shares -= amount;
        }
        erc1155.mint(msg.sender, watchId, amount);
        emit BuyShares(watchId, msg.sender, amount);

        if (watch.shares == 0) {
            watch.tradeAllowed = true;
            quoteToken.safeTransfer(watch.owner, watch.price);
            emit TradeAllowed(watchId);
        }
    }

    /**
     * @dev return all bought shares if a funding stage was canceled
     */
    function revertFunding(uint256 watchId)
        external
        status(watchId, Status.Canceled)
    {
        uint256 shareBalance = erc1155.balanceOf(msg.sender, watchId);
        require(shareBalance > 0, "you don't have a shares");
        erc1155.burnFrom(msg.sender, watchId, shareBalance);
        WatchInfo storage watch = watches[watchId];
        unchecked {
            watch.shares += shareBalance;
        }

        quoteToken.safeTransfer(msg.sender, shareBalance * quoteTokenDelimiter);

        emit RevertFunding(watchId, msg.sender, shareBalance);
    }

    /**
     * @return true if the auction proposal exists
     */
    function proposalIsExist(uint256 watchId) external view returns (bool) {
        return (proposalsToBuyAll[watchId].proposer != address(0));
    }

    /**
     * @dev create a proposal or make a better bet for buying all shares
     * @param  watchId - watch ID
     * @param  price - your offered unnormalized price of all shares,
     */
    function proposeToBuyAllShares(uint256 watchId, uint256 price)
        external
        status(watchId, Status.Trading)
        isEOA
    {
        WatchInfo memory watch = watches[watchId];
        Propose storage proposal = proposalsToBuyAll[watchId];
        uint256 allShares = watch.price / quoteTokenDelimiter;
        address proposer = proposal.proposer;
        if (proposer != address(msg.sender)) {
            if (proposer != address(0)) {
                require(price > proposal.price, "price is too small");
                proposal.proposer = address(0);
                quoteToken.safeTransfer(proposer, proposal.price);
            } else {
                require(price > watch.price / 2, "price is too small");
                if (price > watch.price) {
                    unchecked {
                        proposal.shares = (allShares * 2) / 3 + 1;
                    }
                } else {
                    unchecked {
                        proposal.shares = (allShares * 9) / 10 + 1;
                    }
                }
            }

            quoteToken.safeTransferFrom(msg.sender, address(this), price);
            proposal.proposer = msg.sender;
        } else {
            require(price > proposal.price, "price is too small");
            quoteToken.safeTransferFrom(
                msg.sender,
                address(this),
                price - proposal.price
            );
        }
        proposal.unlockTime = block.timestamp + 1 days;

        uint256 oldPrice = proposal.price;
        proposal.price = price;
        emit ProposalCreated(watchId, proposal.id, msg.sender, price);

        if (oldPrice > 0 && oldPrice <= watch.price && price > watch.price) {
            // move threshold from 9/10 to 2/3
            //(9/10-2/3)=7/30
            uint256 diff = (allShares * 7) / 30;
            if (proposal.shares > diff) {
                unchecked {
                    proposal.shares -= diff;
                }
            } else {
                proposal.shares = 0;
                proposalAccepted(watchId, proposal.id, msg.sender, price);
            }
        }
    }

    /**
     * @dev cancels proposal,is allowed after a lockup period of 1 day
     * @param  watchId - watch ID
     */
    function cancelProposal(uint256 watchId)
        external
        status(watchId, Status.Trading)
    {
        Propose storage proposal = proposalsToBuyAll[watchId];
        address proposer = proposal.proposer;
        require(proposer == msg.sender, "caller is not proposer");
        require(proposal.unlockTime < block.timestamp, "locked");
        proposal.proposer = address(0);
        quoteToken.safeTransfer(proposer, proposal.price);
        emit ProposalCanceled(watchId, proposal.id, proposal.shares);
        proposal.id += 1;
    }

    function proposalAccepted(
        uint256 watchId,
        uint256 id,
        address proposer,
        uint256 price
    ) internal {
        uint256 balance1155 = erc1155.balanceOf(address(this), watchId);
        erc1155.burnFrom(address(this), watchId, balance1155);
        watches[watchId].tradeAllowed = false;
        uint256 fee = (price * AUCTION_FEE_BP) / 10000;
        if (fee > 0) {
            quoteToken.safeTransfer(wcnFeeAddress, fee);
        }
        watches[watchId].soldPrice = price - fee;
        erc721.mint(proposer, watchId);
        watchExistence[watches[watchId].ref] = false;
        emit ProposalAccepted(watchId, id, price, proposer);
    }

    /**
     * @dev accept the proposal,lockup your shares in the contract
     * @param  watchId - watch ID
     * @param  shares - amount of shares which will be locked,
     * update if the shares are zero
     */
    function readyToSell(uint256 watchId, uint256 shares)
        external
        status(watchId, Status.Trading)
        isEOA
    {
        Propose storage proposal = proposalsToBuyAll[watchId];
        require(proposal.proposer != address(0), "proposal not exist");
        UserLockUp storage user = userLockUpInfo[msg.sender][watchId];

        if (shares > 0) {
            require(
                user.shares == 0 || user.proposalId == proposal.id,
                "the proposal has changed"
            );
            erc1155.safeTransferFrom(
                msg.sender,
                address(this),
                watchId,
                shares,
                ""
            );
            unchecked {
                user.shares += shares;
            }
        } else if (user.proposalId != proposal.id) {
            shares = user.shares;
        }

        user.proposalId = proposal.id;
        user.unlockTime = block.timestamp + 1 days;

        if (proposal.shares < shares) {
            proposal.shares = 0;
        } else {
            unchecked {
                proposal.shares -= shares;
            }
        }
        emit ReadyToSell(
            watchId,
            proposal.price,
            msg.sender,
            user.shares,
            proposal.shares
        );

        if (proposal.shares == 0) {
            proposalAccepted(
                watchId,
                proposal.id,
                proposal.proposer,
                proposal.price
            );
        }
    }

    /**
     * @dev cancel your acceptance of the proposal and unlock shares,
     * is allowed after a lockup period of 1 day
     * @param  watchId - watch ID
     */
    function cancelSale(uint256 watchId)
        external
        status(watchId, Status.Trading)
    {
        UserLockUp storage user = userLockUpInfo[msg.sender][watchId];
        uint256 shares = user.shares;
        require(shares > 0, "you don't have a locked shares");
        Propose storage proposal = proposalsToBuyAll[watchId];
        require(
            user.unlockTime < block.timestamp ||
                proposal.proposer == address(0) ||
                user.proposalId != proposal.id,
            "locked"
        );
        user.shares = 0;

        if (user.proposalId == proposal.id) {
            unchecked {
                proposal.shares += shares;
            }
        }

        erc1155.safeTransferFrom(
            address(this),
            msg.sender,
            watchId,
            shares,
            ""
        );
        emit SaleCanceled(watchId, msg.sender, proposal.shares);
    }

    /**
     * @dev swap your shares (locked and not locked) to quote token,
     * is allowed after a complete accepted proposal
     * @param  watchId - watch ID
     */
    function swapSharesToQuoteToken(uint256 watchId)
        external
        status(watchId, Status.Sold)
    {
        uint256 userBalance = erc1155.balanceOf(msg.sender, watchId);
        UserLockUp storage user = userLockUpInfo[msg.sender][watchId];
        uint256 lockedShares = user.shares;
        uint256 userShares = lockedShares + userBalance;
        require(userShares > 0, "you don't have a shares");
        user.shares = 0;
        if (userBalance > 0) {
            erc1155.burnFrom(msg.sender, watchId, userBalance);
        }

        WatchInfo memory watch = watches[watchId];
        uint256 usdtAmount = (watch.soldPrice *
            userShares *
            quoteTokenDelimiter) / watch.price;

        quoteToken.safeTransfer(msg.sender, usdtAmount);

        emit SwapSharesToQuoteToken(watchId, usdtAmount);
    }

    /**
     * @param  watchId - watch ID
     * @return current status
     */
    function watchStatus(uint256 watchId) public view returns (Status) {
        if (watchId < watches.length) {
            WatchInfo memory watch = watches[watchId];
            if (watch.shares > 0) {
                if (watch.fundingStartTime > block.timestamp) {
                    return Status.Waiting;
                }
                if (
                    (block.timestamp - watch.fundingStartTime) > FUNDING_PERIOD
                ) {
                    return Status.Canceled;
                }
                return Status.Presale;
            }

            if (watch.tradeAllowed == true) {
                return Status.Trading;
            }

            if (watch.soldPrice > 0) {
                return Status.Sold;
            }
        }

        return Status.NotExist;
    }

    function checkWcnBalance(
        address accounts,
        uint256 startId,
        uint256 endId
    ) external view returns (WcnBalance[] memory) {
        if (endId == 0 || endId > watches.length) {
            endId = watches.length;
        }
        if (endId <= startId) {
            return new WcnBalance[](0);
        }

        uint256 size = endId - startId;

        WcnBalance[] memory wcnBalance = new WcnBalance[](size);
        uint256 balance = 0;
        uint256 auction = 0;
        uint256 count = 0;
        Status currentStatus;
        bool isSoleOwner = false;

        for (uint256 i = startId; i < endId; ) {
            balance = erc1155.balanceOf(accounts, i);
            auction = userLockUpInfo[accounts][i].shares;
            currentStatus = watchStatus(i);
            isSoleOwner = currentStatus == Status.Sold
                ? (erc721.exists(i) && erc721.ownerOf(i) == accounts)
                : false;

            if (balance > 0 || auction > 0 || isSoleOwner) {
                wcnBalance[count].id = i;
                wcnBalance[count].balance = balance;
                wcnBalance[count].auction = auction;
                wcnBalance[count].isSoleOwner = isSoleOwner;
                wcnBalance[count].status = currentStatus;
                count++;
            }
            unchecked {
                i++;
            }
        }
        assembly {
            mstore(wcnBalance, count)
        }

        return (wcnBalance);
    }

    /**
     * @dev get full information about watches using status filters
     * @param  startId - from watchId
     * @param  endId - to watchId
     * @param  limit - limit on the number of returned watches
     * @param  filter - filter with status bits set
     * @param  reverse - reverse mode (from endId to startId)
     */
    function getWatchesByStatusFilter(
        uint256 startId,
        uint256 endId,
        uint256 limit,
        uint256 filter,
        bool reverse
    ) external view returns (Watch[] memory, int256) {
        if (endId == 0 || endId > watches.length) {
            endId = watches.length;
        }
        if (endId <= startId) {
            return (new Watch[](0), 0);
        }
        uint256 size = endId - startId;
        if (limit == 0 || limit > size) {
            limit = size;
        }

        Watch[] memory result = new Watch[](limit);
        uint256 count = 0;
        int256 nextStartId = -1;
        (uint256 i, uint256 end) = reverse
            ? (endId, startId)
            : (startId, endId);

        unchecked {
            do {
                if (reverse) --i;
                Status wStatus = watchStatus(i);

                if (filter & (1 << uint8(wStatus)) != 0) {
                    WatchInfo memory watch = watches[i];
                    Propose memory proposal = proposalsToBuyAll[i];
                    result[count].pid = i;
                    result[count].fundingStartTime = watch.fundingStartTime;
                    result[count].initialPrice = watch.price;
                    result[count].soldPrice = watch.soldPrice;
                    result[count].shares = watch.shares;
                    result[count].proposalId = proposal.id;
                    result[count].proposer = proposal.proposer;
                    result[count].proposalPrice = proposal.price;
                    result[count].proposalShares = proposal.shares;
                    result[count].proposalUnlockTime = proposal.unlockTime;
                    result[count].status = wStatus;
                    result[count].ref = watch.ref;
                    count++;
                }
                if (!reverse) ++i;
            } while (count != limit && reverse ? (i > end) : (i < end));
        }

        if (i > 0 && i < watches.length) {
            nextStartId = int256(i);
        }

        assembly {
            mstore(result, count)
        }

        return (result, nextStartId);
    }
}
