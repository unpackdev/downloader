// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/*
                              ..............               ascii art by community member
                        ..::....          ....::..                           rqueue#4071
                    ..::..                        ::..
                  ::..                              ..--..
          ███████████████████████████████::..............::::..
          ██  ███  █  █        █  ███  ██                    ..::..
          ██  ██  ██  ████  ████  ███  ██                        ::::
          ██     ███  ████  ████       ██                          ..::
          ██  ██  ██  ████  ████  ███  ██                            ....
        ..██  ███  █  ████  ████  ███  ██                              ::
        ::███████████████████████████████                                ::
        ....    ::                                ....::::::::::..        ::
        --::......                    ..::==--::::....          ..::..    ....
      ::::  ..                  ..--..  ==@@++                      ::      ..
      ::                    ..------      ++..                        ..    ..
    ::                  ..::--------::  ::..    ::------..            ::::==++--..
  ....                ::----------------    ..**%%##****##==        --######++**##==
  ..              ::----------------..    ..####++..    --**++    ::####++::    --##==
....          ..----------------..        **##**          --##--::**##++..        --##::
..        ..--------------++==----------**####--          ..**++..::##++----::::::::****
..    ::==------------++##############%%######..            ++**    **++++++------==**##
::  ::------------++**::..............::**####..            ++**..::##..          ..++##
::....::--------++##..                  ::####::          ::****++####..          ..**++
..::  ::--==--==%%--                      **##++        ..--##++::####==          --##--
  ::..::----  ::==                        --####--..    ::**##..  ==%%##::      ::****
  ::      ::                                **####++--==####::      **%%##==--==####::
    ::    ..::..                    ....::::..--########++..          ==**######++..
      ::      ..::::::::::::::::::....      ..::::....                    ....
        ::::..                      ....::....
            ..::::::::::::::::::::....

*/

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

interface IKithFriends {
  function mint(uint256 id, uint256 amount, address destination) external;
}

contract KithFriendsMinter is Ownable {
  using Strings for uint256;

  uint256 public constant KithFriend_1 = 10;
  uint256 public constant KithFriend_2 = 11;
  uint256 public constant KithFriend_3 = 12;

  uint256 public price;

  bool public saleActive = false;

  bytes32 public merkleRoot;
  mapping(address => uint256) private _alreadyMinted;

  IKithFriends public collection;

  constructor(address collectionAddress, uint256 initialPrice) {
    collection = IKithFriends(collectionAddress);
    price = initialPrice;
  }

  function setSaleActive(bool active) public onlyOwner {
    saleActive = active;
  }

  function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
    merkleRoot = merkleRoot_;
  }

  function alreadyMinted(address account) public view returns (uint256) {
    return _alreadyMinted[account];
  }

  function mintEditions(
    uint256[] calldata tokenIDs,
    uint256[] calldata amounts,
    bytes32[] calldata merkleProof,
    uint256 maxAmount
  ) public payable {
    require(saleActive, "Sale is closed");
    require(tokenIDs.length == amounts.length, "Unequal count of tokens/amounts");

    uint256 totalAmount = sum(amounts);
    require(msg.value == price * totalAmount, "Incorrect payable amount");

    address sender = _msgSender();

    require(totalAmount <= maxAmount - _alreadyMinted[sender], "Insufficient mints left");
    require(_verify(merkleProof, sender, maxAmount), "Invalid proof");

    uint256 tokenID;
    uint256 tokenAmount;
    for (uint256 i = 0; i < tokenIDs.length; i++) {
      tokenID = tokenIDs[i];
      tokenAmount = amounts[i];

      require(knownTokenID(tokenID), "Unknown token");

      _alreadyMinted[sender] += tokenAmount;
      collection.mint(tokenID, tokenAmount, sender);
    }
  }

  function withdraw(address payable recipient) public virtual onlyOwner {
    payable(recipient).transfer(address(this).balance);
  }

  // Private

  function knownTokenID(uint256 tokenID) private pure returns (bool) {
    return tokenID == KithFriend_1 || tokenID == KithFriend_2 || tokenID == KithFriend_3;
  }

  function sum(uint256[] calldata amounts) private pure returns (uint256 result) {
    for (uint256 i = 0; i < amounts.length; i++) {
      result += amounts[i];
    }

    return result;
  }

  function _verify(
    bytes32[] calldata merkleProof,
    address sender,
    uint256 maxAmount
  ) private view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(sender, maxAmount.toString()));
    return MerkleProof.verify(merkleProof, merkleRoot, leaf);
  }
}
