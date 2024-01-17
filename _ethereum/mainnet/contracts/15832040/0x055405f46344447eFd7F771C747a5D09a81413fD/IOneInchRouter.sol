pragma solidity ^0.7.6;

import "./IERC20.sol";

interface IOneInchRouter {
    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags
    ) external returns (uint256 returnAmount);
}
