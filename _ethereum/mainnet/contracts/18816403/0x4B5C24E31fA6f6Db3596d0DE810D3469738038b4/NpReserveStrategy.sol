// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20.sol";

import "./IUniswapV2Router02.sol";
import "./ITreasury.sol";

import "./Whitelist.sol";
import "./SafeMath.sol";
import "./NpPausable.sol";

contract NpReserveStrategy is UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, NpPausable, Whitelist {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    uint256 public constant apr_precision = 100;

    uint256 public liquidityThreshold;
    uint256 public daily_apr;
    uint256 public lastSweep;

    ITreasury public collateralTreasury;
    ITreasury public coreTreasury;
    IERC20 public collateralToken; // USD
    IERC20 public coreToken; // NP
    IUniswapV2Router02 public collateralRouter;

    event UpdateDailyAPR(uint oldApr, uint newApr);
    event Sweep(uint amount);

    constructor() {
        _disableInitializers();
    }

    function initialize(
        IERC20 _coreToken,
        IERC20 _collateralToken,
        IUniswapV2Router02 _router,
        ITreasury _coreTreausry,
        ITreasury _collateralTreasury
    ) external initializer {
        __Ownable_init(_msgSender());
        __Pausable_init();
        __ReentrancyGuard_init();

        coreToken = _coreToken;
        collateralToken = _collateralToken;
        collateralRouter = _router;
        collateralTreasury = _collateralTreasury;
        coreTreasury = _coreTreausry;
        liquidityThreshold = 100e6;
        daily_apr = 20;

        lastSweep = block.timestamp;
    }

    function buyCoreWithCollateral(uint collateralAmount) internal returns (uint coreAmount) {
        address[] memory path = new address[](2);

        //Sell collateral
        path[0] = address(collateralToken);
        path[1] = address(coreToken);

        require(collateralToken.approve(address(collateralRouter), collateralAmount));

        uint initialBalance = coreToken.balanceOf(address(this));

        collateralRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            collateralAmount,
            0, //accept any amount of backed tokens
            path,
            address(this), //send it here first so we can find out how much TRUNK we received
            block.timestamp
        );

        //This contract does not hold any token balances
        coreAmount = coreToken.balanceOf(address(this)).sub(initialBalance);
    }

    /// @dev Update the daily APR of the strategy
    function updateDailyAPR(uint apr) external onlyOwner {
        require(apr >= 0 && apr <= 100, "Daily APR out of range");
        emit UpdateDailyAPR(daily_apr, apr);
        daily_apr = apr;
    }

    //Estimate how much the Collateral Treasury should payout to Core Treasury
    function available() public view returns (uint collateralAmount) {
        //Calculate daily drip
        uint256 collateralTreasuryBalance = collateralToken.balanceOf(address(collateralTreasury));
        //What is the share per second?
        uint256 _share = collateralTreasuryBalance.mul(daily_apr).div(apr_precision).div(24 hours); //divide the profit by seconds in the day
        uint256 _seconds = block.timestamp.sub(lastSweep).min(24 hours); //we will only process the maximum of a days worth of divs
        collateralAmount = _share * _seconds; //share times the amount of time elapsed
    }

    function sweep() external whenNotPaused onlyWhitelisted nonReentrant returns (uint coreAmount, uint collateralAmount) {
        collateralAmount = available();
        if (collateralAmount > liquidityThreshold) {
            collateralTreasury.withdraw(collateralAmount);
            coreAmount = buyCoreWithCollateral(collateralAmount);
            coreToken.safeTransfer(address(coreTreasury), coreAmount);
            lastSweep = block.timestamp;

            emit Sweep(collateralAmount);
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
