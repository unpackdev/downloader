pragma solidity ^0.6.0;

interface IERC20 {
    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

contract bCREDRepayment {

  IERC20 public DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  IERC20 public BCRED = IERC20(0xB7412E57767EC30a76a4461d408d78b36688409C);
  address public BUILD_TREASURY = 0xDf9A17a73308416f555783239573913AFb77fA8a;

  function redeem(uint _amount) external {
    BCRED.transferFrom(msg.sender, address(BUILD_TREASURY), _amount);
    DAI.transfer(msg.sender, _amount);
  }
}