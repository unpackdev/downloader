// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITradingTokenManagerV1.sol";
import "./Address.sol";
import "./Governable.sol";
import "./Pausable.sol";
import "./IDCounter.sol";
import "./FeeCollector.sol";
import "./ITradingTokenV1.sol";
import "./ITradingTokenFactoryV1.sol";

contract TradingTokenManagerV1 is ITradingTokenManagerV1, Governable, Pausable, IDCounter, FeeCollector {
  using Address for address payable;

  /** @dev set the deployer as both owner and governor initially */
  constructor(address factoryAddress, address feesAddress) Governable(_msgSender(), _msgSender()) {
    _factory = ITradingTokenFactoryV1(factoryAddress);
    _setFeesContract(feesAddress);
  }

  ITradingTokenFactoryV1 internal _factory;

  mapping(uint40 => ITradingTokenV1) private _tokens;
  mapping(address => uint40) private _tokenAddressMap;
  
  function factory() external view override returns (address) {
    return address(_factory);
  }

  function setFactory(address value) external virtual override onlyOwner {
    _factory = ITradingTokenFactoryV1(value);
  }

  function createToken(
    string memory name_, 
    string memory symbol_, 
    uint8 decimals_,
    uint256 totalSupply_,
    uint256[] memory tokenData
  ) external payable virtual override onlyNotPaused takeFee("DeployStandardToken") {
    uint40 id = uint40(_next());

    _tokens[id] = ITradingTokenV1(
      _factory.createToken(
        name_, 
        symbol_, 
        decimals_,
        totalSupply_,
        _msgSender(),
        tokenData
      )
    );

    address tokenAddress = address(_tokens[id]);
    _tokenAddressMap[tokenAddress] = id;
    emit CreatedToken(id, tokenAddress);
  }

  function _getTokenDataById(uint40 id) internal virtual view returns (
    address tokenAddress_,
    string memory name_, 
    string memory symbol_, 
    uint8 decimals_,
    uint256 totalSupply_,
    uint256 totalBalance_,
    uint256 launchedAt_,
    address owner_,
    address dexPair_
  ){
    (
      name_, 
      symbol_, 
      decimals_,
      totalSupply_,
      totalBalance_,
      launchedAt_,
      owner_,
      dexPair_
    ) = _tokens[id].getTokenData();

    tokenAddress_ = address(_tokens[id]);
  }

  function getTokenDataById(uint40 id) external override view returns (
    address tokenAddress_,
    string memory name_, 
    string memory symbol_, 
    uint8 decimals_,
    uint256 totalSupply_,
    uint256 totalBalance_,
    uint256 launchedAt_,
    address owner_,
    address dexPair_
  ){
    return _getTokenDataById(id);
  }

  function getTokenDataByAddress(address address_) external override view returns (
    address tokenAddress_,
    string memory name_, 
    string memory symbol_, 
    uint8 decimals_,
    uint256 totalSupply_,
    uint256 totalBalance_,
    uint256 launchedAt_,
    address owner_,
    address dexPair_
  ){
    return _getTokenDataById(_tokenAddressMap[address_]);
  }

  receive() external payable {}
}
