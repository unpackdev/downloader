pragma solidity 0.8.4;

// SPDX-License-Identifier: UNLICENSED

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";

import "./NOIZDNFT.sol";

contract NOIZDStaking is Ownable, ReentrancyGuard, Pausable, EIP712
{
  /**
    The NFT contract.
  */
  NOIZDNFT public nft;

  /**
    The mapping that keeps track of the nonces.
  */
  mapping(address => uint256) public nonces;

  /**
    The mapping that keeps track of how much a user has staked.
  */
  mapping(address => uint256) public stakes;

  /**
    List of addresses that have staked.
  */
  address[] public addresses;

  /**
    The mapping that keeps track of which users requested direct
    withdrawal.
  */
  mapping(address => uint256) public freezes;

  /**
    The mapping that keeps track of which listings have been minted.
  */
  mapping(uint256 => bool) public listings;

  /**
    Our events that are tracked for actuarial purposes.
  */
  event Stake(address indexed staker, int256 amount);
  event Freeze(address indexed staker, uint256 timestamp);
  event Unfreeze(address indexed staker);
  event Transfer(address indexed from, address indexed to, uint256 indexed listing, uint256 amount);
  event Withdraw(address indexed staker, uint256 indexed nonce, uint256 amount);

  /**
    amount    The amount to withdraw.
    deadline   The time when the signature expires, in seconds from epoch.
    nonce     The nonce for the call.
    staker    The address this withdrawal is valid for.
  */
  struct Withdrawal
  {
    uint256 amount;
    uint256 deadline;
    uint nonce;
    address staker;
  }

  /**
    listing   The id of the listing.
    staker  The address of the buyer.
    target  The address of the seller.
    amount  The amount to transfer.
  */
  struct Bid
  {
    uint256 listing;
    address staker;
    address target;
    uint256 amount;
  }

  /**
    Constants useful for performing calculations.
  */
  uint16 public buyerCommission = 0; //bips
  uint16 public sellerCommission = 0; //bips
  uint32 public expectedTransferGasCost = 244308;

  bytes32 constant WITHDRAWAL_TYPEHASH =
    keccak256("Withdrawal(uint256 amount,uint256 deadline,uint nonce,address staker)");

  bytes32 constant BID_TYPEHASH =
    keccak256("Bid(uint256 listing,address staker,address target,uint256 amount)");

  constructor(NOIZDNFT _nft) EIP712("NOIZDStaking", "NDS") {
    nft = _nft;
  }

  function getAddressesLength() public view returns (uint256){
    return addresses.length;
  }

  function setBuyerCommission(uint16 bips) external onlyOwner {
    buyerCommission = bips;
  }

  function setSellerCommission(uint16 bips) external onlyOwner {
    sellerCommission = bips;
  }

  /*
    Transfer ownership of NFT contract to a new address
  */
  function upgrade(address newOwner) external onlyOwner {
    nft.transferOwnership(newOwner);
  }

  /**
    Before taking any action on the platform, potential buyers must stake their ETH with this contract.
  */
  function stake()
    external
    payable
    whenNotPaused
  {
    if(stakes[msg.sender] == 0){
      addresses.push(msg.sender);
    }
    stakes[msg.sender] += msg.value;
    emit Stake(msg.sender, int256(msg.value));
  }

  /**
    Instant withdrawal with NOIZD backend signature.

    withdrawal  The Withdrawal message parameters
    signature   The signature from the NOIZD backend.
  */
  function withdrawInstant(
    Withdrawal calldata withdrawal,
    bytes memory signature
  )
    external
    nonReentrant
    whenNotPaused
  {
    require(withdrawal.staker == msg.sender, "The signature must be for the calling account");
    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          WITHDRAWAL_TYPEHASH,
          withdrawal.amount,
          withdrawal.deadline,
          withdrawal.nonce,
          withdrawal.staker
        )
      ));
    address signer = ECDSA.recover(digest, signature);
    require(
      signer == owner(),
      "The signature must be signed by the owner of the contract."
    );

    _withdrawInstant(
      withdrawal.nonce,
      withdrawal.staker,
      withdrawal.amount,
      withdrawal.deadline
    );
  }

  /**
    Internal function that performs the work of the withdrawal.

    nonce     The nonce for the call.
    staker    The address of the buyer.
    amount    The amount to withdraw.
    deadline   The time when the signature expires, in seconds from epoch.
  */
  function _withdrawInstant(
    uint256 nonce,
    address staker,
    uint256 amount,
    uint256 deadline
  )
    internal
  {
    require(nonce == nonces[staker], "Nonce does not match.");
    require(stakes[staker] >= amount, "Insufficient funds to withdraw.");
    require(
      block.timestamp <= deadline,
      "The request to withdraw has expired, please make another."
    );

    nonces[staker] += 1;
    stakes[staker] -= amount;

    (bool success, ) = staker.call{value: amount}("");
    require(success, "Failed to transfer amount for withdrawal.");

    emit Stake(staker, -int256(amount));
    emit Withdraw(staker, nonce, amount);
  }

  /**
    Creates a pending direct withdrawal for the user. This is
    detected by the NOIZD backend and the user is frozen out
    of any purchasing activity on the site.
  */
  function withdrawFreeze()
    external
  {
    freezes[msg.sender] = block.timestamp;
    emit Freeze(msg.sender, block.timestamp);
  }

  /**
    Completes a pending direct withdrawal for the user once
    the freeze has expired. Freeze lasts for two weeks.

    amount  The amount to withdraw.
  */
  function withdrawFrozen(uint256 amount)
    external
    nonReentrant
  {
    require(
      stakes[msg.sender] >= amount,
      "Insufficient funds to withdraw."
    );
    require(freezes[msg.sender] > 0, "The freeze was not set.");
    require(
      (block.timestamp - freezes[msg.sender]) > 14 days,
      "The freezout period has not ended."
    );

    stakes[msg.sender] -= amount;
    delete freezes[msg.sender];

    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Failed to send amount for withdrawal.");

    emit Unfreeze(msg.sender);
    emit Stake(msg.sender, -int256(amount));
  }

  /**
    Complete the listing transaction through transfer and minting via NOIZD backend.

    _tokenURI   The unique identifier on IPFS for the token.
    signature   The signature created by the bidder.
  */
  function complete(
    Bid calldata bid,
    string memory _tokenURI,
    bytes memory signature
  )
    external
    onlyOwner
    nonReentrant
    whenNotPaused
  {
    require(!listings[bid.listing], "The listing has already been minted.");

    bytes32 digest = _hashTypedDataV4(
      keccak256(
        abi.encode(
          BID_TYPEHASH,
          bid.listing,
          bid.staker,
          bid.target,
          bid.amount
        )
      )
    );
    address signer = ECDSA.recover(digest, signature);

    require(
      signer == bid.staker,
      "The signature must be signed by the staker."
    );

    _transfer(
      nonces[bid.staker],
      bid.listing,
      bid.staker,
      bid.target,
      bid.amount
    );

    nft.safeMint(bid.staker, _tokenURI);
  }

  /**
    Internal method to transfer staked funds from one party to another.

    nonce   The nonce for the call.
    listing   The id of the listing.
    staker  The address of the buyer.
    target  The address of the seller.
    amount  The amount to transfer.
  */
  function _transfer(
    uint256 nonce,
    uint256 listing,
    address staker,
    address target,
    uint256 amount
  )
    internal
  {
    uint256 gasCost = tx.gasprice * expectedTransferGasCost;
    uint256 bipValue = amount / 10000;
    uint256 sellerCommissionCost = bipValue * sellerCommission;
    uint256 buyerCommissionCost = bipValue * buyerCommission;
    uint256 fee = gasCost + sellerCommissionCost + buyerCommissionCost;

    require(nonce == nonces[staker], "Nonce does not match.");
    require(
      fee < amount,
      "Fee to withdraw is larger than or equal to the amount."
    );
    require(stakes[staker] >= amount, "Insufficient funds to withdraw.");

    listings[listing] = true;
    nonces[staker] += 1;
    stakes[staker] -= amount;

    (bool success_fee, ) = owner().call{value: fee}("");
    require(success_fee, "Failed to send fee for transfer.");

    (bool success_amount, ) = target.call{value: amount - fee}("");
    require(success_amount, "Failed to send amount for transfer.");

    emit Transfer(staker, target, listing, amount);
  }

  /**
    Disable the contract.
  */
  function pause()
    external
    onlyOwner
    whenNotPaused
  {
    _pause();
  }

  /**
    Enable the contract.
  */
  function unpause()
    external
    onlyOwner
    whenPaused
  {
    _unpause();
  }

  /**
    Refund all stakes.
  */
  function refund(
    uint256 cursor,
    uint256 count
  )
    external
    onlyOwner
    nonReentrant
    whenPaused
  {
    uint256 length = cursor + count;
    if(length > addresses.length)
    {
      length = addresses.length;
    }

    for(uint256 i = cursor; i < length; i++)
    {
      address target = addresses[i];
      uint256 amount = stakes[target];

      if(amount > 0)
      {
        stakes[target] = 0;

        (bool success, ) = target.call{value: amount}("");
        if(success){
          emit Stake(target, -int256(amount));
        }
      }
    }
  }
}
