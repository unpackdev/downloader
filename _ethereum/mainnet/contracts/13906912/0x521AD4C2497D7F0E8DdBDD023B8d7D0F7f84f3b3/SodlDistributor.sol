pragma solidity ^0.8.4;

//SPDX-License-Identifier: Unlicense

import "./ECDSA.sol";
import "./SignatureChecker.sol";
import "./Ownable.sol";
import "./SODLDAO.sol";

contract SodlDistributor is Ownable {
  address public immutable token;
  mapping(string => uint256) public claimedMap;

  event Claimed(address account, uint256 amount, string txHash);

  constructor(address token_) {
    token = token_;
  }

  using ECDSA for bytes32;

  function claim(
    string memory txHash,
    uint256 amount,
    uint256 blockNumber,
    bytes memory signature
  ) public {
    require(amount > 0, "amount must be greater than 0");
    require(claimedMap[txHash] == 0, "Tx hash claimed already");
    require(block.number < blockNumber, "Invalid blockNumber");

    bytes32 message = keccak256(
      abi.encodePacked(txHash, amount, blockNumber, msg.sender)
    );

    address signer = message.toEthSignedMessageHash().recover(signature);
    require(signer == owner(), "Invalid signature");

    claimedMap[txHash] = amount;
    SODLDAO(token).mint(msg.sender, amount);

    emit Claimed(msg.sender, amount, txHash);
  }

  function isClaimed(string memory txHash) public view returns (bool) {
    return claimedMap[txHash] > 0;
  }

  function claimedAmount(string memory txHash) public view returns (uint256) {
    return claimedMap[txHash];
  }
}
