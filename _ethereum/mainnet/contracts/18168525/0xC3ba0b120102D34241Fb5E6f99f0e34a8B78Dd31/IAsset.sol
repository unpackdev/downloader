pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IAsset is IERC20 {
    function cash() external view returns (uint120);
    function liability() external view returns (uint120);
}