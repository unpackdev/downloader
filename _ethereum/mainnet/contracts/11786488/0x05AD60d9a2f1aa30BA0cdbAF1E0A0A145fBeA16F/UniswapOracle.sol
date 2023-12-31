// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./IUniswapFactory.sol";
import "./OracleBase.sol";


contract UniswapOracle is OracleBase {
    IUniswapFactory private constant _UNISWAP_FACTORY = IUniswapFactory(0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95);
    IERC20 private constant _ETH = IERC20(0x0000000000000000000000000000000000000000);

    function _getBalances(IERC20 srcToken, IERC20 dstToken) internal view override returns (uint256 srcBalance, uint256 dstBalance) {
        if (srcToken == _ETH) {
            address exchange = _UNISWAP_FACTORY.getExchange(dstToken);
            srcBalance = exchange.balance;
            dstBalance = dstToken.balanceOf(exchange);
        } else if (dstToken == _ETH) {
            address exchange = _UNISWAP_FACTORY.getExchange(srcToken);
            srcBalance = srcToken.balanceOf(exchange);
            dstBalance = exchange.balance;
        } else {
            revert("Unsupported tokens");
        }
    }
}
