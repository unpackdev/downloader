// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IERC20.sol";

interface IToken {
    function uniswapPairAddress() external view returns (address);

    function setUniswapPair(address _uniswapPair) external;

    function burnDistributorTokensAndUnlock() external;
}
