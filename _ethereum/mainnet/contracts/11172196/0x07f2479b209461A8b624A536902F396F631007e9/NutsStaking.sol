pragma solidity ^0.4.25;

/**
 * 
 * NUTS Staking (v0.1 beta)
 * 
 * For more info checkout: https://squirrel.finance
 * 
 */


contract NutsStaking {
    using SafeMath for uint256;
    
    ERC20 nuts = ERC20(0x84294FC9710e1252d407d3D80A84bC39001bd4A8);
    ERC20 bond = ERC20(0x0391D2021f89DC339F60Fff84546EA23E337750f);
    
    mapping(address => uint256) public balances;
    mapping(address => int256) payoutsTo;
    
    uint256 public totalDeposits;
    uint256 profitPerShare;
    uint256 constant internal magnitude = 2 ** 64;
    
    function receiveApproval(address player, uint256 amount, address, bytes) external {
        require(msg.sender == address(nuts));
        nuts.transferFrom(player, this, amount);
        totalDeposits += amount;
        balances[player] += amount;
        payoutsTo[player] += (int256) (profitPerShare * amount);
    }
    
    function cashout(uint256 amount) external {
        address recipient = msg.sender;
        claimYield();
        balances[recipient] = balances[recipient].sub(amount);
        totalDeposits = totalDeposits.sub(amount);
        payoutsTo[recipient] -= (int256) (profitPerShare * amount);
        nuts.transfer(recipient, amount);
    }
    
    function claimYield() public {
        address recipient = msg.sender;
        uint256 dividends = (uint256) ((int256)(profitPerShare * balances[recipient]) - payoutsTo[recipient]) / magnitude;
        payoutsTo[recipient] += (int256) (dividends * magnitude);
        bond.transfer(recipient, dividends);
    }
    
    function shareYield(uint256 amount) external {
        require(bond.transferFrom(msg.sender, this, amount));
        profitPerShare += (amount * magnitude) / totalDeposits;
    }
    
    function dividendsOf(address farmer) view public returns (uint256) {
        return (uint256) ((int256)(profitPerShare * balances[farmer]) - payoutsTo[farmer]) / magnitude;
    }
}







interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}