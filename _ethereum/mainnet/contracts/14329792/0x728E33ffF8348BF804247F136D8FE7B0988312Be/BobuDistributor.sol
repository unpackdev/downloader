// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./ECDSA.sol";

error Phase1SaleNotStarted();
error Phase2SaleNotStarted();
error MaxPhase1ClaimsReached();
error MaxPhase2ClaimsReached();
error InsufficientAmount();
error CallerIsContract();
error TransferFailed();
error InvalidSignature();

contract BobuDistributor is Ownable, ReentrancyGuard, ERC1155Holder {
  using ECDSA for bytes32;

  mapping(address => uint256) public numFractionsClaimed;

  IERC1155 private immutable fractional1155;

  uint256 private immutable fractionIdIn1155;
  struct SaleDetails {
    uint128 phase1SaleTime;
    uint128 phase2SaleTime;
  }
  SaleDetails public saleDetails;

  uint256 constant PRICE_FOR_ONE = 0.01 ether;
  address private signer;

  constructor(address fractional1155Address_, uint256 fractionIdIn1155_) {
    fractional1155 = IERC1155(fractional1155Address_);
    fractionIdIn1155 = fractionIdIn1155_;
  }

  function claimPhase1(bytes calldata _signature)
    external
    payable
    callerIsUser
  {
    SaleDetails memory saleDetailsLoc = saleDetails;
    if (
      saleDetailsLoc.phase1SaleTime == 0 ||
      block.timestamp < saleDetailsLoc.phase1SaleTime
    ) {
      revert Phase1SaleNotStarted();
    }
    if (numFractionsClaimed[msg.sender] != 0) {
      revert MaxPhase1ClaimsReached();
    }
    if (msg.value < PRICE_FOR_ONE) revert InsufficientAmount();
    if (!_verify(_signature)) revert InvalidSignature();

    // It is impossible to overflow here because we restrict the number of claims
    // per wallet to be 101.
    unchecked {
      numFractionsClaimed[msg.sender]++;
    }

    fractional1155.safeTransferFrom(
      address(this),
      msg.sender,
      fractionIdIn1155,
      1,
      '0'
    );
  }

  function claimPhase2(uint32 amount, bytes calldata _signature)
    external
    payable
    callerIsUser
  {
    SaleDetails memory saleDetailsLoc = saleDetails;
    if (
      saleDetailsLoc.phase2SaleTime == 0 ||
      block.timestamp < saleDetailsLoc.phase2SaleTime
    ) {
      revert Phase2SaleNotStarted();
    }
    if (numFractionsClaimed[msg.sender] + amount > 101) {
      revert MaxPhase2ClaimsReached();
    }
    if (msg.value < (PRICE_FOR_ONE * amount)) revert InsufficientAmount();

    if (!_verify(_signature)) revert InvalidSignature();

    // It is impossible to overflow here because we restrict the number of claims
    // per wallet to be 101.
    unchecked {
      numFractionsClaimed[msg.sender] += amount;
    }

    fractional1155.safeTransferFrom(
      address(this),
      msg.sender,
      fractionIdIn1155,
      amount,
      '0'
    );
  }

  function setSaleDetails(uint128 phase1SaleTime_, uint128 phase2SaleTime_)
    external
    onlyOwner
  {
    saleDetails = SaleDetails(phase1SaleTime_, phase2SaleTime_);
  }

  modifier callerIsUser() {
    if (tx.origin != msg.sender) revert CallerIsContract();
    _;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}('');
    if (!success) revert TransferFailed();
  }

  function withdrawRemainingBobus() external onlyOwner nonReentrant {
    fractional1155.safeTransferFrom(
      address(this),
      msg.sender,
      fractionIdIn1155,
      fractional1155.balanceOf(address(this), fractionIdIn1155),
      '0'
    );
  }

  function _verify(bytes memory _signature) private view returns (bool) {
    bytes32 hashVal = keccak256(abi.encodePacked(msg.sender));
    bytes32 signedHash = hashVal.toEthSignedMessageHash();
    address signingAddress = signedHash.recover(_signature);
    return signingAddress == signer;
  }

  function setSigner(address _signer) external onlyOwner {
    signer = _signer;
  }
}
