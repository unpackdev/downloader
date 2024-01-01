// SPDX-License-Identifier: MIT

/// @author Tient Technologies (Twitter:https://twitter.com/tient_tech | Github:https://github.com/Tient-Technologies | | LinkedIn:https://www.linkedin.com/company/tient-technologies/)
/// @dev NiceArti (https://github.com/NiceArti)
/// To maintain developer you can also donate to this address - 0xDc3d3fA1aEbd13fF247E5F5D84A08A495b3215FB
/// @title The CflatsExchange contract is used for exchanging tokens to $CFLAT token
/// The contract was inspired by UniswapV2

pragma solidity ^0.8.18;

import "./IERC20Metadata.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Harvest.sol";
import "./ICflatsDatabase.sol";
import "./CflatsDappRequirements.sol";
import "./ICflatsExchange.sol";


contract CflatsExchange is ICflatsExchange, CflatsDappRequirements, Harvest
{
    using SafeERC20 for IERC20;
    address public immutable ACCENT_TOKEN;

    error ExchangeTokenIsAlreadyAddedError();
    error ExchangeTokenPairIsNotCreatedError();
    error ExchangeTokenRateZeroError();
    error ExchangeTokenScopeZeroError();
    error SwapAmountIsTooSmallError();


    mapping(address tokenIn =>
        mapping(address tokenOut => CflatsExchangerInfo exchanger)
    ) private _exchangeInfo;


    constructor(
        address accentToken,
        ICflatsDatabase database
    ) CflatsDappRequirements(database)
    {
        ACCENT_TOKEN = accentToken;
    }



    //************************* startregion: CALLABLE FUNCTIONS  *************************//

    function getExchangeInfo(address exchangeToken)
        public
        view
        returns (CflatsExchangerInfo memory)
    {
        return _exchangeInfo[exchangeToken][ACCENT_TOKEN];
    }


    function getAmountsOut(
        address exchangeToken,
        uint256 amountsIn
    ) public view returns (uint256)
    {
        // standart token accurancy for native evm chain coin
        uint8 exchangeTokenDecimals = 18;

        // token accurancy for native evm chain coin
        if(exchangeToken != address(0))
        {
            exchangeTokenDecimals = IERC20Metadata(exchangeToken).decimals();
        }


        uint8 accentTokenDecimals = IERC20Metadata(ACCENT_TOKEN).decimals();
        uint256 currentExchangeRate = getExchangeInfo(exchangeToken).currentExchangeRate;


        // if token decimals are equal so just return amounts out without
        // doing magic with exchange token accurancy 
        if(accentTokenDecimals == exchangeTokenDecimals)
        {
            return amountsIn * currentExchangeRate;
        }


        // if the accurancy is not equal we doing magic
        uint256 accurancyDifference = exchangeTokenDecimals > accentTokenDecimals ? 
            exchangeTokenDecimals - accentTokenDecimals : 
            accentTokenDecimals - exchangeTokenDecimals;


        // if `exchangeTokenDecimals` is greather than `accentTokenDecimals`
        // we remove excessive accurancy to `exchangeToken` and return the number of tokens that the user will receive
        if(exchangeTokenDecimals > accentTokenDecimals)
        {
            return amountsIn / 10**accurancyDifference * currentExchangeRate;
        }

        // if `exchangeTokenDecimals` is less than `accentTokenDecimals`
        // we add accurancy to `exchangeToken` and return the number of tokens that the user will receive
        return amountsIn * 10**accurancyDifference * currentExchangeRate;
    }

    //************************* endregion: CALLABLE FUNCTIONS  *************************//




    //************************* startregion: SEND FUNCTIONS  *************************//
    function addNewExchangeTokenPair(
        address exchangeToken, 
        uint256 exchangeRate,
        uint256 scopedTokenReserves,
        uint256 minSwapAmount
    ) external onlyOperator
    {
        if(getExchangeInfo(exchangeToken).minExchangeRate > 0)
        {
            revert ExchangeTokenIsAlreadyAddedError();
        }
        if(exchangeRate == 0)
        {
            revert ExchangeTokenRateZeroError();
        }
        if(scopedTokenReserves == 0)
        {
            revert ExchangeTokenScopeZeroError();
        }

        _exchangeInfo[exchangeToken][ACCENT_TOKEN] = CflatsExchangerInfo(
            scopedTokenReserves,
            scopedTokenReserves,
            minSwapAmount,
            exchangeRate,
            exchangeRate
        );
    }

    function deleteExchangeTokenPair(address exchangeToken) external 
    {
        delete _exchangeInfo[exchangeToken][ACCENT_TOKEN];
    }


    function swapExactTokensForTokens(address exchangeToken, uint256 amountsIn) external 
    {
        CflatsExchangerInfo memory _cflatsExchangerInfo = getExchangeInfo(exchangeToken);

        if(_cflatsExchangerInfo.minExchangeRate == 0)
        {
            revert ExchangeTokenPairIsNotCreatedError();
        }
        if(amountsIn < _cflatsExchangerInfo.minSwapAmount)
        {
            revert SwapAmountIsTooSmallError();
        }

        // exchange tokens transferring to sender their amounts by exchange rate
        uint256 transferAmount = getAmountsOut(exchangeToken, amountsIn);
        IERC20(exchangeToken).safeTransferFrom(msg.sender, address(this), amountsIn);
        IERC20(ACCENT_TOKEN).safeTransfer(msg.sender, transferAmount);
        
        // updating info for `exchangeToken`
        _update(exchangeToken);

        emit Exchanged(exchangeToken, ACCENT_TOKEN, amountsIn, transferAmount);
    }


    function swapExactEthForTokens() external payable
    {
        address exchangeToken = address(0);
        CflatsExchangerInfo memory _cflatsExchangerInfo = getExchangeInfo(exchangeToken);

        if(_cflatsExchangerInfo.minExchangeRate == 0)
        {
            revert ExchangeTokenPairIsNotCreatedError();
        }

        uint256 amountsIn = msg.value;
        if(amountsIn < _cflatsExchangerInfo.minSwapAmount)
        {
            revert SwapAmountIsTooSmallError();
        }

        // exchange tokens transferring to sender their amounts by exchange rate
        uint256 transferAmount = getAmountsOut(exchangeToken, amountsIn);
        IERC20(ACCENT_TOKEN).safeTransfer(msg.sender, transferAmount);

        // updating info for `exchangeToken`
        _update(exchangeToken);

        emit Exchanged(exchangeToken, ACCENT_TOKEN, amountsIn, transferAmount);
    }

    //************************* endregion: SEND FUNCTIONS  *************************//




    //************************* startregion: HELPER FUNCTIONS  *************************//

    function _update(
        address exchangeToken
    ) private 
    {
        CflatsExchangerInfo storage _cflatsExchangerInfo = _exchangeInfo[exchangeToken][ACCENT_TOKEN];
        uint256 currentExchangeTokenReserves = _getExchangeTokenCurrentReserves(exchangeToken);

        if(currentExchangeTokenReserves >= _cflatsExchangerInfo.scopedTokenReserves)
        {
            uint256 currentReservesScope = _cflatsExchangerInfo.scopedTokenReserves;
            uint256 currentExchangeRate = _cflatsExchangerInfo.currentExchangeRate;

            // adds five percent from prev scope
            unchecked
            {
                _cflatsExchangerInfo.scopedTokenReserves += currentReservesScope / 20;

                // exchange rate increases to five percents
                _cflatsExchangerInfo.currentExchangeRate -= currentExchangeRate / 20;
            }
        }
        // this state will activate only when owner will claim funds so settings will be setted to default
        else if(currentExchangeTokenReserves == 0 && (_cflatsExchangerInfo.scopedTokenReserves > _cflatsExchangerInfo.minScopedTokenReserves))
        {
            _cflatsExchangerInfo.scopedTokenReserves = _cflatsExchangerInfo.minScopedTokenReserves;
            _cflatsExchangerInfo.currentExchangeRate = _cflatsExchangerInfo.minExchangeRate;
        }
    }


    function _getExchangeTokenCurrentReserves(address exchangeToken) private view returns(uint256)
    {
        // get current balance for ERC20 tokens
        if(exchangeToken != address(0))
        {
            return IERC20(exchangeToken).balanceOf(address(this));
        }

        // get current balance for native chain token
        return address(this).balance;
    }

    //************************* endregion: HELPER FUNCTIONS  *************************//
}