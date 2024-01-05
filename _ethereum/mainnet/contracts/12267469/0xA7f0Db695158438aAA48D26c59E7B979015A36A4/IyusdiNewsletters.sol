// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "./Console.sol";
import "./IyusdiNft.sol";

contract IyusdiNewsletters {

  address public nft;
  address public owner;

  uint256 public postFee;
  uint256 public newsletterFee;
  uint256 public subscriptionMinFee;
  uint256 public subscriptionPercent;
  mapping (uint256 => uint256) public subscriptionFees;
  
  uint256 constant SUBSCRIPTION_BASE = 10000;

  constructor (uint256 _newsletterFee, uint256 _subscriptionMinFee, uint256 _subscriptionPercent, uint256 _postFee) {
    owner = msg.sender;
    postFee = _postFee;
    newsletterFee = _newsletterFee;
    subscriptionMinFee = _subscriptionMinFee;
    subscriptionPercent = _subscriptionPercent;
  }

  function setNft(address _nft) external {
    require(msg.sender == owner && _nft != address(0), '!owner');
    nft = _nft;
  }

  function transferOwner(address _owner) external {
    require(msg.sender == owner && _owner != address(0), '!owner');
    owner = _owner;
  }

  function setFees(uint256 _newsletterFee, uint256 _subscriptionMinFee, uint256 _subscriptionPercent, uint256 _postFee) external {
    require(msg.sender == owner, '!owner');
    postFee = _postFee;
    newsletterFee = _newsletterFee;
    subscriptionMinFee = _subscriptionMinFee;
    subscriptionPercent = _subscriptionPercent;    
  }

  function _getCurator() internal view returns(address) {
    return IyusdiNft(nft).curator();
  }

  function _getNewsletterOwner(uint256 og) internal view returns(address) {
    return IyusdiNft(nft).originalOwner(og);
  }

  function createNewsletter(uint256 subscriptionFee, string memory ipfs) payable external returns(uint256 id) {
    require(msg.value == newsletterFee, '!fee');
    require(subscriptionFee >= subscriptionMinFee, '!subscriptionFee');
    (bool success, ) = _getCurator().call{value: msg.value}("");
    require(success, '!eth');
    id = IyusdiNft(nft).mintOriginal(msg.sender, msg.sender, 0, ipfs);
    subscriptionFees[id] = subscriptionFee;
  }

  function createSubscription(uint256 og, string memory ipfs) payable external returns(uint256 id) {
    id = _createSubscriptionFor(og, msg.sender, ipfs);
  }

  function createSubscriptionFor(uint256 og, address to, string memory ipfs) payable external returns(uint256 id) {
    require(to != address(0), '!for');
    id = _createSubscriptionFor(og, to, ipfs);
  }

  function _createSubscriptionFor(uint256 og, address to, string memory ipfs) internal returns(uint256 id) {
    address newsletterOwner = _getNewsletterOwner(og);
    require(newsletterOwner != address(0), '!og');
    uint256 subscriptionFee = subscriptionFees[og];
    require(msg.value == subscriptionFee, '!fee');
    uint256 curatorFee = subscriptionFee * subscriptionPercent / SUBSCRIPTION_BASE;
    if (curatorFee < subscriptionMinFee) 
      curatorFee = subscriptionMinFee;
    (bool success, ) = _getCurator().call{value: curatorFee}("");
    require(success, '!curator');
    if (subscriptionFee > curatorFee) {
      uint256 toOwner = subscriptionFee - curatorFee;
      (bool osuccess, ) = newsletterOwner.call{value: toOwner}("");
      require(osuccess, '!owner');
    }
    id = IyusdiNft(nft).mintPrint(og, to, ipfs);
  }

  function post(uint256 og, uint256 hash, string memory ipfs) payable external {
    require(msg.value == postFee, '!postFee');
    address newsletterOwner = _getNewsletterOwner(og);
    require(msg.sender == newsletterOwner, '!owner');
    if (postFee > 0) {
      (bool success, ) = _getCurator().call{value: postFee}("");
      require(success, '!sendFee');
    }
    IyusdiNft(nft).post(og, hash, ipfs);
  }

  function allowNewsletterTransfers(uint256 og, bool allow) external {
    address newsletterOwner = _getNewsletterOwner(og);
    require(msg.sender == newsletterOwner, '!owner');
    IyusdiNft(nft).allowTransfers(og, allow);
  }

}
