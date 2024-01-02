// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20.sol";

contract TokenPreSale is
  Initializable,
  OwnableUpgradeable,
  PausableUpgradeable,
  UUPSUpgradeable
{
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
      _disableInitializers();
  }

  function initialize(
    address initialOwner,
    address _tokenAddress,
    address _tokenSpender,
    address _recipient,
    uint256 _nativeTokenPrice
  ) initializer public {
    __Ownable_init(initialOwner);
    __Pausable_init();
    __UUPSUpgradeable_init();

    tokenAddress = _tokenAddress;
    tokenSpender = _tokenSpender;
    recipient = _recipient;
    nativeTokenPrice = _nativeTokenPrice;
  }

  function _authorizeUpgrade(address newImplementation)
      internal
      onlyOwner
      override
  {}

  // * Version
  function version() virtual public pure returns (string memory) {
      return "1";
  }

  // * States
  address public tokenAddress;
  address public tokenSpender;
  address public recipient;
  uint256 public nativeTokenPrice;
  mapping(address => uint256) private specificTokenPrices;

  // * Events
  event BuyToken(address indexed buyer, uint256 amount);
  event BuyTokenBySpecificToken(address indexed buyer, uint256 amount, address indexed specificToken);
  event ChangeTokenAddress(address indexed newTokenAddress);
  event ChangeTokenSpender(address indexed newTokenSpender);
  event ChangeRecipient(address indexed newRecipient);
  event ChangeNativeTokenPrice(uint256 newNativeTokenPrice);
  event ChangeSpecificTokenPrice(address specificToken, uint256 newSpecificTokenPrice);

  // * 계약 일시 정지
  function pause() public onlyOwner() {
    _pause();
  }

  // * 계약 일시 정지 해제
  function unpause() public onlyOwner() {
    _unpause();
  }

  // * tokenAddress 변경
  function changeTokenAddress(address newTokenAddress) virtual public onlyOwner() {
    tokenSpender = newTokenAddress;
    emit ChangeTokenAddress(newTokenAddress);
  }

  // * tokenSpender 변경
  function changeTokenOwner(address newTokenSpender) virtual public onlyOwner() {
    tokenSpender = newTokenSpender;
    emit ChangeTokenSpender(newTokenSpender);
  }

  // * recipient 변경
  function changeRecipient(address newRecipient) virtual public onlyOwner() {
    recipient = newRecipient;
    emit ChangeRecipient(newRecipient);
  }

  // * nativeTokenPrice 변경
  function changeNativeTokenPrice(uint256 newNativeTokenPrice) virtual public onlyOwner() {
    require(newNativeTokenPrice > 0, "price must more than zero.");
    nativeTokenPrice = newNativeTokenPrice;
    emit ChangeNativeTokenPrice(newNativeTokenPrice);
  }

  // * specificTokenPrice 변경
  function changeSpecificTokenPrice(address specificToken, uint256 newSpecificTokenPrice) virtual public onlyOwner() {
    require(newSpecificTokenPrice > 0, "price must more than zero.");
    specificTokenPrices[specificToken] = newSpecificTokenPrice;
    emit ChangeSpecificTokenPrice(specificToken, newSpecificTokenPrice);
  }

  // * pricePerSpecificToken 조회
  function specificTokenPrice(address specificToken) virtual public view returns (uint256) {
    return specificTokenPrices[specificToken];
  }

  // * 네이티브 토큰 총 지불 금액 계산
  function calcTotalPrice(uint256 amount) virtual public view returns (uint256) {
    if (amount <= 0) {
      return 0;
    }
  
    return (amount * nativeTokenPrice) / 1 ether;
  }

  // * 특정 토큰 총 지불 금액 계산
  function calcTotalPriceBySpecificToken(uint256 amount, address specificToken) virtual public view returns (uint256) {
    if (amount <= 0) {
      return 0;
    }

    uint256 price = specificTokenPrice(specificToken);
    return (amount * price) / 1 ether;
  }

  // * 네이티브 토큰으로 프리세일 토큰 구매
  function buyToken(uint256 amount) virtual public payable whenNotPaused {
    require(amount > 0, "can not buy zero tokens.");

    uint256 targetTotalPrice = (amount * nativeTokenPrice) / 1 ether;
    require(msg.value == targetTotalPrice, "msg.value must exactly be the total price.");
  
    payable(recipient).transfer(targetTotalPrice);
    _validateERC20BalAndAllowance(tokenSpender, tokenAddress, amount);
    _transferToken(tokenAddress, tokenSpender, _msgSender(), amount);
    emit BuyToken(_msgSender(), amount);
  }

  // * 특정 ERC-20 토큰으로 프리세일 토큰 구매
  function buyTokenBySpecificToken(uint256 amount, address specificToken) virtual public whenNotPaused {
    require(amount > 0, "can not buy zero tokens.");

    uint256 price = specificTokenPrice(specificToken);
    require(price > 0, "not registered specific token.");
    
    uint256 targetTotalPrice = (amount * price) / 1 ether;
    _validateERC20BalAndAllowance(_msgSender(), specificToken, targetTotalPrice);
    _transferToken(specificToken, _msgSender(), recipient, targetTotalPrice);

    _validateERC20BalAndAllowance(tokenSpender, tokenAddress, amount);
    _transferToken(tokenAddress, tokenSpender, _msgSender(), amount);
    emit BuyTokenBySpecificToken(_msgSender(), amount, specificToken);
  }

  // * 토큰 allowance와 잔액 검증
  function _validateERC20BalAndAllowance(address _spender, address currency, uint256 amount) virtual internal view {
    require(
      IERC20(currency).balanceOf(_spender) >= amount &&
        IERC20(currency).allowance(_spender, address(this)) >= amount,
      "!BAL20"
    );
  }

  // * 토큰 인출(transferFrom)
  function _transferToken(address _tokenAddress, address from, address to, uint256 amount) virtual internal {
    require(IERC20(_tokenAddress).transferFrom(from, to, amount), "transfer failed");
  }
}
