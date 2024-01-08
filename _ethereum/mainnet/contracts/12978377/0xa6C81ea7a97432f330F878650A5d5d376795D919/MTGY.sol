// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeMath.sol";

contract MTGY is IERC20 {
  string public constant name = 'The moontography project';
  string public constant symbol = 'MTGY';
  uint8 public constant decimals = 18;

  address public constant burnWallet =
    0x000000000000000000000000000000000000dEaD;
  address public constant devWallet =
    0x3A3ffF4dcFCB7a36dADc40521e575380485FA5B8;
  address public constant rewardsWallet =
    0x87644cB97C1e2Cc676f278C88D0c4d56aC17e838;

  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowed;

  event Spend(address indexed owner, uint256 value);

  uint256 totalSupply_;

  using SafeMath for uint256;

  constructor(uint256 total) {
    totalSupply_ = total;
    balances[msg.sender] = totalSupply_;
  }

  function totalSupply() public view override returns (uint256) {
    return totalSupply_;
  }

  function balanceOf(address tokenOwner)
    public
    view
    override
    returns (uint256)
  {
    return balances[tokenOwner];
  }

  function transfer(address receiver, uint256 numTokens)
    public
    override
    returns (bool)
  {
    require(numTokens <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(numTokens);
    balances[receiver] = balances[receiver].add(numTokens);
    emit Transfer(msg.sender, receiver, numTokens);
    return true;
  }

  function approve(address delegate, uint256 numTokens)
    public
    override
    returns (bool)
  {
    allowed[msg.sender][delegate] = numTokens;
    emit Approval(msg.sender, delegate, numTokens);
    return true;
  }

  function allowance(address owner, address delegate)
    public
    view
    override
    returns (uint256)
  {
    return allowed[owner][delegate];
  }

  function transferFrom(
    address owner,
    address buyer,
    uint256 numTokens
  ) public override returns (bool) {
    require(numTokens <= balances[owner]);
    require(numTokens <= allowed[owner][msg.sender]);

    balances[owner] = balances[owner].sub(numTokens);
    allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
    balances[buyer] = balances[buyer].add(numTokens);
    emit Transfer(owner, buyer, numTokens);
    return true;
  }

  /**
   * spendOnProduct: used by a moontography product for a user to spend their tokens on usage of a product
   *   25% goes to dev wallet
   *   25% goes to rewards wallet for rewards
   *   50% burned
   */
  function spendOnProduct(uint256 amountTokens) public returns (bool) {
    require(amountTokens <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(amountTokens);
    uint256 half = amountTokens / 2;
    uint256 quarter = half / 2;
    // 50% burn
    balances[burnWallet] = balances[burnWallet].add(half);
    // 25% rewards wallet
    balances[rewardsWallet] = balances[rewardsWallet].add(quarter);
    // 25% dev wallet
    balances[devWallet] = balances[devWallet].add(
      amountTokens - half - quarter
    );
    emit Spend(msg.sender, amountTokens);
    return true;
  }
}
