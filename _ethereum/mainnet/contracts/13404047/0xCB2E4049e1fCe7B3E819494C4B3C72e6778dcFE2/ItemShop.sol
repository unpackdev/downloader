// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ECDSAUpgradeable.sol";

contract ItemShop is Initializable, OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  mapping(uint256 => uint256) public paid;
  address public treasury;
  mapping(address => bool) public servers;

  string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";
  bytes32 private constant EIP712_DOMAIN_TYPEHASH=keccak256(abi.encodePacked(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
  ));
  bytes32 private constant PURCHASE_TYPEHASH=keccak256(abi.encodePacked(
    "Purchase(uint256 invoiceId,address paymentTokenAddress,uint256 amount,uint256 deadline)"
  ));
  bytes32 private SERVER_DOMAIN_SEPARATOR;

  event PayInvoice(
    uint256 indexed invoiceId,
    address indexed paymentTokenAddress,
    uint256 paymentTotal
  );

  function initialize() public initializer {
    __Ownable_init();
    SERVER_DOMAIN_SEPARATOR = keccak256(abi.encode(
      EIP712_DOMAIN_TYPEHASH,
      keccak256("BAG Shop"),
      keccak256("1"),
      block.chainid,
      address(this)
    ));
  }

  function _verify(
    bytes32 _values,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) internal view {
    bytes32 digest = keccak256(abi.encodePacked(
      EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
      SERVER_DOMAIN_SEPARATOR,
      _values
    ));
    address recoveredAddress = ECDSAUpgradeable.recover(digest, _v, _r, _s);
    require(servers[recoveredAddress], 'verify: invalid sig');
  }

  function payInvoice(
    uint256 _invoiceId,
    address _paymentTokenAddress,
    uint256 _paymentTotal,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) public {
    require(treasury != address(0), "payInvoice: invalid treasury");

    bytes32 values = keccak256(abi.encode(
      PURCHASE_TYPEHASH,
      _invoiceId, _paymentTokenAddress, _paymentTotal, _deadline
    ));
    _verify(values, _v, _r, _s);

    require(paid[_invoiceId] == 0, "payInvoice: already paid");
    require(_paymentTotal > 0, "payInvoice: invalid amount");
    require(block.timestamp < _deadline, "payInvoice: deadline passed");

    IERC20Upgradeable(_paymentTokenAddress).safeTransferFrom(msg.sender, treasury, _paymentTotal);
    paid[_invoiceId] = block.number;
    emit PayInvoice(_invoiceId, _paymentTokenAddress, _paymentTotal);
  }

  function setTreasury(address _treasury) public onlyOwner {
    require(_treasury != address(0), "setTreasury: invalid address");
    treasury = _treasury;
  }

  function addServerAddress(address _serverAddress) external onlyOwner {
    servers[_serverAddress] = true;
  }

  function removeServerAddress(address _serverAddress) external onlyOwner {
    servers[_serverAddress] = false;
  }

  uint256[50] private __gap;
}
