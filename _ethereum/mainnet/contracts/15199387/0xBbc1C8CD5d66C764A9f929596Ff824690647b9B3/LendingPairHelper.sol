// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "./IBSLendingPair.sol";

////////////////////////////////////////////////////////////////////////////////////////////
///
/// @title LendingPair
/// @author @samparsky
/// @notice Helper functions to fetch data from LendingPairs
///
////////////////////////////////////////////////////////////////////////////////////////////

contract LendingPairHelper {
    IBSVault public immutable vault;

    constructor(IBSVault _vault) {
        vault = _vault;
    }

    function viewBorrowedValue(IBSLendingPair[] calldata pairs, address _account)
        external
        view
        returns (uint256[] memory totals)
    {
        totals = new uint256[](pairs.length);
        for (uint256 i = 0; i < pairs.length; i++) {
            IBSLendingPair pair = pairs[i];
            totals[i] = pair.debtToken().balanceOf(_account);
        }
    }

    function viewBorrowedValueInUSD(IBSLendingPair[] calldata pairs, address _account)
        external
        view
        returns (uint256[] memory totals)
    {
        totals = new uint256[](pairs.length);
        for (uint256 i = 0; i < pairs.length; i++) {
            IBSLendingPair pair = pairs[i];
            uint256 currentBorrowBalance = pair.borrowBalancePrior(_account);
            uint256 priceInUSD = pair.oracle().getPriceInUSD(pair.asset()) * currentBorrowBalance;
            totals[i] = priceInUSD;
        }
    }

    function viewBorrowLimit(IBSLendingPair[] calldata pairs, address _account)
        external
        view
        returns (uint256[] memory totals)
    {
        totals = new uint256[](pairs.length);
        for (uint256 i = 0; i < pairs.length; i++) {
            IBSLendingPair pair = pairs[i];
            uint256 underlyingAmount =
                vault.toUnderlying(pair.collateralAsset(), pair.collateralOfAccount(_account));

            totals[i] = pair.calcBorrowLimit(underlyingAmount);
        }
    }
}
