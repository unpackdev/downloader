// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./Uniswap.sol";

contract UseUniswap {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    // Uniswap //
    address private constant UNISWAP = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function _swap(
        address _from,
        address _to,
        uint _amount
    ) internal {
        require(_to != address(0), "to = zero address");

        // Swap with uniswap
        IERC20(_from).safeApprove(UNISWAP, 0);
        IERC20(_from).safeApprove(UNISWAP, _amount);

        address[] memory path;

        if (_from == WETH || _to == WETH) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = WETH;
            path[2] = _to;
        }

        Uniswap(UNISWAP).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }
}
