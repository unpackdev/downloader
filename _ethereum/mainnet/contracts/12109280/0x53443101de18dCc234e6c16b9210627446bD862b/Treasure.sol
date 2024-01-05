// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ECDSA.sol";
import "./Ownable.sol";
import "./console.sol";
import "./KeyContract.sol";
import "./SafeMath.sol";
import "./ERC1155Holder.sol";

interface Gathering {
  function balanceOf(address, uint256) external view returns (uint256);
  function setApprovalForAll(address operator, bool approved) external;
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;
}

contract Treasure is Ownable, ERC1155Holder {

  using ECDSA for bytes32;
  using SafeMath for uint256;

  KeyContract public _keyContract;
  uint256 gatheringId = 50204871739540537889825295029850078924626996296174407025322338076332331630825;
  Gathering _gathering = Gathering(0x495f947276749Ce646f68AC8c248420045cb7b5e);

  mapping(address => uint256) public locked;
  address _key;

  bool public isUnlocked = false;

  // public getters / helpers
  function msgSigner(bytes32 hash, bytes memory signature) public pure returns (address) {
    return hash.recover(signature);
  }

  function gatheringBalance(address from) public view returns(uint256) {
    return _gathering.balanceOf(from, gatheringId);
  }

  function getMessage(address addr) public pure returns(bytes32) {
    bytes32 _msg = keccak256(abi.encodePacked(addr));
    return _msg;
  }

  // admin
  function setTokenContract(KeyContract _contractAddress) public onlyOwner {
    _keyContract = _contractAddress;
  }

  function setKey(address key) public onlyOwner {
    _key = key;
  }

  function setLock(bool flag) public onlyOwner {
    isUnlocked = !flag;
  }

  function proxyApproveAll(address newOwner, bool flag) public onlyOwner {
    _gathering.setApprovalForAll(newOwner, flag);
  }

  // player
  function lockTicket(address from) internal returns(bool) {
    _gathering.safeTransferFrom(from, address(this), gatheringId, 1, "0x0" );
    locked[from] = locked[from].add(1);
    return true;
  }

  function mint(bytes memory signature) public returns (uint256) {

    // create message
    bytes32 _msg = getMessage(msg.sender);

    // verify signature
    address recovered = msgSigner(_msg, signature);
    require(recovered == _key, "Bad password");

    // lock the ticket
    require(lockTicket(msg.sender), "Could not lock the ticket");

    // mint nft
    uint256 tokenId = _keyContract.mint(msg.sender);
    return tokenId;
  }

  function redeemTicket() public {
    address to = msg.sender;
    require(isUnlocked, "All tickets are locked");
    require(locked[to] > 0, "No ticket locked");
    locked[to] = locked[to].sub(1);
    _gathering.safeTransferFrom(address(this), to, gatheringId, 1, "0x0" );
  }

  /*
  function burn(uint256 tokenId) public onlyOwner {
    _keyContract.burn(tokenId);
  }
  */

}
