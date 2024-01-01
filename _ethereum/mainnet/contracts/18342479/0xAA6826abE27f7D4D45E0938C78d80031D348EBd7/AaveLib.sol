// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "./ERC20.sol";

import "./IDataProvider.sol";
import "./ILendingPoolV3.sol";
import "./IPriceOracleGetter.sol";
import "./IRewardsController.sol";
import "./console.sol";

library AaveLibPub {
  struct FlashLoanExtra {
		address[] loanAssets;
		uint[] loanAmounts;
		uint[] premiums;
	}

  /******************************************************
   *                                                    *
   *                  ACTIONS FUNCTIONS                 *
   *                                                    *
   ******************************************************/

  function harvest(address _dataProvider, address _rewardsController, address[] memory _tokens) external {
		uint256 length = _tokens.length * 2;
		address[] memory aaveAssets = new address[](length);
		for(uint256 i = 0; i < length;) {
			(address aToken,, address vToken) = IDataProvider(_dataProvider).getReserveTokensAddresses(_tokens[i / 2]);
			aaveAssets[i] = aToken;
    	aaveAssets[i + 1] = vToken;

			unchecked { i += 2; }
		}

		IRewardsController(_rewardsController).claimAllRewardsToSelf(aaveAssets);
	}

    // Borrow from Aave given a want, following certain rate and proportions
  function borrowQuoted(
    address priceOracle,
    address lendingPool,
    address reserveRef,
    uint decimalsRef,
		uint amountRef,
    address reserveBorrow,
    uint decimalsBoffow,
    uint interestRateMode
  ) external returns(uint amountBorrow) {
      amountBorrow = quoteReserves(
        reserveRef,
        decimalsRef,
        amountRef,
        reserveBorrow,
        decimalsBoffow,
        priceOracle
      );

      ILendingPool(lendingPool).borrow(reserveBorrow, amountBorrow, interestRateMode, 0, address(this));
  }

  // function flashLoan(
  //   address lendingPool,
  //   address[] memory loanAssets, 
  //   uint256[] memory loanAmounts,
  //   bytes memory callbackData // last parameter of the callback should be bytes(0)
  // ) external {
  //   uint[] memory loanModes = new uint[](loanAssets.length);
  //   console.log(lendingPool);
  //   ILendingPool(lendingPool).flashLoan(
  //     address(this),
  //     loanAssets, 
  //     loanAmounts, 
  //     loanModes,
  //     address(this),
  //     callbackData,
  //     0
  //   );
  // }

  // function repayFlashLoan(address lendingPool, bytes memory flashLoanExtraData) external {
  //   ILendingPool(lendingPool).repayFlashLoan(flashLoanExtraData);
  // }

  /******************************************************<
   *                                                    *
   *                    VIEW FUNCTIONS                  *
   *                                                    *
   ******************************************************/

  function quoteReserves(
    address reserveIn,
    uint decimalsIn,
		uint amountIn,
    address reserveOut,
    uint decimalsOut,
    address priceOracle
	) public view returns (uint amountOut) {
    // It is expected that userEModeCategory == 0
    
    uint priceIn = IPriceOracleGetter(priceOracle).getAssetPrice(reserveIn); 
		uint assetInUnit = 10 ** decimalsIn;

    uint priceOut = IPriceOracleGetter(priceOracle).getAssetPrice(reserveOut);  
		uint assetOutUnit = 10 ** decimalsOut;

    uint amountInBase = amountIn * priceIn / assetInUnit;
		amountOut = (amountInBase * assetOutUnit) / priceOut;
	}

  function getMaxWithdraw(
    address reserve,
    uint decimals,
    address lendingPool,
    address priceOracle
  ) public view returns(uint256 maxWithdraw) {
    (uint256 totalCollateralBase, uint256 totalDebtBase, uint256 availableBorrowBase,,,) = ILendingPool(lendingPool).getUserAccountData(address(this));
    uint maxWithdrawBase = (availableBorrowBase * totalCollateralBase) / (totalDebtBase + availableBorrowBase);
    return quoteReserveFromBase(maxWithdrawBase, reserve, decimals, priceOracle);
  }

  function quoteReserveFromBase(
    uint amountBase,
    address reserve,
    uint decimals,
    address priceOracle
  ) public view returns(uint256 amount) {
    uint priceOut = IPriceOracleGetter(priceOracle).getAssetPrice(reserve);  
		uint assetOutUnit = 10 ** decimals;
    return (amountBase * assetOutUnit) / priceOut;
  }
}

library AaveLib {
  /******************************************************
   *                                                    *
   *                  ACTIONS FUNCTIONS                 *
   *                                                    *
   ******************************************************/

  function _deposit(ILendingPool lendingPool, address asset, uint256 amount) internal {
    lendingPool.deposit(asset, amount, address(this), 0);
  }

  function _borrow(ILendingPool lendingPool, address asset, uint256 amount, uint256 interestRateMode) internal {
    lendingPool.borrow(asset, amount, interestRateMode, 0, address(this));
  }

  function _repay(ILendingPool lendingPool, address asset, uint256 amount, uint256 rateMode) internal returns (uint256) {
    return lendingPool.repay(asset, amount, rateMode, address(this));
  }

  function _withdraw(ILendingPool lendingPool, address asset, uint256 amount, address to) internal returns (uint256) {
    return lendingPool.withdraw(asset, amount, to);
  }

  function _getReserveTokensAddresses(IDataProvider dataProvider, address asset) internal view returns (
        address aTokenAddress,
        address stableDebtTokenAddress,
        address variableDebtTokenAddress
    ) {
    return dataProvider.getReserveTokensAddresses(asset);
  }

  /******************************************************
   *                                                    *
   *                    VIEW FUNCTIONS                  *
   *                                                    *
   ******************************************************/

  // return supply and borrow balance
  function userReserves(address _asset, address _dataProvider) internal view returns (uint256 supplyBal, uint256 sDebtBal, uint256 vDebtBal) {
    (supplyBal, sDebtBal, vDebtBal,,,,,,) = IDataProvider(_dataProvider).getUserReserveData(_asset, address(this));
  }
}