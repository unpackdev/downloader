// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import "./draft-EIP712.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Voucher is EIP712, Ownable {
  struct VoucherInfo {
    uint256 price;
    string data;
    address wallet;
    address contractAddress;
    bytes signature;
  }

  string private constant SIGNING_DOMAIN = "Voucher";
  string private constant SIGNATURE_VERSION = "1";

  address public primarySalesReceiver;

  mapping(address => uint256) private callerNonce;

  using Counters for Counters.Counter;
  Counters.Counter private _voucherCounter;
  mapping(address => bool) private _allowedMinters;

  event VoucherSold(
    address wallet,
    address targetContractAddress_,
    string data
  );

  constructor(address signer, address payable primarySalesReceiver_)
    EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
  {
    _allowedMinters[signer] = true;
    primarySalesReceiver = primarySalesReceiver_;
    _voucherCounter.increment();
  }

  function addSigner(address signer_) public onlyOwner {
    _allowedMinters[signer_] = true;
  }

  function disableSigner(address signer_) public onlyOwner {
    _allowedMinters[signer_] = false;
  }

  function buy(VoucherInfo calldata voucher) external payable {
    require(msg.value == voucher.price, "Voucher: Invalid price amount");
    address signer = verifyVoucherInfo(voucher);
    require(
      _allowedMinters[signer] == true,
      "Voucher: Signature invalid or unauthorized"
    );
    require(_msgSender() == voucher.wallet, "Voucher: Invalid wallet");

    callerNonce[_msgSender()]++;

    (bool paymentSucess, ) = payable(primarySalesReceiver).call{
      value: msg.value
    }("");
    require(paymentSucess, "Voucher: Payment failed");
    emit VoucherSold(voucher.wallet, voucher.contractAddress, voucher.data);
  }

  function getCallerNonce(address msgSigner) external view returns (uint256) {
    return callerNonce[msgSigner];
  }

  function verifyVoucherInfo(VoucherInfo calldata voucher)
    internal
    view
    returns (address)
  {
    bytes32 digest = hashVoucherInfo(voucher);
    return ECDSA.recover(digest, voucher.signature);
  }

  function hashVoucherInfo(VoucherInfo calldata voucherInfo)
    internal
    view
    returns (bytes32)
  {
    bytes memory info = abi.encodePacked(
      voucherInfo.contractAddress,
      voucherInfo.price,
      voucherInfo.wallet,
      voucherInfo.data
    );

    bytes memory domainInfo = abi.encodePacked(
      this.getChainID(),
      SIGNING_DOMAIN,
      SIGNATURE_VERSION,
      address(this),
      callerNonce[_msgSender()]
    );

    return
      ECDSA.toEthSignedMessageHash(
        keccak256(abi.encodePacked(info, domainInfo))
      );
  }

  function getChainID() external view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }
}
