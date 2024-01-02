// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Swapper.sol";
import "./Quoter.sol";
import "./LibSwap.sol";
import "./ReentrancyGuard.sol";
import "./LibUtil.sol";
import "./LibAsset.sol";
import "./GenericErrors.sol";

/// @title OneTwo Router Facet
/// @author FormalCrypto
/// @notice Provides functionality for swapping
contract OneTwoRouterFacet is Swapper, Quoter, ReentrancyGuard {
    /**
     * @dev Performs multiple swaps in one transaction
     * @param _receiver Address of the receiver of the tokens
     * @param _fromAmount Amount of token to be swapped
     * @param _minAmout Minimum amount ot be received
     * @param _weth Address of wrapped native token
     * @param _partner Address of the partner
     * @param _swaps an object containing swap related data to perform swaps before bridging
     */
    function oneTwoSwap(
        address payable _receiver,
        uint256 _fromAmount,
        uint256 _minAmout,
        address _weth,
        address _partner,
        LibSwap.SwapData[] calldata _swaps
    ) external payable nonReentrant{
        if (LibUtil.isZeroAddress(_receiver)) revert InvalidReceiver();

        uint256 receivedAmount = _swap(
            _fromAmount,
            _minAmout,
            _weth,
            _swaps,
            0,
            _partner
        );

        address receivedToken = _swaps[_swaps.length - 1].toToken;
        LibAsset.transferAsset(receivedToken, _receiver, receivedAmount);
    }

    /**
     * @dev Performs quote of multiple swaps and return amount
     * @param _fromAmount Amount of token to be swapped
     * @param _weth Address of wrapped native token
     * @param _swaps an object containing swap related data to perform swaps before bridging
     */
    function oneTwoQuote(
        address,
        uint256 _fromAmount,
        uint256,
        address _weth,
        address,
        LibSwap.SwapData[] calldata _swaps
    ) public returns(uint256) {
        uint256 receivedAmount = _quote(
            _fromAmount,
            0,
            _weth,
            _swaps,
            0,
            address(0)
        );
        return receivedAmount;
    }
}