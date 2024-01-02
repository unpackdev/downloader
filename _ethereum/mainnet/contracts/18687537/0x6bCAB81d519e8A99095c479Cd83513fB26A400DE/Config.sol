//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**

   ____     ____        __      _   _________    _____      _____   
  / ___)   / __ \      /  \    / ) (_   _____)  (_   _)    / ___ \  
 / /      / /  \ \    / /\ \  / /    ) (___       | |     / /   \_) 
( (      ( ()  () )   ) ) ) ) ) )   (   ___)      | |    ( (  ____  
( (      ( ()  () )  ( ( ( ( ( (     ) (          | |    ( ( (__  ) 
 \ \___   \ \__/ /   / /  \ \/ /    (   )        _| |__   \ \__/ /  
  \____)   \____/   (_/    \__/      \_/        /_____(    \____/   
                                                                
Dapp: https://www.jungle-protocol.com/
Telegram: https://t.me/Jungle_Protocol
Twitter: https://twitter.com/Jungle_Protocol
 */

import "./Ownable.sol";
import "./IAttackRewardCalculator.sol";
import "./IBanansToken.sol";
import "./IMonkey.sol";
import "./IStolenPool.sol";
import "./IDexInterfacer.sol";
import "./IBananChef.sol";
import "./IFullProtec.sol";

/**
Manager for config variables

Notes:
- once operation is stable, timelock will be set as owner
- openBananChefDeposits: first stolen pool epoch (epoch 0) starts at the same time as the banan chef deposits open
 */


contract Config is Ownable {
    //======================================================================================
    // setup
    //======================================================================================

    IMonkey public monkey;
    IBanansToken public banans;
    IStolenPool public stolenPool;
    IAttackRewardCalculator public rewardCalculator;
    IDexInterfacer public dexInterfacer;
    IBananChef public bananChef;
    IFullProtec public bananFullProtec;

    address public treasuryAddress;
    address public uniswapFactoryAddress; 
    address public uniswapRouterAddress; 
    address public banansPoolAddress;
    address public timelockControllerAddress;
    address public banansAddress;
    address public bananChefAddress;
    address public bananFullProtecAddress;
    address public bananStolenPoolAddress;
    address public monkeyAddress;
    address public randomizerAddress; 
    address public attackRewardCalculatorAddress;
    address public dexInterfacerAddress;

    constructor(
        address _treasuryAddress,
        address _uniswapFactoryAddress,
        address _uniswapRouterAddress,
        address _randomizerAddress
    ) {
        treasuryAddress = _treasuryAddress;
        uniswapFactoryAddress = _uniswapFactoryAddress;
        uniswapRouterAddress = _uniswapRouterAddress;
        randomizerAddress = _randomizerAddress;
    }

    function transferOwnershipToTimelock() external onlyOwner {
        transferOwnership(timelockControllerAddress);
    }

    //======================================================================================
    // include setters for each "global" parameter --> gated by onlyOwner
    //======================================================================================

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    function setUniswapFactoryAddress(address _uniswapFactoryAddress) external onlyOwner {
        uniswapFactoryAddress = _uniswapFactoryAddress;        
    }

    function setUniswapRouterAddress(address _uniswapRouterAddress) external onlyOwner {
        uniswapRouterAddress = _uniswapRouterAddress;        
    }

    function setBanansPoolAddress(address _banansPoolAddress) external onlyOwner {
        banansPoolAddress = _banansPoolAddress;        
    }

    function setTimelockControllerAddress(address _timelockControllerAddress) external onlyOwner {
        timelockControllerAddress = _timelockControllerAddress;       
    }

    function setBananTokenAddress(address _bananTokenAddress) external onlyOwner {
        banansAddress = _bananTokenAddress;
        banans = IBanansToken(_bananTokenAddress);    
    }

    function setBananChefAddress(address _bananChefAddress) external onlyOwner {
        bananChefAddress = _bananChefAddress;
        bananChef = IBananChef(_bananChefAddress);       
    }

    function setBananFullProtecAddress(address _fullProtecAddress) external onlyOwner {
        bananFullProtecAddress = _fullProtecAddress;
        bananFullProtec = IFullProtec(_fullProtecAddress);      
    }

    function setBananStolenPoolAddress(address _stolenPoolAddress) external onlyOwner {
        bananStolenPoolAddress = _stolenPoolAddress;
        stolenPool = IStolenPool(_stolenPoolAddress);   
    }

    function setMonkeyAddress(address _monkeyAddress) external onlyOwner {
        monkeyAddress = _monkeyAddress;
        monkey = IMonkey(_monkeyAddress);       
    }

    function setRandomizerAddress(address _randomizerRequesterAddress) external onlyOwner {
        randomizerAddress = _randomizerRequesterAddress;        
    }

    function setRewardCalculatorAddress(address _rewardCalculatorAddress) external onlyOwner {
        attackRewardCalculatorAddress = _rewardCalculatorAddress;
        rewardCalculator = IAttackRewardCalculator(_rewardCalculatorAddress);       
    }

    function setDexInterfacerAddress(address _dexInterfacerAddress) external onlyOwner {
        dexInterfacerAddress = _dexInterfacerAddress;
        dexInterfacer = IDexInterfacer(_dexInterfacerAddress);      
    }

    //======================================================================================
    // NEW SETTERS FOR BANANS CONFIG (CALLS FUNCTIONS ON BANANS)
    //======================================================================================

    function setBuyTaxRate(uint16 _buyTaxRate) external onlyOwner {
        banans.setBuyTaxRate(_buyTaxRate);
    }

    function setSellTaxRate(uint16 _sellTaxRate) external onlyOwner {
        banans.setSellTaxRate(_sellTaxRate);
    }

    function setFinalTaxRate() external onlyOwner {
        banans.setFinalTaxRate();
    }

    function removeMaxWallet() external onlyOwner {
        banans.removeMaxWallet();
    }

    function enableTrading() external onlyOwner {
        banans.enableTrading();
    }

    function addDexAddress(address _dexAddress) external onlyOwner {
        banans.addDexAddress(_dexAddress);
    }

    function removeDexAddress(address _dexAddress) external onlyOwner {
        banans.removeDexAddress(_dexAddress);
    }

    function setMaxScaleFactorDecreasePercentagePerDebase(uint256 _maxScaleFactorDecreasePercentagePerDebase) external onlyOwner {
        banans.setMaxScaleFactorDecreasePercentagePerDebase(_maxScaleFactorDecreasePercentagePerDebase);
    }

    function setTaxSwapAmountThreshold(uint256 _taxSwapAmountThreshold) external onlyOwner {
        banans.setTaxSwapAmountThreshold(_taxSwapAmountThreshold);
    }

    function setDivertTaxToStolenPoolRate(uint256 _divertRate) external onlyOwner {
        banans.setDivertTaxToStolenPoolRate(_divertRate);
    }

    //======================================================================================
    // NEW SETTERS FOR MONKEY (CALLS FUNCTIONS ON MONKEY)
    //======================================================================================

    function setMonkeyMintIsOpen(bool _monkeyMintIsOpen) external onlyOwner {
        monkey.setMonkeyMintIsOpen(_monkeyMintIsOpen);
    }

    function setMonkeyBatchSize(uint16 _monkeyBatchSize) external onlyOwner {
        monkey.setMonkeyBatchSize(_monkeyBatchSize);
    }

    function setMonkeyMintSecondsBetweenBatches(uint32 _monkeyMintSecondsBetweenBatches) external onlyOwner {
        monkey.setMonkeyMintSecondsBetweenBatches(_monkeyMintSecondsBetweenBatches);
    }

    function setMonkeyMaxPerWallet(uint8 _monkeyMaxPerWallet) external onlyOwner {
        monkey.setMonkeyMaxPerWallet(_monkeyMaxPerWallet);
    }

    function setMonkeyMintPriceInBanans(uint128 _monkeyMintPriceInBanans) external onlyOwner {
        monkey.setMonkeyMintPriceInBanans(_monkeyMintPriceInBanans);
    }

    function setMonkeyMintBananFeePercentageToBurn(uint16 _monkeyMintBananFeePercentageToBurn) external onlyOwner {
        monkey.setMonkeyMintBananFeePercentageToBurn(_monkeyMintBananFeePercentageToBurn);
    }

    function setMonkeyMintBananFeePercentageToStolenPool(uint16 _monkeyMintBananFeePercentageToStolenPool) external onlyOwner {
        monkey.setMonkeyMintBananFeePercentageToStolenPool(_monkeyMintBananFeePercentageToStolenPool);
    }

    function setMonkeyMintTier1Threshold(uint16 _monkeyMintTier1Threshold) external onlyOwner {
        monkey.setMonkeyMintTier1Threshold(_monkeyMintTier1Threshold);
    }

    function setMonkeyMintTier2Threshold(uint16 _monkeyMintTier2Threshold) external onlyOwner {
        monkey.setMonkeyMintTier2Threshold(_monkeyMintTier2Threshold);
    }

    function setMonkeyHP(uint8 _monkeyHP) external onlyOwner {
        monkey.setMonkeyHP(_monkeyHP);
    }

    function setMonkeyHitRate(uint16 _monkeyHitRate) external onlyOwner {
        monkey.setMonkeyHitRate(_monkeyHitRate);
    }

    function setMonkeyAttackIsOpen(bool _isOpen) external onlyOwner {
        stolenPool.setStolenPoolAttackIsOpen(_isOpen);
        monkey.setMonkeyAttackIsOpen(_isOpen);
    }

    function setAttackCooldownSeconds(uint32 _attackCooldownSeconds) external onlyOwner {
        monkey.setAttackCooldownSeconds(_attackCooldownSeconds);
    }

    function setAttackHPDeductionAmount(uint8 _attackHPDeductionAmount) external onlyOwner {
        monkey.setAttackHPDeductionAmount(_attackHPDeductionAmount);
    }

    function setAttackHPDeductionThreshold(uint16 _attackHPDeductionThreshold) external onlyOwner {
        monkey.setAttackHPDeductionThreshold(_attackHPDeductionThreshold);
    }


    //======================================================================================
    // NEW SETTERS FOR BANAN CHEF (CALLS FUNCTIONS ON BANAN CHEF)
    //======================================================================================

    function setBananChefPoolAllocPoints(uint256 _pid, uint128 _allocPoints, bool _withUpdate) external onlyOwner {
        bananChef.setAllocationPoint(_pid, _allocPoints, _withUpdate);
    }

    function setBananChefLockDuration(uint256 _pid, uint256 _lockDuration) external onlyOwner {
        bananChef.setLockDuration(_pid, _lockDuration);
    }

    function updateBananChefRewardPerBlock(uint88 _bananChefRewardPerBlock) external onlyOwner {
        bananChef.updateRewardPerBlock(_bananChefRewardPerBlock);
    }

    function setBananChefDebaseMultiplier(uint48 _debaseMultiplier) external onlyOwner {
        bananChef.setDebaseMultiplier(_debaseMultiplier);
    }

    function openBananChefDeposits() external onlyOwner {
        bananChef.openBananChefDeposits();
        stolenPool.setStolenPoolOpenTimestamp();
    }

    function setDepositIsPaused(bool _depositIsPaused) external onlyOwner {
        bananChef.setDepositIsPaused(_depositIsPaused);
    }

    function setClaimTaxRate(uint16 _maxClaimTaxRate) external onlyOwner {
        bananChef.setClaimTaxRate(_maxClaimTaxRate);
    }

    function setFullProtecLiquidityProportion(uint16 _fullProtecLiquidityProportion) external onlyOwner {
        bananChef.setFullProtecLiquidityProportion(_fullProtecLiquidityProportion);
    }

    //======================================================================================
    // NEW SETTERS FOR FULL PROTEC
    //======================================================================================

    function openFullProtecDeposits() external onlyOwner {
        bananFullProtec.openFullProtecDeposits();
    }

    function setFullProtecLockDuration(uint32 _lockDuration) external onlyOwner {
        bananFullProtec.setFullProtecLockDuration(_lockDuration);
    }

    function setThresholdFullProtecBananBalance(uint224 _thresholdFullProtecBananBalance) external onlyOwner {
        bananFullProtec.setThresholdFullProtecBananBalance(_thresholdFullProtecBananBalance);
    }

    //======================================================================================
    // NEW SETTERS FOR STOLEN POOL 
    //======================================================================================

    function setAttackBurnPercentage(uint16 _attackBurnPercentage) external onlyOwner {
        stolenPool.setAttackBurnPercentage(_attackBurnPercentage);
    }

    function setIsApprovedStolenPoolDepositor(address _depositor, bool _isApproved) external onlyOwner {
        stolenPool.setIsApprovedDepositor(_depositor, _isApproved);
    }
}