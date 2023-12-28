pragma solidity ^0.6.7;

interface ERC20 {
  function approve(address spender, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
}

interface OneInch {
  function swap(ERC20 fromToken, ERC20 toToken, uint256 amount, uint256 minReturn, uint256[] calldata distribution, uint256 disableFlags) external payable;
}

contract Arb {
  address constant ONE_INCH_CONTRACT = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;
  address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

  constructor() public {
    ERC20(DAI).approve(ONE_INCH_CONTRACT, 100000000000000000000000000000);
    ERC20(USDT).approve(ONE_INCH_CONTRACT, 100000000000000000000000000000);
  }

  function executeOperation(uint256 _amount, uint256[] memory _distribution) public {
    OneInch(ONE_INCH_CONTRACT).swap(ERC20(DAI), ERC20(USDT), _amount, 0, _distribution, 0);
    uint256 soldAmount = ERC20(USDT).balanceOf(address(this));
    OneInch(ONE_INCH_CONTRACT).swap(ERC20(USDT), ERC20(DAI), soldAmount, 0, _distribution, 0);
  }
}