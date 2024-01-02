// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./PriceOracleInterface.sol";
import "./Withdrawable.sol";

using SafeERC20 for IERC20;

abstract contract IERC20Extented is IERC20 {
    function decimals() virtual public view returns (uint8);
}

contract SwapCore is Ownable, Withdrawable {
    address private priceOracle;
    bool private isPaused = true;

    uint256 swapFee = 0;
    uint256 private statisticsTotalSwaps = 0;
    uint256 private statisticsTotalValueSwappedBase = 0;
    uint256 private statisticsTotalValueSwappedPair = 0;
    uint256 private statisticsFeesAccruedBase = 0;
    uint256 private statisticsFeesAccruedPair = 0;
    uint256 private minimumBaseTokenPerSwap = 0;
    uint256 private maximumBaseTokenPerSwap = 0;
    uint256 private minimumPairTokenPerSwap = 0;
    uint256 private maximumPairTokenPerSwap = 0;
    address private baseTokenContract = address(0);
    uint8 private baseTokenDecimals = 0;
    uint8 private pairTokenDecimals = 0;
    address private pairTokenContract = address(0);

    event BaseTokenContractChanged(address previous, address currentAddress);
    event PairTokenContractChanged(address previous, address currentAddress);

    event debugString(string  message );
    event debugNumber(uint256  message );

    event SwapPaused();
    event SwapResumed();
    event FeeConfigurationChanged(uint256 perviousfee, uint256 newfee);
    event BaseTokenMinimumLimitChanged(
        uint256 previousminimum,
        uint256 currentminimum
    );
    event BaseTokenMaximumLimitChanged(
        uint256 previousmaximum,
        uint256 currentmaximum
    );
    event PairTokenMinimumLimitChanged(
        uint256 previousminimum,
        uint256 currentminimum
    );
    event PairTokenMaximumLimitChanged(
        uint256 previousmaximum,
        uint256 currentmaximum
    );

    function pause() public onlyOwner {
        require(isPaused == false);
        isPaused = true;
        emit SwapPaused();
    }

    function resume() public onlyOwner {
        require(isPaused == true);
        isPaused = false;
        emit SwapResumed();
    }

    function isSwapPaused() public view returns (bool) {
        return isPaused;
    }

    function setBaseTokenContract(address contractAddress) public onlyOwner {
        address previous = baseTokenContract;
        baseTokenContract = contractAddress;
        emit BaseTokenContractChanged(previous, baseTokenContract);

        if (contractAddress != address(0)) {
            IERC20Extented targetContract = IERC20Extented(contractAddress);
            baseTokenDecimals = targetContract.decimals();
        }
        emit debugNumber(baseTokenDecimals);
    }

    function setPairTokenContract(address contractAddress) public onlyOwner {
        address previous = pairTokenContract;
        pairTokenContract = contractAddress;
        emit PairTokenContractChanged(previous, pairTokenContract);

        if (contractAddress != address(0)) {
            IERC20Extented targetContract = IERC20Extented(contractAddress);
            pairTokenDecimals = targetContract.decimals();
        }

        emit debugNumber(pairTokenDecimals);
    }

    function SetMinimumBaseTokenPerSwap(uint256 minimum) public onlyOwner {
        uint256 previous = minimumBaseTokenPerSwap;
        minimumBaseTokenPerSwap = minimum;
        emit BaseTokenMinimumLimitChanged(previous, minimum);
    }

    function SetMaximumBaseTokenPerSwap(uint256 maximum) public onlyOwner {
        uint256 previous = maximumBaseTokenPerSwap;
        maximumBaseTokenPerSwap = maximum;
        emit BaseTokenMaximumLimitChanged(previous, maximum);
    }

    function SetMinimumPairTokenPerSwap(uint256 minimum) public onlyOwner {
        uint256 previous = minimumPairTokenPerSwap;
        minimumPairTokenPerSwap = minimum;
        emit PairTokenMinimumLimitChanged(previous, minimum);
    }

    function SetMaximumPairTokenPerSwap(uint256 maximum) public onlyOwner {
        uint256 previous = maximumPairTokenPerSwap;
        maximumPairTokenPerSwap = maximum;
        emit PairTokenMaximumLimitChanged(previous, maximum);
    }

    function setSwapFee(uint256 percentile) public onlyOwner {
        //
        // The maximum fee can be 99.99% so that would be 99.99 * 10^2 - 9999
        // require(
        //     percentile <= 9999,
        //     "Fee can be from 0% to 99.99% or 9999 as uint"
        // );
        uint256 previousFee = swapFee;
        swapFee = percentile;
        emit FeeConfigurationChanged(previousFee, percentile);
    }

    function getSwapFee() public view returns (uint256) {
        return swapFee;
    }

    function setPriceOracle(address priceOracleAddress) public onlyOwner {
        priceOracle = priceOracleAddress;
    }

    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }

    function quoteSwapToBase(
        uint256 baseQuantity
    )
        public
        view
        returns (
            uint256 quantity,
            uint8 quantityDecimals,
            uint quoteUsed,
            uint8 quoteDecimals
        )
    {
        require(isPaused == false, "Swap is paused, cannot quote swaps");
        require(
            priceOracle != address(0),
            "Price Oracle not configured. Cannot swap"
        );
        require(
            baseTokenContract != address(0),
            "Base Token contract not configured. Cannot swap"
        );
        require(
            pairTokenContract != address(0),
            "Pair Token contract not configured. Cannot swap"
        );
        require(
            baseQuantity >= minimumBaseTokenPerSwap,
            "Swap bellow minimum allowed for base"
        );
        require(
            baseQuantity <= maximumBaseTokenPerSwap,
            "Swap above maximum allowed for base"
        );

        PriceOracleInterface oracle = PriceOracleInterface(priceOracle);

        PriceOracleStructures.PriceOracleData memory quote = oracle.getQuote();

        require(
            oracle.IsQuoteTooDeviant(quote) == false,
            "Quote is too old, cannot swap now"
        );
        require(
            oracle.IsQuoteTooOld(quote) == false,
            "Quote is too old, cannot swap now"
        );

        uint powerDifferential = quote.decimals - baseTokenDecimals;

        uint256 quoteNormalized2 = Math.mulDiv((uint256) (quote.answer), 1, 10 ** powerDifferential);

        uint256 pairQuantityWithoutFee =
        
        Math.mulDiv(baseQuantity, 
                    quoteNormalized2, 
                    10 ** baseTokenDecimals);

        uint256 fees = Math.mulDiv(pairQuantityWithoutFee, swapFee, 10**4);

        return (
            pairQuantityWithoutFee + fees,
            baseTokenDecimals,
            uint(quote.answer),
            quote.decimals
        );
    }

    function divide(uint256 a, uint256 b) private pure returns (uint256) {
        require(b != 0, "division by zero will result in infinity.");
        return (a * 1e18) / b;
    }

    function quoteSwapToPair(
        uint256 baseQuantity
    )
        public
        view
        returns (
            uint256 quantity,
            uint8 quantityDecimals,
            uint quoteUsed,
            uint8 quoteDecimals
        )
    {
        require(
            priceOracle != address(0),
            "Price Oracle not configured. Cannot swap"
        );
        require(
            baseQuantity >= minimumPairTokenPerSwap,
            "Swap bellow minimum allowed for pair"
        );
        require(
            baseQuantity <= maximumPairTokenPerSwap,
            "Swap above maximum allowed for pair"
        );

        PriceOracleInterface oracle = PriceOracleInterface(priceOracle);

        PriceOracleStructures.PriceOracleData memory quote = oracle.getQuote();

        require(
            oracle.IsQuoteTooDeviant(quote) == false,
            "Quote is too old, cannot swap now"
        );
        require(
            oracle.IsQuoteTooOld(quote) == false,
            "Quote is too old, cannot swap now"
        );
  
        uint powerDifferential = quote.decimals - pairTokenDecimals;

        uint256 pairQuantityWithoutFee = 
           Math.mulDiv(baseQuantity, 
           ((uint)(quote.answer) / 10 ** powerDifferential),  10 ** pairTokenDecimals);
        
        uint256 fees = Math.mulDiv(pairQuantityWithoutFee, swapFee, 10**4);

        return (
            pairQuantityWithoutFee + fees,
            pairTokenDecimals,
            uint(quote.answer),
            quote.decimals
        );
    }

    function SwapToBase(uint256 baseQuantity) public {
        require(isPaused == false, "Swap is paused, cannot quote swaps");
        require(
            priceOracle != address(0),
            "Price Oracle not configured. Cannot swap"
        );
        require(
            baseTokenContract != address(0),
            "Base Token contract not configured. Cannot swap"
        );
        require(
            pairTokenContract != address(0),
            "Pair Token contract not configured. Cannot swap"
        );
        require(
            baseQuantity >= minimumBaseTokenPerSwap,
            "Swap bellow minimum allowed for base"
        );
        require(
            baseQuantity <= maximumBaseTokenPerSwap,
            "Swap above maximum allowed for base"
        );
        require(
            baseTokenDecimals != 0,
            "Base token decimals is 0 thus invalid"
        );
        require(
            pairTokenDecimals != 0,
            "Base token decimals is 0 thus invalid"
        );
        require(
            pairTokenDecimals == baseTokenDecimals,
            "Base token decimals and pair token decimals do not match"
        );

        PriceOracleInterface oracle = PriceOracleInterface(priceOracle);

        PriceOracleStructures.PriceOracleData memory quote = oracle.getQuote();     

        require(        
            oracle.IsQuoteTooDeviant(quote) == false,        
            "Quote is too old, cannot swap now"        
        );
        
        require(        
            oracle.IsQuoteTooOld(quote) == false,        
            "Quote is too old, cannot swap now"        
        );

        uint powerDifferential = quote.decimals - baseTokenDecimals;

        uint256 quoteNormalized2 = Math.mulDiv((uint256) (quote.answer), 1, 10 ** powerDifferential);

        uint256 pairQuantityWithoutFee =
        
        Math.mulDiv(baseQuantity, 
                    quoteNormalized2, 
                    10 ** baseTokenDecimals);

        uint256 fees = Math.mulDiv(pairQuantityWithoutFee, swapFee, 10**4);

        statisticsFeesAccruedPair += fees;
        statisticsTotalSwaps++;

        IERC20 baseContract = IERC20(baseTokenContract);
        IERC20 pairContract = IERC20(pairTokenContract);

        pairContract.safeTransferFrom(
            msg.sender,
            address(this),
            pairQuantityWithoutFee + fees
        );
        baseContract.safeTransfer(msg.sender, baseQuantity);

    }

    function SwapToPair(uint256 baseQuantity) public {
        require(isPaused == false, "Swap is paused, cannot quote swaps");
        require(
            priceOracle != address(0),
            "Price Oracle not configured. Cannot swap"
        );
        require(
            baseTokenContract != address(0),
            "Base Token contract not configured. Cannot swap"
        );
        require(
            pairTokenContract != address(0),
            "Pair Token contract not configured. Cannot swap"
        );
        require(
            baseQuantity >= minimumBaseTokenPerSwap,
            "Swap bellow minimum allowed for base"
        );
        require(
            baseQuantity <= maximumBaseTokenPerSwap,
            "Swap above maximum allowed for base"
        );

        require(
            baseTokenDecimals != 0,
            "Base token decimals is 0 thus invalid"
        );
        require(
            pairTokenDecimals != 0,
            "Base token decimals is 0 thus invalid"
        );
        require(
            pairTokenDecimals == baseTokenDecimals,
            "Base token decimals and pair token decimals do not match"
        );

        PriceOracleInterface oracle = PriceOracleInterface(priceOracle);

        PriceOracleStructures.PriceOracleData memory quote = oracle.getQuote();     
         require(
             oracle.IsQuoteTooDeviant(quote) == false,
             "Quote is too old, cannot swap now"
         );
         require(
             oracle.IsQuoteTooOld(quote) == false,
             "Quote is too old, cannot swap now"
         );

        
        uint powerDifferential = quote.decimals - pairTokenDecimals;

        uint256 pairQuantityWithoutFee = 
           Math.mulDiv(baseQuantity, 
           ((uint)(quote.answer) / 10 ** powerDifferential),  10 ** pairTokenDecimals);
        
        uint256 fees = Math.mulDiv(pairQuantityWithoutFee, swapFee, 10**4);

        statisticsFeesAccruedPair += fees;
        statisticsTotalSwaps++;

        IERC20 baseContract = IERC20(baseTokenContract);
        IERC20 pairContract = IERC20(pairTokenContract);

        baseContract.safeTransferFrom(msg.sender, address(this), baseQuantity);
        pairContract.safeTransfer(msg.sender, pairQuantityWithoutFee - fees);
    }

    function getFeesAccrued()
        public
        view
        onlyOwner
        returns (uint256 feesAccruedInBase, uint256 feesAccruedInPair)
    {
        return (statisticsFeesAccruedBase, statisticsFeesAccruedPair);
    }

    function getLiquidityStatus()
        public
        view
        returns (
            uint256 baseLiquidity,
            uint8 baseDecimals,
            uint256 pairLiquidity,
            uint8 pairDecimals
        )
    {
        require(
            baseTokenContract != address(0),
            "Base Token contract not configured."
        );
        require(
            pairTokenContract != address(0),
            "Pair Token contract not configured."
        );

        IERC20 baseContract = IERC20(baseTokenContract);
        IERC20 pairContract = IERC20(pairTokenContract);

        return (
            baseContract.balanceOf(address(this)),
            baseTokenDecimals,
            pairContract.balanceOf(address(this)),
            pairTokenDecimals
        );
    }

    receive() external payable {}

    function removeThisOnProd() public onlyOwner
    {

    }
}
