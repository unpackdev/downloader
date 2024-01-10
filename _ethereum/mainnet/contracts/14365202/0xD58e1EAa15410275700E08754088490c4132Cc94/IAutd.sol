// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;



import "./IERC20.sol";



interface IAutd is IERC20 {

  function mint(address _to, uint256 _amount) external;

  function burn(address _from, uint256 _amount) external;

  function index() external view returns (uint256);

  function balanceFrom(uint256 _amount) external view returns (uint256);

  function balanceTo(uint256 _amount) external view returns (uint256);

}
