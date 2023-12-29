// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./TransferHelper.sol";
import "./SanctionsCompliance.sol";
import "./IRoyaltyEngineV1.sol";

/*//////////////////////////////////////////////////////////////////////////
                        Royalty Payout Helper
//////////////////////////////////////////////////////////////////////////*/

/// @title Royalty Payout Helper
/// @notice Abstract contract to help payout royalties using the Royalty Registry
/// @dev Does not manage updating the sanctions oracle and expects the child contract to implement
/// @author transientlabs.xyz
/// @custom:last-updated 2.5.0
abstract contract RoyaltyPayoutHelper is TransferHelper, SanctionsCompliance {
    /*//////////////////////////////////////////////////////////////////////////
                                  State Variables
    //////////////////////////////////////////////////////////////////////////*/

    address public weth;
    IRoyaltyEngineV1 public royaltyEngine;

    /*//////////////////////////////////////////////////////////////////////////
                                  Constructor
    //////////////////////////////////////////////////////////////////////////*/

    /// @param sanctionsOracle - the init sanctions oracle
    /// @param wethAddress - the init weth address
    /// @param royaltyEngineAddress - the init royalty engine address
    constructor(address sanctionsOracle, address wethAddress, address royaltyEngineAddress) SanctionsCompliance(sanctionsOracle) {
        weth = wethAddress;
        royaltyEngine = IRoyaltyEngineV1(royaltyEngineAddress);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            Internal State Functions
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to update the WETH address
    /// @dev Care should be taken to ensure proper access control for this function
    /// @param wethAddress The new WETH token address
    function _setWethAddress(address wethAddress) internal {
        weth = wethAddress;
    }

    /// @notice Function to update the royalty engine address
    /// @dev Care should be taken to ensure proper access control for this function
    /// @param royaltyEngineAddress The new royalty engine address
    function _setRoyaltyEngineAddress(address royaltyEngineAddress) internal {
        royaltyEngine = IRoyaltyEngineV1(royaltyEngineAddress);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            Royalty Payout Function
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Function to payout royalties from the contract balance based on sale price
    /// @dev if the call to the royalty engine reverts or if the return values are invalid, no payments are made
    /// @dev if the sum of the royalty payouts is greater than the salePrice, the loop exits early for gas savings (this shouldn't happen in reality)
    /// @dev if this is used in a call where tokens should be transferred from a sender, it is advisable to 
    ///      first transfer the required amount to the contract and then call this function, as it will save on gas
    /// @param token The contract address for the token
    /// @param tokenId The token id
    /// @param currency The address of the currency to send to recipients (null address == ETH)
    /// @param salePrice The sale price for the token
    /// @return remainingSale The amount left over in the sale after paying out royalties
    function _payoutRoyalties(address token, uint256 tokenId, address currency, uint256 salePrice)
        internal
        returns (uint256 remainingSale)
    {
        remainingSale = salePrice;
        if (address(royaltyEngine).code.length == 0) return remainingSale;
        try royaltyEngine.getRoyalty(token, tokenId, salePrice) returns (
            address payable[] memory recipients, uint256[] memory amounts
        ) {
            if (recipients.length != amounts.length) return remainingSale;

            for (uint256 i = 0; i < recipients.length; i++) {
                if (_isSanctioned(recipients[i], false)) continue; // don't pay to sanctioned addresses
                if (amounts[i] > remainingSale) break;
                remainingSale -= amounts[i];
                if (currency == address(0)) {
                    _safeTransferETH(recipients[i], amounts[i], weth);
                } else {
                    _safeTransferERC20(recipients[i], currency, amounts[i]);
                }
            }

            return remainingSale;
        } catch {
            return remainingSale;
        }
    }
}
