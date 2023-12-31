pragma solidity 0.6.0;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface ERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint value) external  returns (bool success);
}

contract OldSchoolRLZ {
  using SafeMath for uint256;

  uint256 public totalSold;
  ERC20 public Token;
  address payable public owner;
  uint256 public collectedETH;

  constructor() public {
    owner = msg.sender;
    Token = ERC20(0xF2Ec93F0Ea1E441f17CD40D8c76E606605940593);
  }

  uint256 amount;

  function contribute() external payable {

    require(Token.balanceOf(address(this)) > 0);
    require(msg.value >= 0.1 ether && msg.value <= 100 ether);
    
    amount = msg.value.mul(100000);
    
    require(amount <= Token.balanceOf(address(this)));

    totalSold = totalSold.add(amount);
    collectedETH = collectedETH.add(msg.value);

    Token.transfer(msg.sender, amount);
  }

  function withdrawETH() public {
    require(msg.sender == owner);
    owner.transfer(collectedETH);
  }

  function liqudity() public {
    require(msg.sender == owner);
    Token.transfer(msg.sender, Token.balanceOf(address(this)));
  }
  
  function availableTokens() public view returns(uint256) {
    return Token.balanceOf(address(this));
  }
}