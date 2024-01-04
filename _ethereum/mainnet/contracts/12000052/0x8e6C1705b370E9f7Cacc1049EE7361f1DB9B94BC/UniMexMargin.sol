// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./Uniswap.sol";
import "./IUniMexFactory.sol";

import "./console.sol";

interface IUniMexStaking {
    function distribute(uint256 _amount) external;
}

interface IUniMexPool {
    function borrow(uint256 _amount) external;
    function distribute(uint256 _amount) external;
    function repay(uint256 _amount) external returns (bool);
}

contract UniMexMargin is Ownable, AccessControl, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeERC20 for IERC20;

    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

    address private WETH_ADDRESS;
    IERC20 public WETH;
    uint256 public constant MAG = 1e18;
    uint256 public constant LIQUIDATION_MARGIN = 1.1e18; //11%
    uint256 public thresholdGasPrice = 3e8; //gas price in wei used to calculate bonuses for liquidation, sl, tp
    uint32 public borrowInterestPercentScaled = 100; //10%
    uint256 public constant YEAR = 31536000;
    uint256 public positionNonce = 0;
    bool public paused = false;

    uint256 public amountThresholds;

    struct Position {
        uint256 owed;
        uint256 input;
        uint256 commitment;
        address token;
        bool isShort;
        uint32 startTimestamp;
        uint32 borrowInterest;
        address owner;
        uint32 stopLossPercent;
        uint32 takeProfitPercent;
    }

    struct Limit {
        uint256 amount;
        uint256 minimalSwapAmount;
        address token;
        bool isShort;
        uint32 validBefore;
        uint32 leverageScaled;
        address owner;
        uint32 takeProfitPercent;
        uint32 stopLossPercent;
        uint256 escrowAmount;
    }
    
    mapping(bytes32 => Position) public positionInfo;
    mapping(bytes32 => Limit) public limitOrders;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public escrow;
    
    IUniMexStaking public staking;
    IUniMexFactory public unimex_factory;
    IUniswapV2Factory public uniswap_factory;
    IUniswapV2Router02 public uniswap_router;

    event OnClosePosition(
        bytes32 indexed positionId,
        address token,
        address indexed owner,
        uint256 owed,
        uint256 input,
        uint256 commitment,
        uint32 startTimestamp,
        bool isShort,
        uint256 borrowInterest,
        uint256 liquidationBonus, //amount that went to liquidator when position was liquidated. 0 if position was closed
        uint256 scaledCloseRate // weth/token multiplied by 1e18
    );

    event OnOpenPosition(
        address indexed sender,
        bytes32 positionId,
        bool isShort,
        address indexed token,
        uint256 scaledLeverage
    );

    event OnAddCommitment(
        bytes32 indexed positionId,
        uint256 amount
    );

    event OnLimitOrder(
        bytes32 indexed limitOrderId,
        address indexed owner,
        address token,
        uint256 amount,
        uint256 minimalSwapAmount,
        uint256 leverageScaled,
        uint256 validBefore,
        uint256 escrowAmount,
        uint32 takeProfitPercent,
        uint32 stopLossPercent,
        bool isShort
    );

    event OnLimitOrderCancelled(
        bytes32 indexed limitOrderId
    );

    event OnLimitOrderCompleted(
        bytes32 indexed limitOrderId,
        bytes32 positionId
    );

    event OnTakeProfit(
        bytes32 indexed positionId,
        uint256 positionInput,
        uint256 swapAmount,
        address token,
        bool isShort
    );

    event OnStopLoss(
        bytes32 indexed positionId,
        uint256 positionInput,
        uint256 swapAmount,
        address token,
        bool isShort
    );

    //to prevent flashloans
    modifier isHuman() {
        require(msg.sender == tx.origin);
        _;
    }

    constructor(
        address _staking,
        address _factory,
        address _weth,
        address _uniswap_factory,
        address _uniswap_router
    ) public {
        staking = IUniMexStaking(_staking);
        unimex_factory = IUniMexFactory(_factory);
        WETH_ADDRESS = _weth;
        WETH = IERC20(_weth);
        uniswap_factory = IUniswapV2Factory(_uniswap_factory);
        uniswap_router = IUniswapV2Router02(_uniswap_router);

        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        amountThresholds = 275;
    }

    function deposit(uint256 _amount) public {
        WETH.safeTransferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_amount);
    }

    function withdraw(uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
        WETH.safeTransfer(msg.sender, _amount);
    }

    function calculateBorrowInterest(bytes32 positionId) public view returns (uint256) {
        Position storage position = positionInfo[positionId];
        uint256 loanTime = block.timestamp.sub(position.startTimestamp);
        return position.owed.mul(loanTime).mul(position.borrowInterest).div(1000).div(YEAR);
    }

    function openShortPosition(address token, uint256 amount, uint256 scaledLeverage, uint256 minimalSwapAmount) public isHuman {
        uint256[5] memory values = [amount, scaledLeverage, minimalSwapAmount, 0, 0];
        _openPosition(msg.sender, token, true, values);
    }

    function openLongPosition(address token, uint256 amount, uint256 scaledLeverage, uint256 minimalSwapAmount) public isHuman {
        uint256[5] memory values = [amount, scaledLeverage, minimalSwapAmount, 0, 0];
        _openPosition(msg.sender, token, false, values);
    }

    function openShortPositionWithSlTp(address token, uint256 amount, uint256 scaledLeverage, uint256 minimalSwapAmount,
        uint256 takeProfitPercent, uint256 stopLossPercent) public isHuman {
        uint256[5] memory values = [amount, scaledLeverage, minimalSwapAmount, takeProfitPercent, stopLossPercent];
        _openPosition(msg.sender, token, true, values);
    }

    function openLongPositionWithSlTp(address token, uint256 amount, uint256 scaledLeverage, uint256 minimalSwapAmount,
            uint256 takeProfitPercent, uint256 stopLossPercent) public isHuman {
        uint256[5] memory values = [amount, scaledLeverage, minimalSwapAmount, takeProfitPercent, stopLossPercent];
        _openPosition(msg.sender, token, false, values);
    }

    /**
    * values[0] amount
    * values[1] scaledLeverage
    * values[2] minimalSwapAmount
    * values[3] takeProfitPercent
    * values[4] stopLossPercent
    */
    function _openPosition(address owner, address token, bool isShort, uint256[5] memory values)
                                                                        private nonReentrant returns (bytes32) {
        require(!paused, "PAUSED");
        require(values[0] > 0, "AMOUNT_ZERO");
        require(values[4] < 1e6, "STOPLOSS EXCEEDS MAX");
        address pool = unimex_factory.getPool(address(isShort ? IERC20(token) : WETH));

        require(pool != address(0), "POOL_DOES_NOT_EXIST");
        require(values[1] <= unimex_factory.getMaxLeverage(token).mul(MAG), "LEVERAGE_EXCEEDS_MAX");

        require(checkPositionAmount(token, values[0], values[1]), "NOT_ENOUGH_UNISWAP_LIQUIDITY");

        uint256 amountInWeth = isShort ? calculateConvertedValue(token, WETH_ADDRESS, values[0]) : values[0];
        uint256 commitment = getCommitment(amountInWeth, values[1]);
        uint256 commitmentWithLb = commitment.add(calculateAutoCloseBonus());
        require(balanceOf[owner] >= commitmentWithLb, "NO_BALANCE");

        IUniMexPool(pool).borrow(values[0]);

        uint256 swap;

        {
            (address baseToken, address quoteToken) = isShort ? (token, WETH_ADDRESS) : (WETH_ADDRESS, token);
            swap = swapTokens(baseToken, quoteToken, values[0]);
            require(swap >= values[2], "INSUFFICIENT_SWAP");
        }

        uint256 fees = (swap.mul(4)).div(1000);

        swap = swap.sub(fees);

        if(!isShort) {
            fees = swapTokens(token, WETH_ADDRESS, fees); // convert fees to ETH
        }

        transferFees(fees, pool);

        transferUserToEscrow(owner, owner, commitmentWithLb);

        positionNonce = positionNonce + 1; //possible overflow is ok
        bytes32 positionId = getPositionId(
            owner,
            token,
            values[0],
            values[1],
            positionNonce
        );

        Position memory position = Position({
            owed: values[0],
            input: swap,
            commitment: commitmentWithLb,
            token: token,
            isShort: isShort,
            startTimestamp: uint32(block.timestamp),
            owner: owner,
            borrowInterest: borrowInterestPercentScaled,
            takeProfitPercent: uint32(values[3]),
            stopLossPercent: uint32(values[4])
        });

        positionInfo[positionId] = position;
        emit OnOpenPosition(owner, positionId, isShort, token, values[1]);
        if(position.takeProfitPercent > 0) {
            emit OnTakeProfit(positionId, swap, position.takeProfitPercent, token, isShort);
        }
        if(position.stopLossPercent > 0) {
            emit OnStopLoss(positionId, swap, position.stopLossPercent, token, isShort);
        }
        return positionId;
    }

    /**
    * @dev add additional commitment to an opened position. The amount
    * must be initially approved
    * @param positionId id of the position to add commitment
    * @param amount the amount to add to commitment
    */
    function addCommitmentToPosition(bytes32 positionId, uint256 amount) public {
        Position storage position = positionInfo[positionId];
        _checkPositionIsOpen(position);
        position.commitment = position.commitment.add(amount);
        WETH.safeTransferFrom(msg.sender, address(this), amount);
        escrow[position.owner] = escrow[position.owner].add(amount);
        emit OnAddCommitment(positionId, amount);
    }

    /**
    * @dev allows anyone to close position if it's loss exceeds threshold
    */
    function setStopLoss(bytes32 positionId, uint32 percentAmount) public {
        require(percentAmount < 1e6, "STOPLOSS EXCEEDS MAX");
        Position storage position = positionInfo[positionId];
        _checkPositionIsOpen(position);
        require(msg.sender == position.owner, "NOT_OWNER");
        position.stopLossPercent = percentAmount;
        emit OnStopLoss(positionId, position.input, percentAmount, position.token, position.isShort);
    }

    /**
    * @dev allows anyone to close position if it's profit exceeds threshold
    */
    function setTakeProfit(bytes32 positionId, uint32 percentAmount) public {
        Position storage position = positionInfo[positionId];
        _checkPositionIsOpen(position);
        require(msg.sender == position.owner, "NOT_OWNER");
        position.takeProfitPercent = percentAmount;
        emit OnTakeProfit(positionId, position.input, percentAmount, position.token, position.isShort);
    }

    function autoClose(bytes32 positionId) public isHuman {
        Position storage position = positionInfo[positionId];
        _checkPositionIsOpen(position);

        //check constraints
        (address baseToken, address quoteToken) = position.isShort ? (WETH_ADDRESS, position.token) : (position.token, WETH_ADDRESS);
        uint256 swapAmount = calculateConvertedValue(baseToken, quoteToken, position.input);
        uint256 hundredPercent = 1e6;
        require((position.takeProfitPercent != 0 && position.owed.mul(hundredPercent.add(position.takeProfitPercent)).div(hundredPercent) <= swapAmount) ||
            (position.stopLossPercent != 0 && position.owed.mul(hundredPercent.sub(position.stopLossPercent)).div(hundredPercent) >= swapAmount), "SL_OR_TP_UNAVAILABLE");

        //withdraw bonus from position commitment
        uint256 closeBonus = calculateAutoCloseBonus();
        position.commitment = position.commitment.sub(closeBonus);
        WETH.safeTransfer(msg.sender, closeBonus);
        transferEscrowToUser(position.owner, address(0), closeBonus);
        _closePosition(positionId, position, 0);
    }

    function calculateAutoOpenBonus() public view returns(uint256) {
        return thresholdGasPrice.mul(510000);
    }

    function calculateAutoCloseBonus() public view returns(uint256) {
        return thresholdGasPrice.mul(270000);
    }

    /**
    * @dev opens position that can be opened at a specific price
    */
    function openLimitOrder(address token, bool isShort, uint256 amount, uint256 minimalSwapAmount,
            uint256 leverageScaled, uint32 validBefore, uint32 takeProfitPercent, uint32 stopLossPercent) public  {
        require(!paused, "PAUSED");
        require(stopLossPercent < 1e6, "STOPLOSS EXCEEDS MAX");
        require(validBefore > block.timestamp, "INCORRECT_EXP_DATE");
        uint256[3] memory values256 = [amount, minimalSwapAmount, leverageScaled];
        uint32[3] memory values32 = [validBefore, takeProfitPercent, stopLossPercent];
        _openLimitOrder(token, isShort, values256, values32);
    }

    /**
    * @dev values256[0] - amount
    *      values256[1] - minimal swap amount
    *      values256[2] - scaled leverage
    *      values32[0] - valid before
    *      values32[1] - take profit percent
    *      values32[2] - stop loss percent
    */
    function _openLimitOrder(address token, bool isShort, uint256[3] memory values256, uint32[3] memory values) private {
        uint256 escrowAmount; //stack depth optimization
        {
            uint256 commitment = isShort ? getCommitment(values256[1], values256[2]) : getCommitment(values256[0], values256[2]);
            escrowAmount = commitment.add(calculateAutoOpenBonus()).add(calculateAutoCloseBonus());
            require(balanceOf[msg.sender] >= escrowAmount, "INSUFFICIENT_BALANCE");
            transferUserToEscrow(msg.sender, msg.sender, escrowAmount);
        }

        bytes32 limitOrderId = _getLimitOrderId(token, values256[0], values256[1], values256[2],
            values[0], msg.sender, isShort);
        Limit memory limitOrder = Limit({
            token: token,
            amount: values256[0],
            minimalSwapAmount: values256[1],
            leverageScaled: uint32(values256[2].div(1e14)),
            validBefore: values[0],
            owner: msg.sender,
            escrowAmount: escrowAmount,
            isShort: isShort,
            takeProfitPercent: values[1],
            stopLossPercent: values[2]
        });
        limitOrders[limitOrderId] = limitOrder;
        emitLimitOrderEvent(limitOrderId, token, values256, values, escrowAmount, isShort);
    }

    function emitLimitOrderEvent(bytes32 limitOrderId, address token, uint256[3] memory values256,
        uint32[3] memory values, uint256 escrowAmount, bool isShort) private  {
        emit OnLimitOrder(limitOrderId, msg.sender, token, values256[0], values[1], values256[2], values[0], escrowAmount,
            values[1], values[2], isShort);
    }

    function cancelLimitOrder(bytes32 limitOrderId) public {
        Limit storage limitOrder = limitOrders[limitOrderId];
        require(limitOrder.owner == msg.sender, "NOT_OWNER");
        transferEscrowToUser(limitOrder.owner, limitOrder.owner, limitOrder.escrowAmount);
        delete limitOrders[limitOrderId];
        emit OnLimitOrderCancelled(limitOrderId);
    }

    function autoOpen(bytes32 limitOrderId) public isHuman {
        //get limit order
        Limit storage limitOrder = limitOrders[limitOrderId];
        require(limitOrder.owner != address(0), "NO_ORDER");
        require(limitOrder.validBefore >= uint32(block.timestamp), "EXPIRED");

        //check open rate
        (address baseToken, address quoteToken) = limitOrder.isShort ? (limitOrder.token, WETH_ADDRESS) : (WETH_ADDRESS, limitOrder.token);
        uint256 swapAmount = calculateConvertedValue(baseToken, quoteToken, limitOrder.amount);
        require(swapAmount >= limitOrder.minimalSwapAmount, "LIMIT_NOT_SATISFIED");

        uint256 openBonus = calculateAutoOpenBonus();
        //transfer bonus from escrow to caller
        WETH.transfer(msg.sender, openBonus);

        transferEscrowToUser(limitOrder.owner, limitOrder.owner, limitOrder.escrowAmount.sub(openBonus));
        transferEscrowToUser(limitOrder.owner, address(0), openBonus);

        //open position for user
        uint256[5] memory values = [limitOrder.amount, uint256(limitOrder.leverageScaled.mul(1e14)),
            limitOrder.minimalSwapAmount, uint256(limitOrder.takeProfitPercent), uint256(limitOrder.stopLossPercent)];

        bytes32 positionId = _openPosition(limitOrder.owner, limitOrder.token, limitOrder.isShort, values);

        //delete order id
        delete limitOrders[limitOrderId];
        emit OnLimitOrderCompleted(limitOrderId, positionId);
    }

    function _getLimitOrderId(address token, uint256 amount, uint256 minSwapAmount,
            uint256 scaledLeverage, uint256 validBefore, address owner, bool isShort) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(token, amount, minSwapAmount, scaledLeverage, validBefore,
            owner, isShort));
    }

    function _checkPositionIsOpen(Position storage position) private view {
        require(position.owner != address(0), "NO_OPEN_POSITION");
    }

    function closePosition(bytes32 positionId, uint256 minimalSwapAmount) external isHuman {
        Position storage position = positionInfo[positionId];
        _checkPositionIsOpen(position);
        require(msg.sender == position.owner, "BORROWER_ONLY");
        _closePosition(positionId, position, minimalSwapAmount);
    }

    function _closePosition(bytes32 positionId, Position storage position, uint256 minimalSwapAmount) private nonReentrant{
        uint256 scaledRate;
        if(position.isShort) {
            scaledRate = _closeShort(positionId, position, minimalSwapAmount);
        }else{
            scaledRate = _closeLong(positionId, position, minimalSwapAmount);
        }
        deletePosition(positionId, position, 0, scaledRate);
    }

    function _closeShort(bytes32 positionId, Position storage position, uint256 minimalSwapAmount) private returns (uint256){
        uint256 input = position.input;
        uint256 owed = position.owed;
        uint256 commitment = position.commitment;

        address pool = unimex_factory.getPool(position.token);

        uint256 poolInterestInTokens = calculateBorrowInterest(positionId);
        uint256 swap = swapTokens(WETH_ADDRESS, position.token, input);
        require(swap >= minimalSwapAmount, "INSUFFICIENT_SWAP");
        uint256 scaledRate = calculateScaledRate(input, swap);
        require(swap >= owed.add(poolInterestInTokens).mul(input).div(input.add(commitment)), "LIQUIDATE_ONLY");

        bool isProfit = owed < swap;
        uint256 amount;

        uint256 fees = poolInterestInTokens > 0 ? calculateConvertedValue(position.token, address(WETH), poolInterestInTokens) : 0;
        if(isProfit) {
            uint256 profitInTokens = swap.sub(owed);
            amount = swapTokens(position.token, WETH_ADDRESS, profitInTokens); //profit in eth
        } else {
            uint256 commitmentInTokens = swapTokens(WETH_ADDRESS, position.token, commitment);
            uint256 remainder = owed.sub(swap);
            require(commitmentInTokens >= remainder, "LIQUIDATE_ONLY");
            amount = swapTokens(position.token, WETH_ADDRESS, commitmentInTokens.sub(remainder)); //return to user's balance
        }
        if(isProfit) {
            if(amount >= fees) {
                transferEscrowToUser(position.owner, position.owner, commitment);
                transferToUser(position.owner, amount.sub(fees));
            } else {
                uint256 remainder = fees.sub(amount);
                transferEscrowToUser(position.owner, position.owner, commitment.sub(remainder));
                transferEscrowToUser(position.owner, address(0), remainder);
            }
        } else {
            require(amount >= fees, "LIQUIDATE_ONLY"); //safety check
            transferEscrowToUser(position.owner, address(0x0), commitment);
            transferToUser(position.owner, amount.sub(fees));
        }
        transferFees(fees, pool);

        transferToPool(pool, position.token, owed);

        return scaledRate;
    }

    function _closeLong(bytes32 positionId, Position storage position, uint256 minimalSwapAmount) private returns (uint256){
        uint256 input = position.input;
        uint256 owed = position.owed;
        address pool = unimex_factory.getPool(WETH_ADDRESS);

        uint256 fees = calculateBorrowInterest(positionId);
        uint256 swap = swapTokens(position.token, WETH_ADDRESS, input);
        require(swap >= minimalSwapAmount, "INSUFFICIENT_SWAP");
        uint256 scaledRate = calculateScaledRate(swap, input);
        require(swap.add(position.commitment) >= owed.add(fees), "LIQUIDATE_ONLY");

        uint256 commitment = position.commitment;

        bool isProfit = swap >= owed;

        uint256 amount = isProfit ? swap.sub(owed) : commitment.sub(owed.sub(swap));

        transferToPool(pool, WETH_ADDRESS, owed);

        transferFees(fees, pool);

        transferEscrowToUser(position.owner, isProfit ? position.owner : address(0x0), commitment);

        transferToUser(position.owner, amount.sub(fees));
        return scaledRate;
    }


    /**
    * @dev helper function, indicates when a position can be liquidated.
    * Liquidation threshold is when position input plus commitment can be converted to 110% of owed tokens
    */
    function canLiquidate(bytes32 positionId) public view returns(bool) {
        Position storage position = positionInfo[positionId];
        uint256 liquidationBonus = calculateAutoCloseBonus();
        uint256 canReturn;
        if(position.isShort) {
            uint256 positionBalance = position.input.add(position.commitment);
            uint256 valueToConvert = positionBalance < liquidationBonus ? 0 : positionBalance.sub(liquidationBonus);
            canReturn = calculateConvertedValue(WETH_ADDRESS, position.token, valueToConvert);
        } else {
            uint256 canReturnOverall = calculateConvertedValue(position.token, WETH_ADDRESS, position.input)
                    .add(position.commitment);
            canReturn = canReturnOverall < liquidationBonus ? 0 : canReturnOverall.sub(liquidationBonus);
        }
        uint256 poolInterest = calculateBorrowInterest(positionId);
        return canReturn < position.owed.add(poolInterest).mul(LIQUIDATION_MARGIN).div(MAG);
    }

    /**
    * @dev Liquidates position and sends a liquidation bonus from user's commitment to a caller.
    * can only be called from account that has the LIQUIDATOR role
    */
    function liquidatePosition(bytes32 positionId, uint256 minimalSwapAmount) external isHuman nonReentrant {
        Position storage position = positionInfo[positionId];
        _checkPositionIsOpen(position);
        uint256 canReturn;
        uint256 poolInterest = calculateBorrowInterest(positionId);

        uint256 liquidationBonus = calculateAutoCloseBonus();
        uint256 liquidatorBonus;
        uint256 scaledRate;
        if(position.isShort) {
            uint256 positionBalance = position.input.add(position.commitment);
            uint256 valueToConvert;
            (valueToConvert, liquidatorBonus) = _safeSubtract(positionBalance, liquidationBonus);
            canReturn = swapTokens(WETH_ADDRESS, position.token, valueToConvert);
            require(canReturn >= minimalSwapAmount, "INSUFFICIENT_SWAP");
            scaledRate = calculateScaledRate(valueToConvert, canReturn);
        } else {
            uint256 swap = swapTokens(position.token, WETH_ADDRESS, position.input);
            require(swap >= minimalSwapAmount, "INSUFFICIENT_SWAP");
            scaledRate = calculateScaledRate(swap, position.input);
            uint256 canReturnOverall = swap.add(position.commitment);
            (canReturn, liquidatorBonus) = _safeSubtract(canReturnOverall, liquidationBonus);
        }
        require(canReturn < position.owed.add(poolInterest).mul(LIQUIDATION_MARGIN).div(MAG), "CANNOT_LIQUIDATE");

        _liquidate(position, canReturn, poolInterest);

        transferEscrowToUser(position.owner, address(0x0), position.commitment);
        WETH.safeTransfer(msg.sender, liquidatorBonus);

        deletePosition(positionId, position, liquidatorBonus, scaledRate);
    }

    function _liquidate(Position memory position, uint256 canReturn, uint256 fees) private {
        address baseToken = position.isShort ? position.token : WETH_ADDRESS;
        address pool = unimex_factory.getPool(baseToken);
        if(canReturn > position.owed) {
            transferToPool(pool, baseToken, position.owed);
            uint256 remainder = canReturn.sub(position.owed);
            if(remainder > fees) { //can pay fees completely
                if(position.isShort) {
                    remainder = swapTokens(position.token, WETH_ADDRESS, remainder);
                    if(fees > 0) { //with fees == 0 calculation is reverted with "UV2: insufficient input amount"
                        fees = calculateConvertedValue(position.token, WETH_ADDRESS, fees);
                        if(fees > remainder) { //safety check
                            fees = remainder;
                        }
                    }
                }
                transferFees(fees, pool);
                transferToUser(position.owner, remainder.sub(fees));
            } else { //all is left is for fees
                if(position.isShort) {
                    //convert remainder to weth
                    remainder = swapTokens(position.token, WETH_ADDRESS, canReturn.sub(position.owed));
                }
                transferFees(remainder, pool);
            }
        } else {
            //return to pool all that's left
            transferToPool(pool, baseToken, canReturn);
        }
    }

    function setStaking(address _staking) external onlyOwner {
        require(_staking != address(0));
        staking = IUniMexStaking(_staking);
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner public {
        paused = true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner public {
        paused = false;
    }

    function setThresholdGasPrice(uint256 gasPrice) public {
        require(hasRole(LIQUIDATOR_ROLE, msg.sender), "NOT_LIQUIDATOR");
        thresholdGasPrice = gasPrice;
    }

    /**
    * @dev set interest rate for tokens owed from pools. Scaled to 10 (e.g. 150 is 15%)
    */
    function setBorrowPercent(uint32 _newPercentScaled) external onlyOwner {
        borrowInterestPercentScaled = _newPercentScaled;
    }

    function calculateScaledRate(uint256 wethAmount, uint256 tokenAmount) private pure returns (uint256 scaledRate) {
        if(tokenAmount == 0) {
            return 0;
        }
        return wethAmount.mul(MAG).div(tokenAmount);
    }

    function transferUserToEscrow(address from, address to, uint256 amount) private {
        require(balanceOf[from] >= amount);
        balanceOf[from] = balanceOf[from].sub(amount);
        escrow[to] = escrow[to].add(amount);
    }

    function transferEscrowToUser(address from, address to, uint256 amount) private {
        require(escrow[from] >= amount);
        escrow[from] = escrow[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);
    }

    function transferToUser(address to, uint256 amount) private {
        balanceOf[to] = balanceOf[to].add(amount);
    }

    function getPositionId(
        address maker,
        address token,
        uint256 amount,
        uint256 leverage,
        uint256 nonce
    ) private pure returns (bytes32 positionId) {
        //date acts as a nonce
        positionId = keccak256(
            abi.encodePacked(maker, token, amount, leverage, nonce)
        );
    }

    function calculateConvertedValue(address baseToken, address quoteToken, uint256 amount) private view returns (uint256) {
        address token0;
        address token1;
        (token0, token1) = UniswapV2Library.sortTokens(baseToken, quoteToken);
        IUniswapV2Pair pair = IUniswapV2Pair(uniswap_factory.getPair(token0, token1));
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 value;
        if (token1 == baseToken) {
            value = UniswapV2Library.getAmountOut(amount, reserve1, reserve0);
        } else {
            value = UniswapV2Library.getAmountOut(amount, reserve0, reserve1);
        }
        return value;
    }

    function swapTokens(address baseToken, address quoteToken, uint256 input) private returns (uint256 swap) {
        if(input == 0) {
            return 0;
        }
        IERC20(baseToken).approve(address(uniswap_router), input);
        address[] memory path = new address[](2);
        path[0] = baseToken;
        path[1] = quoteToken;
        uint256 balanceBefore = IERC20(quoteToken).balanceOf(address(this));

        IUniswapV2Router02(uniswap_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            input,
            0, //checks are done after swap in caller functions
            path,
            address(this),
            block.timestamp
        );

        uint256 balanceAfter = IERC20(quoteToken).balanceOf(address(this));
        swap = balanceAfter.sub(balanceBefore);
    }

    function getCommitment(uint256 _amount, uint256 scaledLeverage) private pure returns (uint256 commitment) {
        commitment = (_amount.mul(MAG)).div(scaledLeverage);
    }

    function transferFees(uint256 fees, address pool) private {
        uint256 halfFees = fees.div(2);

        // Pool fees
        WETH.approve(pool, halfFees);
        IUniMexPool(pool).distribute(halfFees);

        // Staking Fees
        WETH.approve(address(staking), fees.sub(halfFees));
        staking.distribute(fees.sub(halfFees));
    }

    function transferToPool(address pool, address token, uint256 amount) private {
        IERC20(token).approve(pool, amount);
        IUniMexPool(pool).repay(amount);
    }


    function _safeSubtract(uint256 from, uint256 amount) private pure returns (uint256 remainder, uint256 subtractedAmount) {
        if(from < amount) {
            remainder = 0;
            subtractedAmount = from;
        } else {
            remainder = from.sub(amount);
            subtractedAmount = amount;
        }
    }

    function setAmountThresholds(uint32 leverage5) public onlyOwner {
        amountThresholds = leverage5;
    }

    function checkPositionAmount(address token, uint256 amount, uint256 leverageScaled) public view returns (bool) {
        if(leverageScaled <= 1e18) {
            return true;
        }
        address token0;
        address token1;
        (token0, token1) = UniswapV2Library.sortTokens(token, WETH_ADDRESS);
        IUniswapV2Pair pair = IUniswapV2Pair(uniswap_factory.getPair(token0, token1));
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 tokenLiquidity = token0 == token ? reserve0 : reserve1;
        if (leverageScaled <= 2e18) {
            return amount < tokenLiquidity.mul(amountThresholds).mul(1109).div(1000).div(1e4);
        }  else {
            return amount < tokenLiquidity.mul(amountThresholds).div(1e4);
        }
    }

    function deletePosition(bytes32 positionId, Position storage position, uint256 liquidatedAmount, uint256 scaledRate) private {
        emit OnClosePosition(
            positionId,
            position.token,
            position.owner,
            position.owed,
            position.input,
            position.commitment,
            position.startTimestamp,
            position.isShort,
            position.borrowInterest,
            liquidatedAmount,
            scaledRate
        );
        delete positionInfo[positionId];
    }

}
