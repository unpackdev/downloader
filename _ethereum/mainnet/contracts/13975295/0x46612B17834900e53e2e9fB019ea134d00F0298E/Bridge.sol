pragma solidity ^0.8.0;

import "./IERC20.sol";

contract Bridge {
  address public owner;
  address private tokenAddress;
  uint private crossFee = 1; // in gwei

  mapping(address => mapping(uint => bool)) public sendNonces;
  mapping(address => mapping(uint => bool)) public recvNonces;

  enum Step { Send, Recv }
  event Transfer(
    address from,
    address to,
    uint amount,
    uint date,
    uint nonce,
    Step indexed step
  );

  modifier onlyOwner() {
    require (msg.sender == owner);
    _;
  }

  constructor(uint crossFee_, address tokenAddress_) {
    owner = msg.sender;
    crossFee = crossFee_;
    tokenAddress = tokenAddress_;
  }

  // transfer from msg.sender to contract
  function crossSend(
    address recipient,
    uint tokenAmount,
    uint nonce) external payable {
    // check fee
    require(msg.value >= crossFee, 'Insufficient fee.');
    require(sendNonces[msg.sender][nonce] == false, 'transfer already processed');

    sendNonces[msg.sender][nonce] = true;

    IERC20 token = IERC20(tokenAddress);
    token.transferFrom(msg.sender, owner, tokenAmount);

    emit Transfer(
      msg.sender,
      recipient,
      tokenAmount,
      block.timestamp,
      nonce,
      Step.Send
    );
  }

  // transfer from contract to recipient
  function crossRecv(
    address sender,
    address recipient, 
    uint tokenAmount,
    uint nonce) external onlyOwner {
    require(recvNonces[msg.sender][nonce] == false, 'transfer already processed');
    recvNonces[msg.sender][nonce] = true;

    IERC20 token = IERC20(tokenAddress);
    token.transferFrom(owner, recipient, tokenAmount);

    emit Transfer(
      sender,
      recipient,
      tokenAmount,
      block.timestamp,
      nonce,
      Step.Recv
    );
  }

  // withdraw from contract to owner
  function withdraw() external onlyOwner {
    // get the amount of Ether stored in this contract
    uint amount = address(this).balance;

    // send all Ether to owner
    // Owner can receive Ether since the address of owner is payable
    (bool success, ) = payable(owner).call{value: amount}("");
    require(success, "Failed to send balance");
  }

  // set fee
  function setFee(uint fee) external onlyOwner {
    crossFee = fee;
  }

  // get fee
  function getFee() external view returns (uint) {
    return crossFee;
  }

  // set owner
  function setOwner(address owner_) external onlyOwner {
    require(owner_ != address(0), 'Owner can not be null.');
    owner = owner_;
  }
}
