pragma solidity 0.7.6;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

import "./Price.sol";
import "./BasicMaths.sol";
import "./IPool.sol";
import "./ISystemSettings.sol";
import "./IPoolCallback.sol";
import "./IWETH.sol";
import "./IDeployer02.sol";
import "./IDebt.sol";
import "./Rates.sol";

contract Pool is ERC20, Rates, IPool {
    using SafeMath for uint256;
    using BasicMaths for uint256;
    using BasicMaths for bool;
    using SafeERC20 for IERC20;

    address public _poolToken;
    address public _settings;
    address public override debtToken;

    uint256 public _lastRebaseBlock = 0;
    uint32 public _positionIndex = 0;
    uint8 public _poolDecimalDiff;
    mapping(uint32 => Position) public override _positions;

    uint256 public _lsAvgPrice = 1e18;
    uint256 public _liquidityPool = 0;
    uint256 public _totalSizeLong = 0;
    uint256 public _totalSizeShort = 0;
    uint256 public _rebaseAccumulatedLong = 0;
    uint256 public _rebaseAccumulatedShort = 0;

    uint8 private constant StandardDecimal = 18;
    bool private locked;

    constructor(
        address poolToken,
        address uniPool,
        address setting,
        string memory symbol,
        bool reverse,
        uint8 oracle
    ) ERC20(symbol, symbol) Rates(uniPool, reverse, oracle) {
        uint8 decimals = ERC20(poolToken).decimals();

        _setupDecimals(decimals);
        _poolToken = poolToken;
        _settings = setting;
        _poolDecimalDiff = StandardDecimal > ERC20(poolToken).decimals()
            ? StandardDecimal - ERC20(poolToken).decimals()
            : 0;

        debtToken = IDeployer02(ISystemSettings(setting).deployer02()).deploy(address(this), poolToken, setting, symbol);
    }

    function lsTokenPrice() external view override returns (uint256) {
        return
            Price.lsTokenPrice(
                IERC20(address(this)).totalSupply(),
                _liquidityPool
            );
    }

    function poolCallback(address user, uint256 amount) internal lock {
        uint256 balanceBefore = IERC20(_poolToken).balanceOf(address(this));
        IPoolCallback(msg.sender).poolV2Callback(
            amount,
            _poolToken,
            address(_oraclePool),
            user,
            _reverse
        );
        require(
            IERC20(_poolToken).balanceOf(address(this)) >=
                balanceBefore.add(amount),
            "PT Err"
        );
    }

    function _mintLsByPoolToken(uint256 amount) internal {
        uint256 lsTokenAmount = Price.lsTokenByPoolToken(
            IERC20(address(this)).totalSupply(),
            _liquidityPool,
            amount
        );

        _mint(ISystemSettings(_settings).official(), lsTokenAmount);
        emit MintLiquidity(lsTokenAmount);
    }

    function addLiquidity(address user, uint256 amount) external override {
        ISystemSettings(_settings).requireSystemActive();
        require(amount > 0, "Amt Err");
        rebase();

        uint256 lsTotalSupply = IERC20(address(this)).totalSupply();
        uint256 lsTokenAmount = Price.lsTokenByPoolToken(
            lsTotalSupply,
            _liquidityPool,
            amount
        );
        poolCallback(user, amount);

        _mint(user, lsTokenAmount);
        _liquidityPool = _liquidityPool.add(amount);
        _lsAvgPrice = Price.calLsAvgPrice(_lsAvgPrice, lsTotalSupply, amount, lsTokenAmount);

        IDebt debt = IDebt(debtToken);
        uint bonds;
        if (lsTotalSupply > 0) {
            bonds = debt.bondsLeft().mul(lsTokenAmount) / lsTotalSupply;
            if (bonds > 0) {
                debt.issueBonds(user, bonds);
            }
        }

        emit AddLiquidity(user, amount, lsTokenAmount, bonds);
    }

    function removeLiquidity(address user, uint256 amount, uint256 bondsAmount, address receipt) external override lock {
        ISystemSettings settings = ISystemSettings(_settings);
        rebase();

        IERC20 ls = IERC20(address(this));
        uint256 bondsLeft = IDebt(debtToken).bondsLeft();
        uint256 poolTokenAmount;

        if (bondsAmount == 0) {
            // remove ls without bonds
            poolTokenAmount = Price.poolTokenByLsTokenWithDebt(
                ls.totalSupply(),
                bondsLeft,
                _liquidityPool,
                amount
            );
        } else {
            // remove ls with bonds
            uint256 bondsRequired = bondsLeft.mul(amount).div(ls.totalSupply());
            if (bondsAmount >= bondsRequired) {
                bondsAmount = bondsRequired;
            } else {
                amount = bondsAmount.mul(ls.totalSupply()).div(bondsLeft);
            }

            IPoolCallback(msg.sender).poolV2BondsCallback(
                bondsAmount,
                _poolToken,
                address(_oraclePool),
                user,
                _reverse
            );

            IDebt(debtToken).burnBonds(bondsAmount);
            poolTokenAmount = Price.poolTokenByLsTokenWithDebt(
                ls.totalSupply(),
                0,
                _liquidityPool,
                amount
            );
        }

        uint256 nakedPosition = Price
            .mulPrice(_totalSizeLong.diff(_totalSizeShort), _getPrice())
            .div(10**_poolDecimalDiff);
        require(settings.mulLiquidityCoefficient(nakedPosition) <= _liquidityPool.sub2Zero(poolTokenAmount),
            "Ls Err");

        uint256 balanceBefore = ls.balanceOf(address(this));
        IPoolCallback(msg.sender).poolV2RemoveCallback(
            amount,
            _poolToken,
            address(_oraclePool),
            user,
            _reverse
        );
        require(
            ls.balanceOf(address(this)) >=
                balanceBefore.add(amount),
            "LS Err"
        );

        _burn(address(this), amount);
        _liquidityPool = _liquidityPool.sub(poolTokenAmount);
        IERC20(_poolToken).safeTransfer(receipt, poolTokenAmount);

        emit RemoveLiquidity(user, poolTokenAmount, amount, bondsAmount);
    }

    function openPosition(
        address user,
        uint8 direction,
        uint16 leverage,
        uint256 position
    ) external override returns (uint32) {
        ISystemSettings setting = ISystemSettings(_settings);
        setting.checkOpenPosition(leverage);
        require(
            direction == 1 || direction == 2,
            "D Err"
        );

        require(position > 0, "Amt Err");
        require(_liquidityPool > 0, "L Err");

        rebase();

        uint256 price = _getPrice();
        uint256 value = position.mul(leverage);

        if (setting.deviation()) {
            uint256 nakedPosition;
            bool positive;

            if (direction == 1) {
                (positive, nakedPosition) = Price
                    .mulPrice(_totalSizeLong, price)
                    .div(10**_poolDecimalDiff)
                    .add(value)
                    .diff2(
                        Price.mulPrice(_totalSizeShort, price).div(
                            10**_poolDecimalDiff
                        )
                    );
            } else {
                (positive, nakedPosition) = Price
                    .mulPrice(_totalSizeLong, price)
                    .div(10**_poolDecimalDiff)
                    .diff2(
                        Price
                            .mulPrice(_totalSizeShort, price)
                            .div(10**_poolDecimalDiff)
                            .add(value)
                    );
            }

            if ((direction == 1) == positive) {
                uint256 deviation = setting.calDeviation(
                    nakedPosition,
                    _liquidityPool
                );
                price = Price.calDeviationPrice(deviation, price, direction);
            }
        }

        poolCallback(user, position);
        if (_poolDecimalDiff > 0) {
            value = value.mul(10**_poolDecimalDiff);
        }
        uint256 size = Price.divPrice(value, price);

        uint256 openRebase;
        if (direction == 1) {
            _totalSizeLong = _totalSizeLong.add(size);
            openRebase = _rebaseAccumulatedLong;
        } else {
            _totalSizeShort = _totalSizeShort.add(size);
            openRebase = _rebaseAccumulatedShort;
        }

        _positionIndex++;
        _positions[_positionIndex] = Position(
            price,
            block.number,
            position,
            size,
            openRebase,
            msg.sender,
            direction
        );

        emit OpenPosition(
            user,
            price,
            openRebase,
            direction,
            leverage,
            position,
            size,
            _positionIndex
        );
        return _positionIndex;
    }

    function addMargin(
        address user,
        uint32 positionId,
        uint256 margin
    ) external override {
        ISystemSettings(_settings).requireSystemActive();
        Position memory p = _positions[positionId];
        require(msg.sender == p.account, "P Err");
        rebase();

        poolCallback(user, margin);
        _positions[positionId].margin = p.margin.add(margin);

        emit AddMargin(user, margin, positionId);
    }

    function closePosition(
        address receipt,
        uint32 positionId
    ) external override {
        ISystemSettings setting = ISystemSettings(_settings);
        setting.requireSystemActive();

        Position memory p = _positions[positionId];
        require(p.account == msg.sender, "P Err");
        rebase();

        uint256 closePrice = _getPrice();
        uint256 pnl;
        bool isProfit;
        if (block.number - p.openBlock > setting.minHoldingPeriod()) {
            pnl = Price.mulPrice(p.size, closePrice.diff(p.openPrice));
            isProfit = (closePrice >= p.openPrice) == (p.direction == 1);
        }

        uint256 fee = setting.mulClosingFee(Price.mulPrice(p.size, closePrice));
        uint256 fundingFee;
        if (p.direction == 1) {
            fundingFee = Price.calFundingFee(
                p.size.mul(_rebaseAccumulatedLong.sub(p.openRebase)),
                closePrice
            );

            _totalSizeLong = _totalSizeLong.sub(p.size);
        } else {
            fundingFee = Price.calFundingFee(
                p.size.mul(_rebaseAccumulatedShort.sub(p.openRebase)),
                closePrice
            );

            _totalSizeShort = _totalSizeShort.sub(p.size);
        }

        if (_poolDecimalDiff != 0) {
            pnl = pnl.div(10**_poolDecimalDiff);
            fee = fee.div(10**_poolDecimalDiff);
            fundingFee = fundingFee.div(10**_poolDecimalDiff);
        }

        require(
            isProfit.addOrSub2Zero(p.margin, pnl) > fee.add(fundingFee),
            "Close Err"
        );

        int256 debtChange;
        uint256 transferOut = isProfit.addOrSub(p.margin, pnl).sub(fee).sub(
            fundingFee
        );

        if (transferOut < p.margin) {
            // repay debt
            uint256 debtRepay = setting.calDebtRepay(p.margin - transferOut,
                IDebt(debtToken).totalDebt(),
                _liquidityPool
            );

            if (debtRepay > 0) {
                IERC20(_poolToken).safeTransfer(debtToken, debtRepay);
            }

            debtChange = int256(-debtRepay);

        } else {

            uint256 debtIssue;
            if (_liquidityPool.add(p.margin) < transferOut) {
                debtIssue = transferOut - p.margin;
            }
            else {
                uint256 lsPrice = Price.lsTokenPrice(
                    IERC20(address(this)).totalSupply(),
                    _liquidityPool.add(p.margin) - transferOut);

                debtIssue = setting.calDebtIssue(transferOut - p.margin,
                    _lsAvgPrice,
                    lsPrice
                );
            }

            transferOut = transferOut.sub(debtIssue);
            if (debtIssue > 0) {
                IDebt(debtToken).issueBonds(receipt, debtIssue);
            }

            debtChange = int256(debtIssue);
        }

        if (transferOut > 0) {
            IERC20(_poolToken).safeTransfer(receipt, transferOut);
        }

        if (p.margin >= transferOut.add(Price.calRepay(debtChange))) {
            _liquidityPool = _liquidityPool.add(p.margin.sub(transferOut.add(Price.calRepay(debtChange))));
        } else {
            _liquidityPool = _liquidityPool.sub(transferOut.add(Price.calRepay(debtChange)).sub(p.margin));
        }

        _mintLsByPoolToken(setting.mulProtocolFee(fundingFee.add(fee)));

        delete _positions[positionId];
        emit ClosePosition(
            receipt,
            closePrice,
            fee,
            fundingFee,
            pnl,
            positionId,
            isProfit,
            debtChange
        );
    }

    function liquidate(
        address user,
        uint32 positionId,
        address receipt
    ) external override {
        Position memory p = _positions[positionId];
        require(p.account != address(0), "P Err");

        ISystemSettings setting = ISystemSettings(_settings);
        setting.requireSystemActive();
        require(IERC20(address(this)).balanceOf(user) >= setting.liqLsRequire(), "too less ls");

        rebase();

        uint256 liqPrice = _getPrice();
        uint256 pnl = Price.mulPrice(p.size, liqPrice.diff(p.openPrice));
        uint256 fee = setting.mulClosingFee(Price.mulPrice(p.size, liqPrice));
        uint256 fundingFee;

        if (p.direction == 1) {
            fundingFee = Price.calFundingFee(
                p.size.mul(_rebaseAccumulatedLong.sub(p.openRebase)),
                liqPrice
            );

            _totalSizeLong = _totalSizeLong.sub(p.size);
        } else {
            fundingFee = Price.calFundingFee(
                p.size.mul(_rebaseAccumulatedShort.sub(p.openRebase)),
                liqPrice
            );

            _totalSizeShort = _totalSizeShort.sub(p.size);
        }

        if (_poolDecimalDiff != 0) {
            pnl = pnl.div(10**_poolDecimalDiff);
            fee = fee.div(10**_poolDecimalDiff);
            fundingFee = fundingFee.div(10**_poolDecimalDiff);
        }

        bool isProfit = (liqPrice >= p.openPrice) == (p.direction == 1);

        require(
            isProfit.addOrSub2Zero(p.margin, pnl) < fee.add(fundingFee).add(setting.mulMarginRatio(p.margin)),
            "Liq Err"
        );

        uint256 liquidateFee = setting.mulLiquidationFee(p.margin, block.number - p.openBlock);
        uint256 liqProtocolFee = setting.mulLiqProtocolFee(liquidateFee);
        liquidateFee = liquidateFee.sub(liqProtocolFee);

        uint256 debtRepay = setting.calDebtRepay(p.margin.sub(liquidateFee),
            IDebt(debtToken).totalDebt(),
            _liquidityPool
        );
        if (debtRepay > 0) {
            IERC20(_poolToken).safeTransfer(debtToken, debtRepay);
        }

        _liquidityPool = _liquidityPool.add(p.margin.sub(liquidateFee).sub(debtRepay));
        IERC20(_poolToken).safeTransfer(receipt, liquidateFee);
        delete _positions[positionId];

        uint256 protocolFee = setting.mulProtocolFee(fundingFee.add(fee));
        _mintLsByPoolToken(protocolFee.add(liqProtocolFee));

        emit Liquidate(
            user,
            positionId,
            liqPrice,
            fee,
            fundingFee,
            liquidateFee,
            pnl,
            isProfit,
            debtRepay
        );
    }

    function rebase() internal {
        ISystemSettings setting = ISystemSettings(_settings);
        uint256 currBlock = block.number;

        if (_lastRebaseBlock == currBlock) {
            return;
        }

        if (_liquidityPool == 0) {
            _lastRebaseBlock = currBlock;
            return;
        }

        uint256 rebasePrice = _getPriceAndUpdate();
        uint256 nakedPosition = Price
            .mulPrice(_totalSizeLong.diff(_totalSizeShort), rebasePrice)
            .div(10**_poolDecimalDiff);

        if (!setting.meetImbalanceThreshold(nakedPosition, _liquidityPool)) {
            _lastRebaseBlock = currBlock;
            return;
        }

        uint256 rebaseSize = _totalSizeLong.diff(_totalSizeShort).sub(
            Price
                .divPrice(
                    setting.mulImbalanceThreshold(_liquidityPool),
                    rebasePrice
                )
                .mul(10**_poolDecimalDiff)
        );

        if (_totalSizeLong > _totalSizeShort) {
            uint256 rebaseDelta = setting.calRebaseDelta(
                rebaseSize.mul(block.number.sub(_lastRebaseBlock)),
                _totalSizeLong
            );

            _rebaseAccumulatedLong = _rebaseAccumulatedLong.add(rebaseDelta);
        } else {
            uint256 rebaseDelta = setting.calRebaseDelta(
                rebaseSize.mul(block.number.sub(_lastRebaseBlock)),
                _totalSizeShort
            );

            _rebaseAccumulatedShort = _rebaseAccumulatedShort.add(rebaseDelta);
        }
        _lastRebaseBlock = currBlock;

        emit Rebase(
            _rebaseAccumulatedLong,
            _rebaseAccumulatedShort
        );
    }

    function exit(
        address receipt,
        uint32 positionId
    ) external override {
        ISystemSettings(_settings).requireSystemSuspend();

        Position memory p = _positions[positionId];
        require(p.account == msg.sender, "P Err");

        if (p.direction == 1) {
            _totalSizeLong = _totalSizeLong.sub(p.size);
        } else {
            _totalSizeShort = _totalSizeShort.sub(p.size);
        }

        IERC20(_poolToken).safeTransfer(receipt, p.margin);

        delete _positions[positionId];
    }

    modifier lock() {
        require(!locked, 'LOCK');
        locked = true;
        _;
        locked = false;
    }
}
