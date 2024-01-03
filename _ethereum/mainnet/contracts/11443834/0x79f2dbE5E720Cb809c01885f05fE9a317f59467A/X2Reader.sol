// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IX2Market.sol";
import "./IERC20.sol";

contract X2Reader {
    using SafeMath for uint256;

    function getMarketInfo(address _market, address _account) public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        address bullToken = IX2Market(_market).bullToken();
        address bearToken = IX2Market(_market).bearToken();

        return (
            _account.balance, // index: 0
            IX2Market(_market).latestPrice(), // index: 1
            IERC20(bullToken).totalSupply(), // index: 2
            IERC20(bearToken).totalSupply(), // index: 3
            IERC20(bullToken).balanceOf(_account), // index: 4
            IERC20(bearToken).balanceOf(_account) // index: 5
        );
    }

    function getTokenInfo(address _market, address _router, address _account) public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        address bullToken = IX2Market(_market).bullToken();
        address bearToken = IX2Market(_market).bearToken();

        uint256 bullAllowance = IERC20(bullToken).allowance(_account, _router);
        uint256 bearAllowance = IERC20(bearToken).allowance(_account, _router);

        return(
            IX2Market(_market).cachedDivisors(bullToken), // index: 0
            IX2Market(_market).cachedDivisors(bearToken), // index: 1
            IX2Market(_market).getDivisor(bullToken), // index: 2
            IX2Market(_market).getDivisor(bearToken), // index: 3
            bullAllowance, // index: 4
            bearAllowance // index: 5
        );
    }
}
