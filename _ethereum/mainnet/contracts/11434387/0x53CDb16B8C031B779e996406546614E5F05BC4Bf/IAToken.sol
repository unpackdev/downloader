pragma solidity 0.6.12;

import "./IERC20.sol";

interface IAToken is IERC20 {
    function redeem(uint256 _amount) external;
    function underlyingAssetAddress() external returns (address);
}