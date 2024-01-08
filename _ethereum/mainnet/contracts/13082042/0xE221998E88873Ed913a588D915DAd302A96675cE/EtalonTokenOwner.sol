// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <=0.8.7;

//import "./console.sol";
import "./EtalonToken.sol";
import "./Owned.sol";
import "./TaxContract.sol";
import "./PRBMathUD60x18.sol";
import "./IUniswapV2Router02.sol"; // подключаем библиотеку для работы с пулом ликвидности
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

// the admin settings
contract EtalonTokenOwner is EtalonToken, Owned {
    //using Pricing for Pricing.PricingData;
    using GlobalLimits for GlobalLimits.GlobalLimitsData;
    using SellLimit for SellLimit.SellLimitData;
    using PRBMathUD60x18 for uint256;

    // the liquidity pool library
    // adds liquidity to the liquidity pool, the liquidity token is burned
    // ETH and token are taken from the contract address
    function OwnerAddLiquidityToPair() public payable onlyOwner {
        // creating a pair on the uniswap
        _UniswapV2Pair = IUniswapV2Pair(
            IUniswapV2Factory(_UniswapRouter.factory()).createPair(
                address(this),
                _UniswapRouter.WETH()
            )
        );
        // confirm that we will transfer the specified amount of token to the router
        _approve(address(this), address(_UniswapRouter), type(uint256).max);
        // shoving liquidity into the pair (the entire ETH balance that is on the contract)
        _UniswapRouter.addLiquidityETH{value: address(this).balance}(
            address(this), // the current token is adding to the liquidity pool
            balanceOf(address(this)), // adding the tokens
            0,
            0,
            //address(msg.sender),
            address(0), // who to send the liquidity tokens to
            block.timestamp
        );

        // get liquidity pool reserves
        (uint256 RouterToken, uint256 RouterEth, ) = _UniswapV2Pair
            .getReserves();

        // limit initialization
        _GlobalLimits.Initialize(
            _GlobalLimits._MaxFallPercent,
            _GlobalLimits._PriceControlTimeIntervalMinutes,
            PRBMathUD60x18.div(RouterEth, RouterToken) // current price
        );
        _SellLimit.Initialize(_SellLimit.DefaultMaxFallPercent);
    }

    // mints the specified amount of token to the specified address
    function OwnerMint(address account, uint256 amount) public onlyOwner {
        // memorizing an account
        if (account != address(_UniswapRouter)) TryAddToAccountList(account);
        // mint
        _mint(account, amount);
    }

    // the admin burns the entire token on the specified account
    function OwnerBurnAll(address account) public onlyOwner {
        _burn(account, balanceOf(account));
    }

    // initializes the tax library
    // only admin, for testing
    function OwnerInitializeTax(
        uint256 taxIntervalDays,
        uint256 constantTaxPercent,
        uint256 minBalancePercentTransactionForReward,
        uint256 rewardStopAccountPercent,
        uint256 maxTaxPercent
    ) public onlyOwner {
        InitializeTax(
            taxIntervalDays,
            constantTaxPercent,
            minBalancePercentTransactionForReward,
            rewardStopAccountPercent,
            maxTaxPercent
        );
    }
}
