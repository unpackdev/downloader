import "./IERC20.sol";

interface IBankEth is IERC20 {

    function dividendTracker() external returns(address);
  	
    function uniswapV2Pair() external returns(address);

  	function setTradingStartTime(uint256 newStartTime) external;
  	
    function updateDividendTracker(address newAddress) external;

    function updateUniswapV2Router(address newAddress) external;

    function excludeFromFees(address account, bool excluded) external;

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) external;

    function setAutomatedMarketMakerPair(address pair, bool value) external;
    
    function excludeFromDailyLimit(address account, bool excluded) external;

    function allowPreTrading(address account, bool allowed) external;

    function setMaxPurchaseEnabled(bool enabled) external;

    function setMaxPurchaseAmount(uint256 newAmount) external;

    function updateDevAddress(address payable newAddress) external;

    function getTotalDividendsDistributed() external view returns (uint256);

    function isExcludedFromFees(address account) external view returns(bool);

    function withdrawableDividendOf(address account) external view returns(uint256);

	function dividendTokenBalanceOf(address account) external view returns (uint256);

    function reinvestInactive(address payable account) external;

    function claim(bool reinvest, uint256 minTokens) external;
        
    function getNumberOfDividendTokenHolders() external view returns(uint256);
    
    function getAccount(address _account) external view returns (
        uint256 withdrawableDividends,
        uint256 withdrawnDividends,
        uint256 balance
    );
    
    function assignAntiBot(address _address) external;
    
    function toggleAntiBot() external;
}