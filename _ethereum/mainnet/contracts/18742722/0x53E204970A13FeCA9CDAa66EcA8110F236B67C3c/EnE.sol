//SPDX-License-Identifier: MIT
pragma solidity =0.8.23;

interface EnE {
    //events
    event SwapThresholdChange(uint threshold);
    event OverLiquifiedThresholdChange(uint threshold);
    event OnSetTaxes(
        uint buy, 
        uint sell, 
        uint transfer_
    );
    event ManualSwapChange(bool status);
    event MaxWalletBalanceUpdated(uint256 percent);
    event MaxTransactionAmountUpdated(uint256 percent);
    event ExcludeAccount(address indexed account, bool indexed exclude);
    event ExcludeFromWalletLimits(address indexed account, bool indexed exclude);
    event ExcludeFromTransactionLimits(address indexed account, bool indexed exclude);
    event OwnerSwap();
    event OnEnableTrading();
    event OnProlongLPLock(uint UnlockTimestamp);
    event OnReleaseLP();
    event RecoverETH();
    event NewPairSet(address Pair, bool Add);
    event LimitTo20PercentLP();
    event NewRouterSet(address _newdex);
    event NewFeeWalletSet(address indexed NewTaxWallet);
    event RecoverTokens(uint256 amount);
    event TokensAirdroped(address indexed sender, uint256 total, uint256 amount);
    //errors
    error ZeroAddress();
    error SameAddress();
    error ContractAddress(); 
    error PairAddress();
}