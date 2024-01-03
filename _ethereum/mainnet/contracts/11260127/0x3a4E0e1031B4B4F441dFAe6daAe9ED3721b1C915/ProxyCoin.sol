pragma solidity ^0.6.0;

interface IDSProxyFactory {
  function build() external returns (address payable);
}

interface IDSProxy {
  function setOwner(address) external;
}

contract ProxyCoin {
  //////////////////////////////////////////////////////////////////////////
  // Generic ERC20
  //////////////////////////////////////////////////////////////////////////

  // owner -> amount
  mapping(address => uint256) s_balances;
  address[] s_proxies;
  // owner -> spender -> max amount
  mapping(address => mapping(address => uint256)) s_allowances;

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  // Spec: Get the account balance of another account with address `owner`
  function balanceOf(address owner) public view returns (uint256 balance) {
    return s_balances[owner];
  }

  function internalTransfer(address from, address to, uint256 value) internal returns (bool success) {
    if (value <= s_balances[from]) {
      s_balances[from] -= value;
      s_balances[to] += value;
      emit Transfer(from, to, value);
      return true;
    } else {
      return false;
    }
  }

  // Spec: Send `value` amount of tokens to address `to`
  function transfer(address to, uint256 value) public returns (bool success) {
    address from = msg.sender;
    return internalTransfer(from, to, value);
  }

  // Spec: Send `value` amount of tokens from address `from` to address `to`
  function transferFrom(address from, address to, uint256 value) public returns (bool success) {
    address spender = msg.sender;
    if(value <= s_allowances[from][spender] && internalTransfer(from, to, value)) {
      s_allowances[from][spender] -= value;
      return true;
    } else {
      return false;
    }
  }

  // Spec: Allow `spender` to withdraw from your account, multiple times, up
  // to the `value` amount. If this function is called again it overwrites the
  // current allowance with `value`.
  function approve(address spender, uint256 value) public returns (bool success) {
    address owner = msg.sender;
    if (value != 0 && s_allowances[owner][spender] != 0) {
      return false;
    }
    s_allowances[owner][spender] = value;
    emit Approval(owner, spender, value);
    return true;
  }

  // Spec: Returns the `amount` which `spender` is still allowed to withdraw
  // from `owner`.
  // What if the allowance is higher than the balance of the `owner`?
  // Callers should be careful to use min(allowance, balanceOf) to make sure
  // that the allowance is actually present in the account!
  function allowance(address owner, address spender) public view returns (uint256 remaining) {
    return s_allowances[owner][spender];
  }

  //////////////////////////////////////////////////////////////////////////
  // GasToken specifics
  //////////////////////////////////////////////////////////////////////////

  uint8 constant public decimals = 0;
  string constant public name = "proxy.cash";
  string constant public symbol = "DS-Proxy";

  IDSProxyFactory public DSFactory;

  // We build a queue of nonces at which child contracts are stored. s_head is
  // the nonce at the head of the queue, s_tail is the nonce behind the tail
  // of the queue. The queue grows at the head and shrinks from the tail.
  // Note that when and only when a contract CREATEs another contract, the
  // creating contract's nonce is incremented.
  // The first child contract is created with nonce == 1, the second child
  // contract is created with nonce == 2, and so on...
  // For example, if there are child contracts at nonces [2,3,4],
  // then s_head == 4 and s_tail == 1. If there are no child contracts,
  // s_head == s_tail.
  uint256 supply;


  constructor(address _dsFactory) public {
    DSFactory = IDSProxyFactory(_dsFactory);
    supply = 0;
  }

  // totalSupply gives  the number of tokens currently in existence
  // Each token corresponds to one child contract that can be SELFDESTRUCTed
  // for a gas refund.
  function totalSupply() public view returns (uint256) {

    return supply;
  }

  // Creates a child contract that can only be destroyed by this contract.
  function makeChild() internal returns (address payable) {
    return DSFactory.build();
  }

  // Mints `value` new sub-tokens (e.g. cents, pennies, ...) by creating `value`
  // new child contracts. The minted tokens are owned by the caller of this
  // function.
  function mint(uint256 value) public {
    for (uint256 i = 0; i < value; i++) {
      address proxy = address(makeChild());
      s_proxies.push(proxy);
    }
    supply += value;
    s_balances[msg.sender] += value;
  }

  function claim() public returns (bool) {
    return _claim(msg.sender);
  }

  function claimFor(address newOwner) public returns (bool) {
    return _claim(newOwner);
  }

  function _claim(address newOwner) internal returns (bool success) {
    uint256 from_balance = s_balances[msg.sender];
    if (from_balance == 0) {
      return false;
    }


    uint lastPos = s_proxies.length - 1;
    address proxy = s_proxies[lastPos];
    s_proxies.pop();

    IDSProxy(proxy).setOwner(newOwner);

    s_balances[msg.sender] = from_balance - 1;

    supply -= 1;

    return true;
  }
}