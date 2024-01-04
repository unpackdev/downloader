// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

import "./IX2ETHFactory.sol";
import "./IX2PriceFeed.sol";
import "./IX2Token.sol";
import "./IX2Market.sol";

contract X2ETHMarket is ReentrancyGuard, IX2Market {
    using SafeMath for uint256;

    // use a single storage slot
    // max uint128 has 38 digits so it can support the INITIAL_REBASE_DIVISOR
    // increasing by 10^28 times
    uint128 public override cachedBullDivisor;
    uint128 public override cachedBearDivisor;

    uint256 public constant FEE_BASIS_POINTS = 20; // 0.2% fee
    uint256 public constant MAX_APP_FEE_BASIS_POINTS = 20; // 0.2% max app fee
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    // X2Token.balance uses uint128, max uint128 has 38 digits
    // with an initial rebase divisor of 10^10
    // and 18 decimals for ETH, collateral of up to 10 billion ETH
    // can be supported
    uint128 public constant INITIAL_REBASE_DIVISOR = 10**10;
    uint256 public constant MAX_DIVISOR = uint128(-1);

    uint256 public constant FUNDING_INTERVAL = 1 hours;
    uint256 public constant MIN_FUNDING_DIVISOR = 500;
    uint256 public constant MAX_FUNDING_DIVISOR = 1000000;

    address public factory;

    address public override bullToken;
    address public override bearToken;
    address public priceFeed;
    uint256 public multiplierBasisPoints;
    uint256 public maxProfitBasisPoints;
    uint256 public feeReserve;

    uint256 public appFeeBasisPoints;
    uint256 public appFeeReserve;

    uint256 public fundingDivisor;
    uint256 public lastFundingTime;

    uint256 public override lastPrice;

    bool public isInitialized;

    mapping (address => uint256) public appFees;

    event DistributeFees(address feeReceiver, uint256 amount);
    event DistributeInterest(address feeReceiver, uint256 amount);
    event Rebase(uint256 price, uint128 bullDivisor, uint128 bearDivisor);

    modifier onlyFactory() {
        require(msg.sender == factory, "X2ETHMarket: forbidden");
        _;
    }

    function initialize(
        address _factory,
        address _priceFeed,
        uint256 _multiplierBasisPoints,
        uint256 _maxProfitBasisPoints,
        uint256 _fundingDivisor,
        uint256 _appFeeBasisPoints
    ) public {
        require(!isInitialized, "X2ETHMarket: already initialized");
        require(_maxProfitBasisPoints <= BASIS_POINTS_DIVISOR, "X2ETHMarket: maxProfitBasisPoints limit exceeded");
        isInitialized = true;

        factory = _factory;
        priceFeed = _priceFeed;
        multiplierBasisPoints = _multiplierBasisPoints;
        maxProfitBasisPoints = _maxProfitBasisPoints;
        setFunding(_fundingDivisor);
        setAppFee(_appFeeBasisPoints);

        lastPrice = uint176(latestPrice());
        require(lastPrice != 0, "X2ETHMarket: unsupported price feed");

        _updateLastFundingTime();
    }

    function setAppFee(uint256 _appFeeBasisPoints) public override onlyFactory {
        require(_appFeeBasisPoints <= MAX_APP_FEE_BASIS_POINTS, "X2ETHMarket: fee limit exceeded");
        appFeeBasisPoints = _appFeeBasisPoints;
    }

    function setFunding(uint256 _fundingDivisor) public override onlyFactory {
        require(_fundingDivisor >= MIN_FUNDING_DIVISOR && _fundingDivisor <= MAX_FUNDING_DIVISOR, "X2ETHMarket: funding range exceeded");
        fundingDivisor = _fundingDivisor;
    }

    function setBullToken(address _bullToken) public onlyFactory {
        require(bullToken == address(0), "X2ETHMarket: bullToken already set");
        bullToken = _bullToken;
        cachedBullDivisor = INITIAL_REBASE_DIVISOR;
    }

    function setBearToken(address _bearToken) public onlyFactory {
        require(bearToken == address(0), "X2ETHMarket: bearToken already set");
        bearToken = _bearToken;
        cachedBearDivisor = INITIAL_REBASE_DIVISOR;
    }

    function buy(address _token, address _appFeeReceiver) public payable nonReentrant returns (uint256) {
        return _buy(_token, msg.sender, _appFeeReceiver);
    }

    function sell(address _token, uint256 _sellPoints, address _receiver, address _appFeeReceiver) public nonReentrant returns (uint256) {
        return _sell(_token, _sellPoints, _receiver, true, _appFeeReceiver);
    }

    // since an X2Token's distributor can be set by the factory's gov,
    // the market should allow an option to sell the token without invoking
    // the distributor
    // this ensures that tokens can always be sold even if the distributor
    // is set to an address that intentionally fails when `distribute` is called
    function sellWithoutDistribution(address _token, uint256 _sellPoints, address _receiver) public nonReentrant returns (uint256) {
        return _sell(_token, _sellPoints, _receiver, false, address(0));
    }

    function flip(address _token, uint256 _flipPoints, address _appFeeReceiver) public nonReentrant returns (uint256) {
        return _flip(_token, _flipPoints, msg.sender, _appFeeReceiver);
    }

    function rebase() public returns (bool) {
        uint256 _lastPrice = uint256(lastPrice);
        uint256 nextPrice = latestPrice();
        uint256 intervals = block.timestamp.sub(lastFundingTime).div(FUNDING_INTERVAL);
        if (_lastPrice == nextPrice && intervals == 0) { return false; }

        (uint256 nextBullDivisor, uint256 nextBearDivisor) = getDivisors(_lastPrice, nextPrice);

        lastPrice = nextPrice;
        cachedBullDivisor = uint128(nextBullDivisor);
        cachedBearDivisor = uint128(nextBearDivisor);
        if (intervals > 0) {
            _updateLastFundingTime();
        }

        emit Rebase(nextPrice, uint128(nextBullDivisor), uint128(nextBearDivisor));
        return true;
    }

    function distributeFees() public nonReentrant returns (uint256) {
        address feeReceiver = IX2ETHFactory(factory).feeReceiver();
        require(feeReceiver != address(0), "X2Market: empty feeReceiver");

        uint256 fees = feeReserve;
        feeReserve = 0;

        (bool success,) = feeReceiver.call{value: fees}("");
        require(success, "X2ETHMarket: transfer failed");

        emit DistributeFees(feeReceiver, fees);

        return fees;
    }

    function distributeAppFees(address _appFeeReceiver) public nonReentrant returns (uint256) {
        require(_appFeeReceiver != address(0), "X2Market: empty feeReceiver");

        uint256 fees = appFees[_appFeeReceiver];
        if (fees == 0) { return 0; }

        appFeeReserve = appFeeReserve.sub(fees);
        appFees[_appFeeReceiver] = 0;

        (bool success,) = _appFeeReceiver.call{value: fees}("");
        require(success, "X2ETHMarket: transfer failed");

        emit DistributeFees(_appFeeReceiver, fees);

        return fees;
    }

    function distributeInterest() public nonReentrant returns (uint256) {
        address interestReceiver = IX2ETHFactory(factory).interestReceiver();
        require(interestReceiver != address(0), "X2Market: empty interestReceiver");

        uint256 interest = interestReserve();

        (bool success,) = interestReceiver.call{value: interest}("");
        require(success, "X2ETHMarket: transfer failed");

        emit DistributeInterest(interestReceiver, interest);

        return interest;
    }

    function interestReserve() public view returns (uint256) {
        uint256 bullRefSupply = IX2Token(bullToken)._totalSupply();
        uint256 bearRefSupply = IX2Token(bearToken)._totalSupply();

        // the actual underlying supplies
        uint256 totalBulls = bullRefSupply.div(cachedBullDivisor);
        uint256 totalBears = bearRefSupply.div(cachedBearDivisor);

        uint256 balance = address(this).balance;
        return balance.sub(totalBulls).sub(totalBears).sub(feeReserve).sub(appFeeReserve);
    }

    function getDivisor(address _token) public override view returns (uint256) {
        bool isBull = _token == bullToken;
        uint256 _lastPrice = uint256(lastPrice);
        uint256 nextPrice = latestPrice();
        uint256 intervals = block.timestamp.sub(lastFundingTime).div(FUNDING_INTERVAL);

        if (_lastPrice == nextPrice && intervals == 0) {
            return isBull ? cachedBullDivisor : cachedBearDivisor;
        }

        (uint256 nextBullDivisor, uint256 nextBearDivisor) = getDivisors(_lastPrice, nextPrice);
        return isBull ? nextBullDivisor : nextBearDivisor;
    }

    function latestPrice() public override view returns (uint256) {
        int256 answer = IX2PriceFeed(priceFeed).latestAnswer();
        // avoid negative or zero values being returned
        if (answer <= 0) {
            return uint256(lastPrice);
        }
        return uint256(answer);
    }

    function getFunding() public override view returns (uint256, uint256) {
        uint256 _lastPrice = uint256(lastPrice);
        uint256 nextPrice = latestPrice();
        (uint256 nextBullDivisor, uint256 nextBearDivisor) = getDivisors(_lastPrice, nextPrice);

        uint256 totalBulls = IX2Token(bullToken)._totalSupply().div(nextBullDivisor);
        uint256 totalBears = IX2Token(bearToken)._totalSupply().div(nextBearDivisor);

        if (totalBulls > totalBears && totalBears > 0) {
            uint256 funding = totalBulls.sub(totalBears).div(fundingDivisor);
            return (funding, 0);
        }

        if (totalBears > totalBulls && totalBulls > 0) {
            uint256 funding = totalBears.sub(totalBulls).div(fundingDivisor);
            return (0, funding);
        }

        return (0, 0);
    }

    function getDivisors(uint256 _lastPrice, uint256 _nextPrice) public override view returns (uint256, uint256) {
        uint256 bullRefSupply = IX2Token(bullToken)._totalSupply();
        uint256 bearRefSupply = IX2Token(bearToken)._totalSupply();

        // the actual underlying supplies
        uint256 totalBulls = bullRefSupply.div(cachedBullDivisor);
        uint256 totalBears = bearRefSupply.div(cachedBearDivisor);

        // scope variables to avoid stack too deep errors
        {
        // refSupply is the smaller of the two supplies
        uint256 refSupply = totalBulls < totalBears ? totalBulls : totalBears;
        uint256 delta = _nextPrice > _lastPrice ? _nextPrice.sub(_lastPrice) : _lastPrice.sub(_nextPrice);
        // profit is [(smaller supply) * (change in price) / (last price)] * multiplierBasisPoints
        uint256 profit = refSupply.mul(delta).div(_lastPrice).mul(multiplierBasisPoints).div(BASIS_POINTS_DIVISOR);

        // cap the profit to the (max profit percentage) of the smaller supply
        uint256 maxProfit = refSupply.mul(maxProfitBasisPoints).div(BASIS_POINTS_DIVISOR);
        if (profit > maxProfit) { profit = maxProfit; }

        totalBulls = _nextPrice > _lastPrice ? totalBulls.add(profit) : totalBulls.sub(profit);
        totalBears = _nextPrice > _lastPrice ? totalBears.sub(profit) : totalBears.add(profit);
        }

        {
        uint256 intervals = block.timestamp.sub(lastFundingTime).div(FUNDING_INTERVAL);
        if (intervals > 0) {
            if (totalBulls > totalBears && totalBears > 0) {
                uint256 funding = totalBulls.sub(totalBears).div(fundingDivisor).mul(intervals);
                totalBulls = totalBulls.sub(funding);
                totalBears = totalBears.add(funding);
            }
            if (totalBears > totalBulls && totalBulls > 0) {
                uint256 funding = totalBears.sub(totalBulls).div(fundingDivisor).mul(intervals);
                totalBears = totalBears.sub(funding);
                totalBulls = totalBulls.add(funding);
            }
        }
        }

        return (_getNextDivisor(bullRefSupply, totalBulls, cachedBullDivisor), _getNextDivisor(bearRefSupply, totalBears, cachedBearDivisor));
    }

    function _updateLastFundingTime() private {
        lastFundingTime = block.timestamp;
    }

    function _getNextDivisor(uint256 _refSupply, uint256 _nextSupply, uint256 _fallbackDivisor) private pure returns (uint256) {
        if (_nextSupply == 0) {
            return INITIAL_REBASE_DIVISOR;
        }

        // round up the divisor
        uint256 divisor = _refSupply.mul(10).div(_nextSupply).add(9).div(10);
        // prevent the cachedDivisor from overflowing or being set to 0
        if (divisor == 0 || divisor > MAX_DIVISOR) { return _fallbackDivisor; }

        return divisor;
    }

    function _collectFees(uint256 _amount) private returns (uint256) {
        uint256 fee = _amount.mul(FEE_BASIS_POINTS).div(BASIS_POINTS_DIVISOR);
        feeReserve = feeReserve.add(fee);
        return fee;
    }

    function _collectAppFees(uint256 _amount, address _appFeeReceiver) private returns (uint256) {
        if (appFeeBasisPoints == 0) {
            return 0;
        }
        uint256 fee = _amount.mul(appFeeBasisPoints).div(BASIS_POINTS_DIVISOR);
        appFees[_appFeeReceiver] = appFees[_appFeeReceiver].add(fee);
        appFeeReserve = appFeeReserve.add(fee);
        return fee;
    }

    function _buy(address _token, address _receiver, address _appFeeReceiver) private returns (uint256) {
        bool isBull = _token == bullToken;
        require(isBull || _token == bearToken, "X2ETHMarket: unsupported token");
        uint256 amount = msg.value;
        require(amount > 0, "X2ETHMarket: insufficient collateral sent");

        rebase();

        uint256 fee = _collectFees(amount);
        uint256 appFee = _appFeeReceiver == address(0) ? 0 : _collectAppFees(amount, _appFeeReceiver);
        uint256 depositAmount = amount.sub(fee).sub(appFee);

        IX2Token(_token).mint(_receiver, depositAmount, isBull ? cachedBullDivisor : cachedBearDivisor);

        return depositAmount;
    }

    function _sell(address _token, uint256 _sellPoints, address _receiver, bool _distribute, address _appFeeReceiver) private returns (uint256) {
        require(_sellPoints > 0, "X2ETHMarket: insufficient amount");
        require(_token == bullToken || _token == bearToken, "X2ETHMarket: unsupported token");
        rebase();

        uint256 amount = IX2Token(_token).burn(msg.sender, _sellPoints, _distribute);

        uint256 fee = _collectFees(amount);
        uint256 appFee = _appFeeReceiver == address(0) ? 0 : _collectAppFees(amount, _appFeeReceiver);

        uint256 withdrawAmount = amount.sub(fee).sub(appFee);
        (bool success,) = _receiver.call{value: withdrawAmount}("");
        require(success, "X2ETHMarket: transfer failed");

        return withdrawAmount;
    }

    function _flip(address _token, uint256 _flipPoints, address _receiver, address _appFeeReceiver) private returns (uint256) {
        require(_flipPoints > 0, "X2ETHMarket: insufficient amount");

        bool sellBull = _token == bullToken;
        require(sellBull || _token == bearToken, "X2ETHMarket: unsupported token");
        rebase();

        uint256 amount = IX2Token(_token).burn(msg.sender, _flipPoints, true);

        uint256 fee = _collectFees(amount);
        uint256 appFee = _appFeeReceiver == address(0) ? 0 : _collectAppFees(amount, _appFeeReceiver);
        uint256 flipAmount = amount.sub(fee).sub(appFee);

        // if bull tokens were burnt then mint bear tokens
        // if bear tokens were burnt then mint bull tokens
        IX2Token(sellBull ? bearToken : bullToken).mint(
            _receiver,
            flipAmount,
            sellBull ? cachedBearDivisor : cachedBullDivisor
        );

        return flipAmount;
    }
}
