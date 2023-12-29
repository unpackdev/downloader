pragma solidity ^0.8.23;

import "./IERC20.sol";

interface ISunra {
    function token1() external view returns (IERC20);

    function token2() external view returns (IERC20);

    function createNewLands() external;
}
