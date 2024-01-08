// SPDX-License-Identifier: Unlicense
import "./IERC20.sol";

pragma solidity 0.7.6;

interface IHypervisor {

  function deposit(
        uint256,
        uint256,
        address
    ) external returns (uint256);

    function withdraw(
        uint256,
        address,
        address
    ) external returns (uint256, uint256);

    function token0() external view returns (IERC20);
    function token1() external view returns (IERC20);
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function getTotalAmounts() external view returns (uint256 total0, uint256 total1);
    function totalSupply() external view returns (uint256 );
}
