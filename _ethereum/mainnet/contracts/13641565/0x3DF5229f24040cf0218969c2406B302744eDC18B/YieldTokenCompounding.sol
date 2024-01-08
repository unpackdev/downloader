// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IVault.sol";
import "./ITranche.sol";
import "./IERC20.sol";

/// @notice Yield Token Compounding on top of element.finance.
contract YieldTokenCompounding {
    //Address of balancer v2 vault that holds all tokens
    IVault public immutable balVault;
    uint256 internal immutable _MAX_VALUE = type(uint256).max;

    constructor(address _balVault) {
        balVault = IVault(_balVault);
    }

    /**
    @notice Do Yield Token Compounding i.e. convert base tokens to PTs, YTs and sell PTs for base tokens and reconvert for more YTs recursively
    @param _n the number of compounding to do
    @param _trancheAddress the element.fi tranche contract address for the token to compound
    @param _balancerPoolId of the pool containing PTs and Base Tokens. AMM formula is constant power sum formula.
    @param _amount The amount of base tokens supplied initially
    @param _expectedYtOutput slippage protection
    @return number of YTs user obtained, number of base tokens spent (useful for YTC calculator)
    @dev assume user has approved this contract for base tokens.
     */
    function compound(
        uint8 _n,
        address _trancheAddress,
        bytes32 _balancerPoolId,
        uint256 _amount,
        uint256 _expectedYtOutput,
        uint256 _expectedBaseTokensSpent
    ) public returns (uint256, uint256) {
        require (_n > 0 && _n < 31, "n has to be between 1 to 255 inclusive.");
        // Step 1: Assume the user approves the contract for the base token [permit support is a nice to have in general but for simplicity fine to omit]

        // Step 2: User calls deposit, the smart contract uses transferFrom to move the tokens from the user to the WP for the tranche.
        ITranche tranche = ITranche(_trancheAddress);
        address baseTokenAddress = address(tranche.underlying());
        uint256 initialBalance = IERC20(baseTokenAddress).balanceOf(msg.sender);
        //address(uint160(addr)) makes it of type address payable.
        address payable wrappedPositionAddress = address(uint160(address(tranche.position())));
        
        // tranche.underlying() = baseToken. Transfer base tokens from user to WP.
        tranche.underlying().transferFrom(msg.sender, wrappedPositionAddress, _amount);

        // Step 5: repeat steps 3-4 N times.
        uint256 ytBalance = _forLoop(_n, tranche, _balancerPoolId, baseTokenAddress, wrappedPositionAddress);

        uint256 baseTokensSpent = _baseTokensSpent(baseTokenAddress, initialBalance);
        
        require(ytBalance >= _expectedYtOutput, "Too much slippage: YT");
        require(baseTokensSpent <= _expectedBaseTokensSpent, "Too much slippage: BT");

        // Step 6: Send the smart contract balance of yt to the user
        // Transfer YTs from this contract to the user
        tranche.interestToken().transfer(msg.sender, ytBalance);
        // There will be 0 PTs left (all compounded away). Any baseTokens `_amount` have already been sent to the user on last compounding.     
        
        return (ytBalance, baseTokensSpent);   
    }
    
    function _baseTokensSpent(address baseTokenAddress, uint256 initialBalance) internal view returns (uint256) {
        return initialBalance - IERC20(baseTokenAddress).balanceOf(msg.sender);
    }
    
    function _forLoop(uint8 _n, ITranche tranche, bytes32 _balancerPoolId, 
        address baseTokenAddress, address payable wrappedPositionAddress) 
        internal returns(uint256) {
        // The amount of yts accrued so far.
        uint256 ytBalance = 0;
        for (uint8 i = 0; i < _n; i++) {
            // Step 3: Smart contract calls prefundedDeposit on the tranche with destination of itself
            (uint256 pt, uint256 yt) = tranche.prefundedDeposit(address(this));
            ytBalance += yt;
            // Step 4: Smart contract calls balancer smart contract and sells PT for base and indicates the wp as the destination.
            // Note: if last compounding, then send base tokens to user instead of WP
            swapPTsForBaseTokenOnBalancer(
                address(tranche),
                _balancerPoolId,
                baseTokenAddress,
                address(this),
                i == _n - 1 ? msg.sender : wrappedPositionAddress,
                pt
            );
        }
        return ytBalance;
    }

    function swapPTsForBaseTokenOnBalancer(
        address _trancheAddress,
        bytes32 _poolId,
        address _baseTokenAddress,
        address _fromAddress,
        address payable _receiverAddress,
        uint256 _amount
    ) internal returns (uint256) {
        // Swap PTs (tranche contract token) for base tokens
        IVault.SwapKind kind = IVault.SwapKind.GIVEN_IN;
        IAsset assetIn = IAsset(_trancheAddress);
        IAsset assetOut = IAsset(_baseTokenAddress);
        IVault.SingleSwap memory singleSwap = IVault.SingleSwap({
            poolId: _poolId,
            kind: kind,
            assetIn: assetIn,
            assetOut: assetOut,
            amount: _amount,
            userData: bytes("")
        });

        // Sell from this contract to Wrapped Position contract /userAddress (for last compounding)
        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: _fromAddress,
            fromInternalBalance: false,
            recipient: _receiverAddress,
            toInternalBalance: false
        });

        uint256 limit = 0;
        uint256 deadline = _MAX_VALUE; 

        uint256 baseTokensReceived = balVault.swap(
            singleSwap,
            funds,
            limit,
            deadline
        );
        return baseTokensReceived;
    }
    
    /// @dev Approve balancer vault to spend this contract's tranche tokens (PTs aka fixed yield tokens)
    /// @param _trancheAddress The tranche address
    function approveTranchePTOnBalancer(address _trancheAddress) public {
        ITranche tranche = ITranche(_trancheAddress);
        tranche.approve(address(balVault), _MAX_VALUE);
    }

    /// @dev Check allowance of balancer vault for spending this contract's tranche tokens (PTs aka fixed yield tokens)
    /// @param _trancheAddress The tranche address
    function checkTranchePTAllowanceOnBalancer(address _trancheAddress) public view returns (uint256) {
        ITranche tranche = ITranche(_trancheAddress);
        return tranche.allowance(address(this), address(balVault));
    }
}
