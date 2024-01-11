// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "./AaveInterfaces.sol";
import "./IERC3156FlashLender.sol";
import "./IERC20.sol";

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}

library FlashMintLib {
    event Leverage(
        uint256 amountRequested,
        uint256 amountUsed,
        uint256 requiredDAI,
        uint256 amountToCloseLTVGap,
        bool deficit,
        address flashLoan
    );

    address public constant LENDER = 0x1EB4CF3A948E7D72A198fe073cCb8C7a948cD853;
    uint256 private constant _DAI_DECIMALS = 1e18;
    uint256 private constant _COLLAT_RATIO_PRECISION = 1 ether;
    address private constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant _DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    IAToken public constant ADAI = IAToken(0x028171bCA77440897B824Ca71D1c56caC55b68A3);
    IProtocolDataProvider private constant _protocolDataProvider =
        IProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
    ILendingPool private constant _lendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    uint16 private constant _referral = 0; // TODO: get our own referral code

    uint256 private constant _RAY = 10**27;

    function doFlashMint(
        bool deficit,
        uint256 amountDesired,
        address token,
        uint256 collatRatioDAI,
        uint256 depositToCloseLTVGap
    ) public returns (uint256 amount) {
        if (amountDesired == 0) {
            return 0;
        }
        amount = amountDesired;
        address dai = _DAI;

        // calculate amount of dai we need
        uint256 requiredDAI;
        {
            requiredDAI = (toDAI(amount, token) * _COLLAT_RATIO_PRECISION) / collatRatioDAI;

            uint256 requiredDAIToCloseLTVGap = 0;
            if (depositToCloseLTVGap > 0) {
                requiredDAIToCloseLTVGap = toDAI(depositToCloseLTVGap, token);
                requiredDAI = requiredDAI + requiredDAIToCloseLTVGap;
            }

            uint256 _maxLiquidity = maxLiquidity();

            /*
            When depositing/withdrawing in the `lendingPool` the amounts are scaled by a `liquidityIndex` and rounded with the functions rayDiv and rayMul (in the aDAI contract)
            Weirdly, 2 different indexes are used: `liquidityIndex` is used when depositing and `getReserveNormalizedIncome` when withdrawing
            Therefore, we need to round `requiredDAI`, or we may get some rounding errors and revert
            because the amount we try to withdraw (to pay back the flashloan) is not equal to the amount deposited
            */
            uint256 liquidityIndex = _lendingPool.getReserveData(dai).liquidityIndex;
            uint256 getReserveNormalizedIncome = _lendingPool.getReserveNormalizedIncome(dai);
            uint256 rayDiv = ((requiredDAI * _RAY + liquidityIndex / 2) / liquidityIndex);
            requiredDAI = (rayDiv * getReserveNormalizedIncome + (_RAY / 2)) / _RAY;

            if (requiredDAI > _maxLiquidity) {
                requiredDAI = (_maxLiquidity * _RAY - (_RAY / 2)) / getReserveNormalizedIncome;
                requiredDAI = (requiredDAI * liquidityIndex - liquidityIndex / 2) / _RAY;

                // NOTE: if we cap amountDAI, we reduce amountToken we are taking too
                amount =
                    (fromDAI(requiredDAI - requiredDAIToCloseLTVGap, token) * collatRatioDAI) /
                    _COLLAT_RATIO_PRECISION;
            }
        }

        bytes memory data = abi.encode(deficit, amount);
        uint256 _fee = IERC3156FlashLender(LENDER).flashFee(dai, requiredDAI);
        // Check that fees have not been increased without us knowing
        require(_fee == 0);
        uint256 _allowance = IERC20(dai).allowance(address(this), address(LENDER));
        if (_allowance < requiredDAI) {
            IERC20(dai).approve(address(LENDER), 0);
            IERC20(dai).approve(address(LENDER), type(uint256).max);
        }

        IERC3156FlashLender(LENDER).flashLoan(IERC3156FlashBorrower(address(this)), dai, requiredDAI, data);

        emit Leverage(amountDesired, amount, requiredDAI, depositToCloseLTVGap, deficit, LENDER);

        return amount; // we need to return the amount of Token we have changed our position in
    }

    function loanLogic(
        bool deficit,
        uint256 amount,
        uint256 amountFlashmint,
        address want
    ) public returns (bytes32) {
        address dai = _DAI;
        bool isDai = (want == dai);

        ILendingPool lp = _lendingPool;

        if (isDai) {
            if (deficit) {
                lp.deposit(dai, amountFlashmint - amount, address(this), _referral);
                lp.repay(dai, IERC20(dai).balanceOf(address(this)), 2, address(this));
                lp.withdraw(dai, amountFlashmint, address(this));
            } else {
                lp.deposit(dai, IERC20(dai).balanceOf(address(this)), address(this), _referral);
                lp.borrow(dai, amount, 2, _referral, address(this));
                lp.withdraw(dai, amountFlashmint - amount, address(this));
            }
        } else {
            // 1. Deposit DAI in Aave as collateral
            lp.deposit(dai, amountFlashmint, address(this), _referral);

            if (deficit) {
                // 2a. if in deficit withdraw amount and repay it
                lp.withdraw(want, amount, address(this));
                lp.repay(want, IERC20(want).balanceOf(address(this)), 2, address(this));
            } else {
                // 2b. if levering up borrow and deposit
                lp.borrow(want, amount, 2, _referral, address(this));
                lp.deposit(want, IERC20(want).balanceOf(address(this)), address(this), _referral);
            }
            // 3. Withdraw DAI
            lp.withdraw(dai, amountFlashmint, address(this));
        }

        return CALLBACK_SUCCESS;
    }

    function priceOracle() internal view returns (IPriceOracle) {
        return IPriceOracle(_protocolDataProvider.ADDRESSES_PROVIDER().getPriceOracle());
    }

    function toDAI(uint256 _amount, address asset) internal view returns (uint256) {
        address dai = _DAI;
        if (_amount == 0 || _amount == type(uint256).max || asset == dai) {
            return _amount;
        }

        if (asset == _WETH) {
            return
                (_amount * (uint256(10)**uint256(IOptionalERC20(dai).decimals()))) / priceOracle().getAssetPrice(dai);
        }

        address[] memory tokens = new address[](2);
        tokens[0] = asset;
        tokens[1] = dai;
        uint256[] memory prices = priceOracle().getAssetsPrices(tokens);

        uint256 ethPrice = (_amount * prices[0]) / (uint256(10)**uint256(IOptionalERC20(asset).decimals()));
        return (ethPrice * _DAI_DECIMALS) / prices[1];
    }

    function fromDAI(uint256 _amount, address asset) internal view returns (uint256) {
        address dai = _DAI;
        if (_amount == 0 || _amount == type(uint256).max || asset == dai) {
            return _amount;
        }

        if (asset == _WETH) {
            return
                (_amount * priceOracle().getAssetPrice(dai)) / (uint256(10)**uint256(IOptionalERC20(dai).decimals()));
        }

        address[] memory tokens = new address[](2);
        tokens[0] = asset;
        tokens[1] = dai;
        uint256[] memory prices = priceOracle().getAssetsPrices(tokens);

        uint256 ethPrice = (_amount * prices[1]) / _DAI_DECIMALS;

        return (ethPrice * (uint256(10)**uint256(IOptionalERC20(asset).decimals()))) / prices[0];
    }

    function maxLiquidity() public view returns (uint256) {
        return IERC3156FlashLender(LENDER).maxFlashLoan(_DAI);
    }
}
