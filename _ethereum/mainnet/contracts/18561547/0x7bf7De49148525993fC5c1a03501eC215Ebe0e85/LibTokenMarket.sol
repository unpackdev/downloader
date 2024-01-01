// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./LibAppStorage.sol";
import "./IClaimToken.sol";
import "./IPriceConsumer.sol";
import "./IUserTier.sol";
import "./IGToken.sol";
import "./LibMarketStorage.sol";
import "./IProtocolRegistry.sol";

library LibTokenMarket {
    using SafeERC20 for IERC20;

    event LoanOfferCreatedToken(
        uint256 _loanId,
        LibMarketStorage.LoanDetailsToken _loanDetailsToken
    );

    event LoanOfferAdjustedToken(
        uint256 _loanId,
        LibMarketStorage.LoanDetailsToken _loanDetails
    );

    event TokenLoanOfferActivated(
        uint256 loanId,
        address _lender,
        uint256 _stableCoinAmount,
        bool _autoSell
    );

    event LoanOfferCancelToken(
        uint256 loanId,
        address _borrower,
        LibMarketStorage.LoanStatus loanStatus
    );

    /// @dev internal function checking ERC20 collateral token approval
    /// @param _collateralTokens array of collateral token addresses
    /// @param _collateralAmounts array of collateral amounts
    /// @param isMintSp will be false for all the collateral tokens, and will be true at the time of activate loan
    /// @param borrower address of the borrower whose collateral approval is checking
    /// @return bool return the bool value true or false

    function checkApprovalCollaterals(
        address[] memory _collateralTokens,
        uint256[] memory _collateralAmounts,
        bool[] memory isMintSp,
        address borrower
    ) internal view returns (bool) {
        uint256 length = _collateralTokens.length;
        for (uint256 i = 0; i < length; i++) {
            address claimToken = IClaimToken(address(this))
                .getClaimTokenofSUNToken(_collateralTokens[i]);
            require(
                IProtocolRegistry(address(this)).isTokenEnabledForCreateLoan(
                    _collateralTokens[i]
                ) || IClaimToken(address(this)).isClaimToken(claimToken),
                "GLM: One or more tokens not approved."
            );
            require(
                IProtocolRegistry(address(this)).isTokenEnabledForCreateLoan(
                    _collateralTokens[i]
                ),
                "GTM: token not enabled"
            );
            require(!isMintSp[i], "GLM: mint error");
            uint256 allowance = IERC20(_collateralTokens[i]).allowance(
                borrower,
                address(this)
            );
            require(
                allowance >= _collateralAmounts[i],
                "GTM: Transfer amount exceeds allowance."
            );
        }

        return true;
    }

    /// @dev this function returns calulatedLTV Percentage, maxLoanAmountValue, and  collatetral Price In Borrowed Stable
    /// @param _stakedCollateralTokens addresses array of the staked collateral token by the borrower
    /// @param _stakedCollateralAmount collateral tokens amount array
    /// @param _borrowStableCoin stable coin address the borrower want to borrrower
    /// @param _loanAmountinStable loan amount in stable address decimals
    /// @param _borrower address of the borrower
    function getltvCalculations(
        address[] memory _stakedCollateralTokens,
        uint256[] memory _stakedCollateralAmount,
        address _borrowStableCoin,
        uint256 _loanAmountinStable,
        address _borrower,
        LibMarketStorage.TierType _tierType
    )
        internal
        view
        returns (
            uint256 calculatedLTV,
            uint256 maxLoanAmountValue,
            uint256 collatetralInBorrowed
        )
    {
        for (
            uint256 index = 0;
            index < _stakedCollateralAmount.length;
            index++
        ) {
            address claimToken = IClaimToken(address(this))
                .getClaimTokenofSUNToken(_stakedCollateralTokens[index]);
            if (IClaimToken(address(this)).isClaimToken(claimToken)) {
                collatetralInBorrowed =
                    collatetralInBorrowed +
                    (
                        IPriceConsumer(address(this)).getSunTokenInStable(
                            claimToken,
                            _borrowStableCoin,
                            _stakedCollateralTokens[index],
                            _stakedCollateralAmount[index]
                        )
                    );
            } else {
                collatetralInBorrowed =
                    collatetralInBorrowed +
                    (
                        IPriceConsumer(address(this))
                            .getCollateralPriceinStable(
                                _stakedCollateralTokens[index],
                                _borrowStableCoin,
                                _stakedCollateralAmount[index]
                            )
                    );
            }
        }
        calculatedLTV = (collatetralInBorrowed * 100) / _loanAmountinStable;
        maxLoanAmountValue = IUserTier(address(this)).getMaxLoanAmountToValue(
            collatetralInBorrowed,
            _borrower,
            _tierType
        );

        return (calculatedLTV, maxLoanAmountValue, collatetralInBorrowed);
    }

    /// @dev check approve of tokens, transfer token to contract and mint synthetic token if mintVip is on for that collateral token
    /// @param _loanId using loanId to make isMintSp flag true in the create loan function
    /// @param collateralAddresses collateral token addresses array
    /// @param collateralAmounts collateral token amounts array
    /// @return bool return true if succesful check all the approval of token and transfer of collateral tokens, else returns false.
    function transferCollateralsandMintSynthetic(
        uint256 _loanId,
        address[] memory collateralAddresses,
        uint256[] memory collateralAmounts,
        address borrower
    ) internal returns (bool) {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        uint256 length = collateralAddresses.length;
        for (uint256 k = 0; k < length; k++) {
            IERC20(collateralAddresses[k]).safeTransferFrom(
                borrower,
                address(this),
                collateralAmounts[k]
            );
            {
                LibProtocolStorage.Market memory market = IProtocolRegistry(
                    address(this)
                ).getSingleApproveToken(collateralAddresses[k]);
                if (
                    IProtocolRegistry(address(this)).isSyntheticMintOn(
                        collateralAddresses[k]
                    )
                ) {
                    IGToken(market.gToken).mint(borrower, collateralAmounts[k]);
                    ms.borrowerLoanToken[_loanId].isMintSp[k] = true;
                }
            }
        }
        return true;
    }
}
