pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./SaleManager.sol";
import "./SafeERC20.sol";

contract ClaimManager {
  /** TOKENS CAN ONLY BE WITHDRAWN FROM THIS CLAIMS CONTRACT UNDER THESE CONDITIONS:
  - ERC-20 token
  - Sale closed
  - Claims contract registered
  - Claims opened (this transfers the token being claimed into the claims manager)
  - The message sender calling claim() participated in the sale and their claim was not voided

  Constructor Arguments
  _saleManager: the contract managing sales
  _saleId: the id for this sale within the sale manager (one claims contract per sale)
  _claimToken: the token that will be claimed by sale participants from this claims contract

  Note
  - This contract tracks claims in units of the claim token (unlike the sale manager, which tracks purchases in units of the spend token)
  */
  using SafeERC20 for IERC20;

  event Open(uint256 totalClaims);
  event Void(address indexed claimant, uint256 voidedClaim, bytes32 saleId);
  event Claim(address indexed claimant, uint256 amount, bytes32 saleId);
  event Close();

  // track the contract that ran the sale to get purchases
  SaleManager public immutable saleManager;
  // sales run by the SaleManager are indexed by saleId
  bytes32 public immutable saleId;
  // The ClaimsManager will allow claimants to claim this token
  IERC20 public immutable claimToken;
  // has the ClaimsManager been opened to allow claimants to claim tokens?
  bool public opened;
  // the quantity of tokens purchased in purchases that were voided, denominated in the token being claimed
  uint256 public voidClaims;
  // the quantity of claims remaining, denominated in the token being claimed
  uint256 public remainingClaims;
  // each user can claim tokens at most once
  mapping(address => bool) claimed;

  constructor(
    address _saleManager,
    bytes32 _saleId,
    address _claimToken
  ) {
    // Set up a new claim contract for a specific sale
    saleManager = SaleManager(_saleManager);
    saleId = _saleId;
    claimToken = IERC20(_claimToken);
  }

  modifier isSeller {
    require(
      saleManager.getSeller(saleId) == msg.sender,
      "can only be called by the seller"
    );
    _;
  }

  modifier saleOver {
    require(
      saleManager.isOver(saleId),
      "sale must be over first"
    );
    _;
  }

  modifier claimsOpened {
    require(
      opened,
      "claims must be opened first"
    );
    _;
  }

  function getRemainingClaim(address claimant) public view returns (uint256) {
    // How many tokens can this user claim in the future?
    if (claimed[claimant]) {
      return 0;
    }
    return saleManager.getBought(saleId, claimant);
  }

  function getTokenBalance() public claimsOpened view returns (uint256) {
    // How many tokens is this contract holding for future claimants?
    return claimToken.balanceOf(address(this));
  }

  function void(address claimant) public isSeller saleOver returns (uint256) {
    // If a user participated in the sale in error, prevent this user from receiving any tokens
    require(!opened, "claims already opened");
    uint256 voidClaim = getRemainingClaim(claimant);
    claimed[claimant] = true;
    voidClaims += voidClaim;
    emit Void(claimant, voidClaim, saleId);
    return voidClaim;
  }

  // allow claimants to begin claiming tokens
  function open() public isSeller saleOver {
    // checks that the claims contract was registered
    require(saleManager.getClaimManager(saleId) == address(this), "not registered as claims contract with sale manager");
    require(!opened, "claims already opened");

    uint256 _remainingClaims = saleManager.spentToBought(saleId, saleManager.getTotalSpent(saleId)) - voidClaims;

    require(claimToken.allowance(msg.sender, address(this)) >= _remainingClaims, "claims contract allowance too low");

    // effects
    remainingClaims = _remainingClaims;
    opened = true;
    emit Open(remainingClaims);

    // interactions
    claimToken.safeTransferFrom(msg.sender, address(this), remainingClaims);
  }

  function claim() public saleOver claimsOpened returns (uint256) {
    // checks
    uint256 quantity = getRemainingClaim(msg.sender);
    require(quantity > 0, "this address cannot claim any tokens");

    // effects
    claimed[msg.sender] = true;
    emit Claim(msg.sender, quantity, saleId);
    remainingClaims -= quantity;
    if (remainingClaims == 0) {
      emit Close();
    }

    // interactions
    claimToken.safeTransfer(msg.sender, quantity);
    return quantity;
  }

  // The seller can rescue ERC-20 tokens accidentally sent here
  function recoverERC20(address tokenAddress, uint256 tokenAmount) public {
    require(tokenAddress != address(claimToken), "Only for recovering tokens accidentally sent here");
    IERC20(tokenAddress).transfer(saleManager.getSeller(saleId), tokenAmount);
  }
}