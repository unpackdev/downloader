pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";

import "./IProducts.sol";
import "./IQueue.sol";
import "./IToken.sol";
import "./ITreasury.sol";

import "./Permit.sol";
import "./SafeMathExt.sol";
import "./UintSet.sol";

contract Trading {

    /* Libraries */

    using SafeMath for uint256;
    using SafeMathExt for uint256;
    using UintSet for UintSet.Set;

    /* Structs */

    struct Position {
        address sender; // 20 bytes
        bytes12 symbol; // 12 bytes
        uint64 margin; // 8 bytes
        uint64 leverage; // 8 bytes
        uint64 price; // 8 bytes
        uint48 block; // 7 bytes
        bool isBuy; // 1 byte
        uint256 id; // not stored
    }

    /* Variables */

    address private products;
    address private queue;
    address private treasury;

    // DAI
    address public currency;

    // minimum margin to open a position
    uint256 public minimumMargin;

    // 10^18 for DAI
    uint256 public currencyUnit;

    // user => balance
    mapping(address => uint256) public freeMargins;

    // id => Position
    mapping(uint256 => Position) public positions;

    // user => position ids
    mapping(address => UintSet.Set) private userPositionIds;

    // positions being liquidated
    mapping(uint256 => bool) public liquidatingIds;

    // user => bool
    mapping(address => uint256) public pausedUsers;

    // liquidator reward %
    uint256 public liquidatorReward;

    address public owner;
    bool private initialized;
    bool public paused;

    /* Events */
    event NewContracts(address products, address queue, address treasury);
    event NewMinimum(uint256 amount);
    event NewLiquidatorReward(uint256 amount);
    event Deposited(uint256 amount);
    event Withdrew(uint256 amount);

    event OrderSubmitted(
        uint256 id,
        address indexed sender,
        bool isBuy,
        bytes32 symbol,
        uint256 margin,
        uint256 leverage,
        uint256 positionId
    );

    event OrderCancelled(
        uint256 id,
        uint256 positionId,
        address indexed sender,
        string reason
    );

    event PositionOpened(
        uint256 positionId,
        address indexed sender,
        bool isBuy,
        bytes32 symbol,
        uint256 margin,
        uint256 leverage,
        uint256 price
    );

    event PositionLiquidated(
        uint256 positionId,
        address indexed sender,
        address indexed liquidator,
        uint256 marginLiquidated
    );

    event PositionClosed(
        uint256 positionId,
        address indexed sender,
        uint256 marginClosed,
        uint256 amountToReturn,
        uint256 entryPrice,
        uint256 price,
        uint256 leverage
    );

    event LiquidationSubmitted(
        uint256 id,
        uint256 positionId,
        address indexed sender
    );

    /* Initializer (called only once) */

    function initialize(address _currency) public {
        require(!initialized, '!initialized');
        initialized = true;
        owner = msg.sender;
        liquidatorReward = 10;
        currency = _currency;
        currencyUnit = SafeMathExt.base10pow(IToken(_currency).decimals());
    }

    /* Methods called by governance */

    function registerContracts(
        address _products,
        address _queue,
        address _treasury
    ) external onlyOwner {
        products = _products;
        queue = _queue;
        treasury = _treasury;
        emit NewContracts(_products, _queue, _treasury);
    }

    function setCurrencyMin(uint256 _amount) external onlyOwner {
        minimumMargin = _amount;
        emit NewMinimum(_amount);
    }

    function setLiquidatorReward(uint256 _amount) external onlyOwner {
        require(_amount <= 100, '!percent');
        liquidatorReward = _amount;
        emit NewLiquidatorReward(_amount);
    }

    function pauseUsers(address[] calldata users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            pausedUsers[users[i]] = block.number;
        }
    }

    function unpauseUsers(address[] calldata users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            pausedUsers[users[i]] = 0;
        }
    }

    // TODO review
    function capUserBalance(
        address user,
        uint256 newBalanceCap
    ) external onlyOwner {
        // user must be blocked in a previous transaction before we can cap the balance
        uint256 pauseBlockNumber = pausedUsers[user];
        require(pauseBlockNumber > 0 && pauseBlockNumber < block.number, '!user_not_paused');
        uint256 treasuryBalance = ITreasury(treasury).getUserBalance(user);
        // trading balance and newBalance are 8 decimals, treasuryBalance 18 decimals (in most cases)
        require(newBalanceCap.mulDecimal8(currencyUnit) >= treasuryBalance, '!too_low');
        if (freeMargins[user] > newBalanceCap) {
            freeMargins[user] = newBalanceCap;
        }
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    /* Methods called by the client */

    function deposit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused {
        uint256 amt = amount.mulDecimal8(currencyUnit);
        Permit.permit(currency, amt, msg.sender, treasury, deadline, v, r, s);
        ITreasury(treasury).userDeposit(msg.sender, amt);
        freeMargins[msg.sender] = freeMargins[msg.sender].add(amount);
        emit Deposited(amount);
    }

    function withdraw(
        uint256 amount
    ) external whenNotPaused whenNotUserPaused(msg.sender) {
        freeMargins[msg.sender] = freeMargins[msg.sender].sub(amount, '!balance');
        ITreasury(treasury).userWithdraw(msg.sender, amount.mulDecimal8(currencyUnit));
        emit Withdrew(amount);
    }

    function submitOrder(
        bool isBuy,
        bytes32 symbol,
        uint256 margin,
        uint256 leverage
    ) external whenNotPaused whenNotUserPaused(msg.sender) {
        require(margin >= minimumMargin, '!margin');
        require(leverage >= SafeMathExt.UNIT8, '!leverage');
        uint256 maxLeverage = IProducts(products).getMaxLeverage(symbol, true);
        require(maxLeverage > 0, '!symbol');
        require(leverage <= maxLeverage, '!max_leverage');
        freeMargins[msg.sender] = freeMargins[msg.sender].sub(margin, '!balance');
        uint256 id = _queueOrder(isBuy, symbol, margin, leverage, 0, address(0));
        positions[id] = Position({isBuy: isBuy, margin: SafeMathExt.safeUint64(margin), leverage: SafeMathExt.safeUint64(leverage), sender: msg.sender, symbol: bytes12(''), price: 0, block: 0, id: 0});
    }

    function submitOrderUpdate(
        uint256 positionId,
        uint256 margin
    ) external whenNotPaused {
        Position storage position = positions[positionId];
        require(position.price > 0, '!found');
        require(position.sender == msg.sender, '!authorized');
        // partial or full close
        require(margin <= uint256(position.margin), '!margin');
        _queueOrder(!position.isBuy, bytes32(position.symbol), margin, uint256(position.leverage), positionId, address(0));
    }

    function liquidatePositions(uint256[] calldata positionIds) external {
        uint256 length = positionIds.length;
        require(length < 6, '!too_many');
        for (uint256 i = 0; i < length; i++) {
            uint256 positionId = positionIds[i];
            Position storage position = positions[positionId];
            if (position.price > 0 && !liquidatingIds[positionId]) {
                liquidatingIds[positionId] = true;
                _queueOrder(!position.isBuy, bytes32(position.symbol), 0, 0, positionId, msg.sender);
            }
        }
    }

    function getUserPositions(address user) external view returns(Position[] memory _positions) {
        uint256 length = userPositionIds[user].length();
        _positions = new Position[](length);
        for (uint256 i=0; i < length; i++) {
            uint256 id = userPositionIds[user].at(i);
            Position memory positionWithId = positions[id];
            positionWithId.id = id;
            _positions[i] = positionWithId;
        }
        return _positions;
    }

    function getUserFreeMargin(address user) external view returns(uint256) {
        return freeMargins[user];
    }

    /* Queue methods */

    function processOrder(
        uint256 id,
        bytes32 symbol,
        uint256 price,
        uint256 margin,
        uint256 positionId,
        address liquidator
    ) external whenNotPaused onlyQueue {
        if (positionId > 0) {
            if (liquidator != address(0)) {
                delete liquidatingIds[positionId];
                Position memory position = positions[positionId];
                require(position.price > 0, '!found');
                uint256 positionMargin = uint256(position.margin);
                (uint256 pnl, bool isPnlNegative) = _calculatePnl(position, positionMargin, price);
                if (isPnlNegative && pnl >= positionMargin) {
                    _processLiquidation(liquidator, positionId, positionMargin, position.sender);
                }
            } else {
                _processClose(margin, price, positionId);
            }
        } else {
            _processOpen(id, symbol, price);
        }
    }

    function cancelOrder(
        uint256 id,
        uint256 positionId,
        address liquidator,
        string calldata reason
    ) external onlyQueue {
        if (positionId == 0) {
            // cancelling a new order
            Position storage position = positions[id];
            address sender = position.sender;
            uint256 margin = uint256(position.margin);
            delete positions[id];
            // release margin back to user
            freeMargins[sender] = freeMargins[sender].add(margin);
            emit OrderCancelled(id, id, sender, reason);
        } else if (liquidator != address(0)) {
            // cancelling a liquidation request
            delete liquidatingIds[id];
            emit OrderCancelled(id, positionId, liquidator, reason);
        } else {
            // cancelling a full or partial close order (sender could be address zero)
            emit OrderCancelled(id, positionId, positions[positionId].sender, reason);
        }
    }

    /* Internal methods */

    function _queueOrder(
        bool isBuy,
        bytes32 symbol,
        uint256 margin,
        uint256 leverage,
        uint256 positionId,
        address liquidator
    ) internal returns (uint256 id) {
        id = IQueue(queue).queueOrder(symbol, margin, positionId, liquidator);

        if (liquidator != address(0)) {
            emit LiquidationSubmitted(id, positionId, msg.sender);
        } else {
            emit OrderSubmitted(id, msg.sender, isBuy, symbol, margin, leverage, positionId);
        }
        return id;
    }

    function _processOpen(
        uint256 id,
        bytes32 symbol,
        uint256 price
    ) internal {
        Position storage position = positions[id];
        bool isBuy = position.isBuy;
        uint256 margin = uint256(position.margin);
        uint256 leverage = uint256(position.leverage);
        address sender = position.sender;
        // calculate execution price
        uint256 spread = IProducts(products).getSpread(symbol);
        if (isBuy) {
            price = price.mulDecimal8(SafeMathExt.UNIT8.add(spread));
        } else {
            price = price.mulDecimal8(SafeMathExt.UNIT8.sub(spread));
        }
        // complete the Position struct started in submitOrder
        position.symbol = bytes12(symbol);
        position.price = SafeMathExt.safeUint64(price);
        position.block = uint48(block.number);
        // user to position ID
        userPositionIds[sender].add(id);
        // event
        emit PositionOpened(id, sender, isBuy, symbol, margin, leverage, price);
    }

    function _processClose(
        uint256 margin,
        uint256 price,
        uint256 positionId
    ) internal {
        Position memory mPosition = positions[positionId];
        uint256 positionMargin = uint256(mPosition.margin);
        require(margin <= positionMargin, '!margin');
        uint256 spread = IProducts(products).getSpread(bytes32(mPosition.symbol));
        // execution price
        if (mPosition.isBuy) {
            price = price.mulDecimal8(SafeMathExt.UNIT8.sub(spread));
        } else {
            price = price.mulDecimal8(SafeMathExt.UNIT8.add(spread));
        }
        // pnl
        (uint256 pnl, bool isPnlNegative) = _calculatePnl(mPosition, margin, price);
        uint256 amountToReturn;
        if (isPnlNegative && pnl >= margin) {
            // position is liquidated
            delete positions[positionId];
            userPositionIds[mPosition.sender].remove(positionId);
            // transfer user margin to surplus
            ITreasury(treasury).collectFromUser(mPosition.sender, positionMargin.mulDecimal8(currencyUnit));
        } else {
            if (margin < positionMargin) {
                // partial close, update position margin
                Position storage position = positions[positionId];
                position.margin = SafeMathExt.safeUint64(positionMargin.sub(margin));
            } else {
                // full close, remove from mappings
                delete positions[positionId];
                userPositionIds[mPosition.sender].remove(positionId);
            }
            if (isPnlNegative) {
                amountToReturn = margin.sub(pnl);
                // return amountToReturn to free margin
                freeMargins[mPosition.sender] = freeMargins[mPosition.sender].add(amountToReturn);
                // collect pnl
                ITreasury(treasury).collectFromUser(mPosition.sender, pnl.mulDecimal8(currencyUnit));
            } else {
                amountToReturn = margin.add(pnl);
                freeMargins[mPosition.sender] = freeMargins[mPosition.sender].add(amountToReturn);
            }
        }
        emit PositionClosed(positionId, mPosition.sender, margin, amountToReturn, mPosition.price, price, mPosition.leverage);
    }

    function _processLiquidation(
        address liquidator,
        uint256 positionId,
        uint256 positionMargin,
        address positionSender
    ) internal {
        delete positions[positionId];
        userPositionIds[positionSender].remove(positionId);
        // collect margin from user
        ITreasury(treasury).collectFromUser(positionSender, positionMargin.mulDecimal8(currencyUnit));
        // pay liquidatorReward % of margin to liquidator
        uint256 liquidatorMargin = positionMargin.mul(liquidatorReward).div(100);
        freeMargins[liquidator] = freeMargins[liquidator].add(liquidatorMargin);
        ITreasury(treasury).payToUser(liquidator, liquidatorMargin.mulDecimal8(currencyUnit));
        emit PositionLiquidated(positionId, positionSender, liquidator, positionMargin);
    }

    /* Helpers */

    function _calculatePnl(
        Position memory position,
        uint256 margin,
        uint256 price
    ) internal view returns (uint256 pnl, bool isPnlNegative) {
        uint256 positionLeverage = uint256(position.leverage);
        uint256 positionPrice = uint256(position.price);
        if (position.isBuy) {
            if (price >= position.price) {
                pnl = margin.mul(positionLeverage).mul(price.sub(positionPrice)).div(positionPrice).div(SafeMathExt.UNIT8);
            } else {
                pnl = margin.mul(positionLeverage).mul(positionPrice.sub(price)).div(positionPrice).div(SafeMathExt.UNIT8);
                isPnlNegative = true;
            }
        } else {
            if (price > position.price) {
                pnl = margin.mul(positionLeverage).mul(price.sub(positionPrice)).div(positionPrice).div(SafeMathExt.UNIT8);
                isPnlNegative = true;
            } else {
                pnl = margin.mul(positionLeverage).mul(positionPrice.sub(price)).div(positionPrice).div(SafeMathExt.UNIT8);
            }
        }
        // Calculate funding to apply on this position
        uint256 fundingToApply = margin.mul(positionLeverage).mul(block.number.sub(uint256(position.block))).mul(IProducts(products).getFundingRate(bytes32(position.symbol))).div(1e16);
        // Subtract funding from pnl
        if (isPnlNegative) {
            pnl = pnl.add(fundingToApply);
        } else if (fundingToApply > pnl) {
            isPnlNegative = true;
            pnl = fundingToApply.sub(pnl);
        } else {
            pnl = pnl.sub(fundingToApply);
        }
        return (pnl, isPnlNegative);
    }

    /* Modifiers */

    modifier onlyOwner() {
        require(msg.sender == owner, '!authorized');
        _;
    }

    modifier onlyQueue() {
        require(msg.sender == queue, '!authorized');
        _;
    }

    modifier whenNotUserPaused(address user) {
        require(pausedUsers[user] == 0, '!pausedUser');
        _;
    }

    modifier whenNotPaused() {
        require(!paused, '!paused');
        _;
    }

}