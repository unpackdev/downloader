// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ECDSA.sol";

contract Airdrop {

  /**
   * The owner who can issue airdrops
   */
  address public owner;
  /**
   * The nonce for each user
   */
  mapping(address => uint256) public nonces;
  /**
   * The token to airdrop
   */
  IERC20 public token;

  constructor(
    address _owner,
    address _token
  ) {
    owner = _owner;
    token = IERC20(_token);
  }

  function claim(
    uint256 _amount,
    uint256 _nonce,
    bytes memory _signature
  ) public {
    require(
      ECDSA.recover(
        ECDSA.toEthSignedMessageHash(abi.encodePacked(msg.sender, _amount, _nonce)),
        _signature
      ) == owner,
      "Invalid signature"
    );
    require(_nonce == nonces[msg.sender], "Invalid nonce");
    nonces[msg.sender] = _nonce + 1;
    token.transfer(msg.sender, _amount);
  }

  function claimBehalf(
    address _to,
    uint256 _amount,
    uint256 _nonce,
    bytes memory _signature
  ) public {
    require(
      ECDSA.recover(
        ECDSA.toEthSignedMessageHash(abi.encodePacked(_to, _amount, _nonce)),
        _signature
      ) == owner,
      "Invalid signature"
    );
    require(_nonce == nonces[_to], "Invalid nonce");
    nonces[_to] = _nonce + 1;
    token.transferFrom(address(this), _to, _amount);
  }
}