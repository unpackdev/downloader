// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Pausable.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

import "./IDagenItems.sol";

import "./console.sol";

contract BadgeBlindBox is Ownable, Pausable {
  using SafeMath for uint256;
  using ECDSA for bytes32;

  address payable public beneficiary;
  address public verifier;
  address public dagenItems;
  uint256 public releaseTime;

  uint256 public openBlindBoxPrice = 0.065 ether;

  event BlindBoxOpened(uint256 indexed index, uint256[] ids);

  mapping(uint256 => bool) public blindBoxesOpened;
  uint256 public maxPerWallet = 0;

  mapping(address => uint256) private _walletMints;
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
   * @param signature: hashed message for verifier which can be used only once
   * @param ids: token ids
   * @param amounts: amount for each token
   */
  function openBlindBox(
    uint256 blindBoxIndex,
    bytes memory signature,
    uint256[] calldata ids,
    uint256[] calldata amounts
  ) external payable whenNotPaused {
    require(block.timestamp >= releaseTime, "not release");
    require(msg.sender == tx.origin, "No bots");
    require(msg.value == openBlindBoxPrice, "price incorrect");
    require(maxPerWallet == 0 || _walletMints[msg.sender] < maxPerWallet, "exceed max");
    require(blindBoxesOpened[blindBoxIndex] == false, "opened");

    bytes32 messageHash = keccak256(
      abi.encodePacked(address(this), msg.sender, blindBoxIndex, ids, amounts)
    );
    address signer = messageHash.toEthSignedMessageHash().recover(signature);
    console.log(signer, verifier);
    require(signer == verifier, "not verified");

    for (uint256 i = 0; i < ids.length; i++) {
      _genAmount[ids[i]] += amounts[i];
      require(_genAmount[ids[i]] <= preset[ids[i]], "exceed limit amount");
      IDagenItems(dagenItems).mint(msg.sender, ids[i], amounts[i], new bytes(0));
    }

    blindBoxesOpened[blindBoxIndex] = true;
    emit BlindBoxOpened(blindBoxIndex, ids);
    _walletMints[msg.sender] += 1;

    if (msg.value != 0) {
      payable(beneficiary).transfer(msg.value);
    }
  }
}
