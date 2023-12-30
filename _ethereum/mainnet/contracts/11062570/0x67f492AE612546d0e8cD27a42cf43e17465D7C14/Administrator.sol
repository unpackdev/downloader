pragma solidity 0.6.12;

interface StakingContract {
    function transferOwnership(address newOwner) external;
    function burn(address account, uint256 amount) external;
    function updateHoldersDay(bool _enableHoldersDay) external;
    
    // Self-explanatory functions to update several configuration variables
    
    function updateTokenAddress(address newToken) external;
    
    function updateCalculator(address calc) external;
    
    function updateUseExternalCalcIterative(bool _useExternalCalcIterative) external;
    
    
    function updateInflationAdjustmentFactor(uint256 _inflationAdjustmentFactor) external;
    
    function updateStreak(bool negative, uint _streak) external;
    
    function updateMinStakeDurationDays(uint8 _minStakeDurationDays) external;
    
    function updateMinStakes(uint _minStake) external;
    function updateMinPercentIncrease(uint8 _minIncrease) external;
    function updateEnableBurns(bool _enabledBurns) external;
    
    function updateWhitelist(address addr, string calldata reason, bool remove) external;
    
    function updateUniWhitelist(address addr, string calldata reason, bool remove) external;
    
    function updateBlacklist(address addr, uint256 fee, bool remove) external;
    
    function updateUniswapPair(address addr) external;
    
    function updateEnableUniswapSellBurns(bool _enableDirectSellBurns) external;
    
    function updateUniswapSellBurnPercent(uint8 _sellerBurnPercent) external;
    
    function updateFreeze(bool _enableFreeze) external;
    
    function updateNextStakingContract(address nextContract) external;
    
    function updateLiquidityStakingContract(address _liquidityStakingContract) external;
    
    function updateOracle(address _oracle) external;
    
    function updatePreviousStakingContract(address previousContract) external;

    function updateTransferBurnFee(uint _transferBurnFee) external;

    function updateMaxStreak(uint _maxStreak) external;

    function updateMaxStakingDays(uint _maxStakingDays) external;
    function updateHoldersDayRewardDenominator(uint _holdersDayRewardDenominator) external;

    function updateIncreaseTransferFees(bool _increaseTransferFees) external;
    function updateCheckPreviousContractWhitelist(bool _checkPreviousStakingContractWhitelist) external;
    
    function removeLatestUpdate() external;
    function resetStakeTimeDebug(address account, uint startTimestamp, uint lastTimestamp, bool migrated) external;
    
}


interface Minter {
    function liquidityRewards(address recipient, uint amount) external;
}

interface UniswapV2Router{
    function addLiquidityETH(
      address token,
      uint amountTokenDesired,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
      
     function WETH() external pure returns (address);
     
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external payable;
}

interface ERC20 {
    function transfer(address recipient, uint256 amount) external virtual returns (bool);
}


contract Administrator {
    
    address public owner;
    StakingContract public stakingContract;
    address public TimeContract;
    Minter public minter;
    address public storedTokens;
    UniswapV2Router public router;
    
    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }
    
    modifier onlyTIME() {
        assert(msg.sender == TimeContract);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        stakingContract = StakingContract(0x738d3CEC4E685A2546Ab6C3B055fd6B8C1198093); 
        minter = Minter(0x28e484dBD6BB501D37EFC8cD4b8dc33121cC78be);
        storedTokens = 0xB3470826919CC8eA0aB5e333358E36f701B1c6f5;
        router = UniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        TimeContract = 0x869aA079b622DEf8D522968E7A73a973B8B00CD6;
    }
    
    function transfer(address to, uint amount) external onlyOwner {
        stakingContract.burn(storedTokens, amount);
        minter.liquidityRewards(to, amount);
    }
    
    function transferOwnership() external onlyOwner {
        stakingContract.transferOwnership(owner);
    }
    
    function updateStoredTokens(address _storedTokens) external onlyOwner {
        storedTokens = _storedTokens;
    }
    
    function updateStakingContract(address _stakingContract) external onlyOwner {
        stakingContract = StakingContract(_stakingContract);
    }
    
    function updateMinter(address _minter) external onlyOwner {
        minter = Minter(_minter);
    }
    
    function swapExactETHForTokensAddLiquidity(address[] calldata path, uint liquidityETH, uint swapETH)
      external
      payable
      onlyTIME
      returns (uint liquidity) {
        uint[] memory amounts = router.swapExactETHForTokens{value: swapETH}(0, path, address(this), block.timestamp + 86400);
        (uint amountToken, uint amountETH, uint liquidity) = router.addLiquidityETH{value: liquidityETH}(TimeContract, amounts[amounts.length-1], 0, 0, TimeContract, block.timestamp + 86400);
        return liquidity;
      }
     
    function updateTimeContract(address _time) external onlyOwner {
      TimeContract = _time;   
    }
    
    function updateHoldersDay(bool _enableHoldersDay) external onlyOwner {
        stakingContract.updateHoldersDay(_enableHoldersDay);
    }
    
    // Self-explanatory functions to update several configuration variables
    
    function updateTokenAddress(address newToken) external onlyOwner {
        stakingContract.updateTokenAddress(newToken);
    }
    
    function updateCalculator(address calc) external onlyOwner {
        stakingContract.updateCalculator(calc);
    }
    
    function updateUseExternalCalcIterative(bool _useExternalCalcIterative) external onlyOwner {
        stakingContract.updateUseExternalCalcIterative(_useExternalCalcIterative);
    }
    
    
    function updateInflationAdjustmentFactor(uint256 _inflationAdjustmentFactor) external onlyOwner {
        stakingContract.updateInflationAdjustmentFactor(_inflationAdjustmentFactor);
    }
    
    function updateStreak(bool negative, uint _streak) external onlyOwner {
        stakingContract.updateStreak(negative, _streak);
    }
    
    function updateMinStakeDurationDays(uint8 _minStakeDurationDays) external onlyOwner {
        stakingContract.updateMinStakeDurationDays(_minStakeDurationDays);
    }
    
    function updateMinStakes(uint _minStake) external onlyOwner {
        stakingContract.updateMinStakes(_minStake);
    }
    function updateMinPercentIncrease(uint8 _minIncrease) external onlyOwner {
        stakingContract.updateMinPercentIncrease(_minIncrease);
    }
    
    function updateEnableBurns(bool _enabledBurns) external onlyOwner {
        stakingContract.updateEnableBurns(_enabledBurns);
    }
    
    function updateWhitelist(address addr, string calldata reason, bool remove) external onlyOwner {
        stakingContract.updateWhitelist(addr, reason, remove);
    }
    
    function updateUniWhitelist(address addr, string calldata reason, bool remove) external onlyOwner {
        stakingContract.updateUniWhitelist(addr, reason, remove);
    }
    
    function updateBlacklist(address addr, uint256 fee, bool remove) external onlyOwner {
       stakingContract.updateBlacklist(addr, fee, remove);
    }
    
    function updateUniswapPair(address addr) external onlyOwner {
       stakingContract.updateUniswapPair(addr);
    }
    
    function updateEnableUniswapSellBurns(bool _enableDirectSellBurns) external onlyOwner {
        stakingContract.updateEnableUniswapSellBurns(_enableDirectSellBurns);
    }
    
    function updateUniswapSellBurnPercent(uint8 _sellerBurnPercent) external onlyOwner {
        stakingContract.updateUniswapSellBurnPercent(_sellerBurnPercent);
    }
    
    function updateFreeze(bool _enableFreeze) external onlyOwner {
        stakingContract.updateFreeze(_enableFreeze);
    }
    
    function updateNextStakingContract(address nextContract) external onlyOwner {
        stakingContract.updateNextStakingContract(nextContract);
    }
    
    function updateLiquidityStakingContract(address _liquidityStakingContract) external onlyOwner {
        stakingContract.updateLiquidityStakingContract(_liquidityStakingContract);
    }
    
    function updateOracle(address _oracle) external onlyOwner {
        stakingContract.updateOracle(_oracle);
    }
    
    function updatePreviousStakingContract(address previousContract) external onlyOwner {
        stakingContract.updatePreviousStakingContract(previousContract);
    }

    function updateTransferBurnFee(uint _transferBurnFee) external onlyOwner {
        stakingContract.updateTransferBurnFee(_transferBurnFee);
    }

    function updateMaxStreak(uint _maxStreak) external onlyOwner {
        stakingContract.updateMaxStreak(_maxStreak);
    }
    

    function updateMaxStakingDays(uint _maxStakingDays) external onlyOwner {
        stakingContract.updateMaxStakingDays(_maxStakingDays);
    }

    function updateHoldersDayRewardDenominator(uint _holdersDayRewardDenominator) external onlyOwner {
        stakingContract.updateHoldersDayRewardDenominator( _holdersDayRewardDenominator);
    }

    function updateIncreaseTransferFees(bool _increaseTransferFees) external onlyOwner {
        stakingContract.updateIncreaseTransferFees(_increaseTransferFees);
    }

    function updateCheckPreviousContractWhitelist(bool _checkPreviousStakingContractWhitelist) external onlyOwner {
        stakingContract.updateCheckPreviousContractWhitelist(_checkPreviousStakingContractWhitelist);
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
       stakingContract.transferOwnership(newOwner);
    }
    
    function removeLatestUpdate() external onlyOwner {
        stakingContract.removeLatestUpdate();
    }
    
    function burn(address account, uint256 amount) external onlyOwner {     // We allow ourselves to burn tokens in case they were minted due to a bug
        stakingContract.burn(account, amount);
    }
    
    function resetStakeTimeDebug(address account, uint lastTimestamp, uint startTimestamp, bool migrated) external {
        require(msg.sender == owner || msg.sender == TimeContract);
        stakingContract.resetStakeTimeDebug(account, lastTimestamp, startTimestamp, migrated);
    }
    
    function transferTokens(address token, uint amount) external onlyOwner { // in case any tokens get caught here
        ERC20(token).transfer(owner, amount);
    }
    
    receive() external payable {
    }
    
    fallback() external payable {
    }
    
}