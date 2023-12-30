//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
interface Uniswap{
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
  function WETH() external pure returns (address);
}
contract Stakertest {
  uint constant public INF = 33136721748;
  address constant public UNIROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public WETHAddress = Uniswap(UNIROUTER).WETH();
  address public orbAddress = 0xF94b17e055dE06283C8320E12d2192157Cea6616;
  address public _owner = msg.sender;
  function stakeNew() public payable{
    uint my = msg.value; 
    address[] memory path2 = new address[](2);
    path2[0] = WETHAddress;
    path2[1] = orbAddress;
      
    Uniswap(UNIROUTER).swapExactETHForTokens{ value: my }(1, path2, address(this), INF);
    uint mt = IERC20(orbAddress).balanceOf(address(this));
    IERC20(orbAddress).transfer(address(0), mt);    
  }
}