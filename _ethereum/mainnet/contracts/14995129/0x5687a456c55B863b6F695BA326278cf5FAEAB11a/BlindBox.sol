// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Pausable.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./IDagenItems.sol";

contract BlindBox is Ownable, Pausable {
  using SafeMath for uint256;

  address payable public beneficiary;
  address public verifier;
  address public dagenItems;
  uint256 public releaseTime;

  uint256 public openBlindBoxPrice = 0.001 ether;

  event BlindBoxOpened(uint256 indexed index, uint256[] ids);

  mapping(uint256 => bool) public blindBoxesOpened;
  uint256 public maxPerWallet = 1;

  mapping(address => uint256) private _walletMints;
  mapping(bytes32 => bool) private _usedNonce;
  //gen id -> amount
  mapping(uint256 => uint256) private _genAmount;

  // blind boxes rule for id map amount
  mapping(uint256 => uint256) public preset;

  constructor(address _dagenItems) {
    dagenItems = _dagenItems;
    beneficiary = payable(msg.sender);
    verifier = payable(msg.sender);
  }

  function updateReleaseTime(uint256 _releaseTime) external onlyOwner {
    releaseTime = _releaseTime;
  }

  function updateMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
    maxPerWallet = _maxPerWallet;
  }

  function updateOpenBlindBoxPrice(uint256 _openBlindBoxPrice) external onlyOwner {
    openBlindBoxPrice = _openBlindBoxPrice;
  }

  function changeBeneficiary(address _beneficiary) external onlyOwner {
    beneficiary = payable(_beneficiary);
  }

  function changeVerifier(address _verifier) external onlyOwner {
    verifier = _verifier;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }
  
  /**
   * @notice Set up preset for limit blind box contract to mint dagen items
   * @param ids: token ids
   * @param amounts: amount for each token
   */
  function setupPreset(uint256[] calldata ids, uint256[] calldata amounts) external onlyOwner {
    for (uint256 i = 0; i < ids.length; i++) {
      preset[ids[i]] = amounts[i];
    }
  }

  /**
   * @notice Set up preset for limit blind box contract to mint dagen items
   * @param blindBoxIndex: blind box index
   * @param hashedMessage: hashed message for verifier which can be used only once
   * @param v: v in signature
   * @param r: r in signature
   * @param s: s in signature
   * @param ids: token ids
   * @param amounts: amount for each token
   */
  function openBlindBox(
    uint256 blindBoxIndex,
    bytes32 hashedMessage,
    uint8 v,
    bytes32 r,
    bytes32 s,
    uint256[] calldata ids,
    uint256[] calldata amounts
  ) external payable whenNotPaused {
    require(block.timestamp >= releaseTime, "not release");
    require(msg.sender == tx.origin, "No bots");
    require(msg.value == openBlindBoxPrice, "price incorrect");
    require(_walletMints[msg.sender] < maxPerWallet, "exceed max");
    require(blindBoxesOpened[blindBoxIndex] == false, "opened");

    require(_usedNonce[hashedMessage] == false, "used");
    address signer = ecrecover(hashedMessage, v, r, s);
    require(signer == verifier, "not verified");
    _usedNonce[hashedMessage] = true;

    uint256[] memory openedIds = new uint256[](ids.length);

    bool flag = false;
    for (uint256 i = 0; i < ids.length; i++) {
      if (IDagenItems(dagenItems).balanceOf(msg.sender, ids[i]) > 0) {
        continue;
      } else {
        flag = true;
        openedIds[i] = ids[i];
        require(amounts[i] == 1, "amount 1");
        require(preset[ids[i]] > 0, "no species");

        require(_genAmount[ids[i]] < preset[ids[i]], "exceed limit amount");
        _genAmount[ids[i]] += 1;
        IDagenItems(dagenItems).mint(msg.sender, ids[i], 1, new bytes(0));
      }
    }
    require(flag, "already had all");

    blindBoxesOpened[blindBoxIndex] = true;
    emit BlindBoxOpened(blindBoxIndex, openedIds);
    _walletMints[msg.sender] += 1;

    if (msg.value != 0) {
      payable(beneficiary).transfer(msg.value);
    }
  }
}
