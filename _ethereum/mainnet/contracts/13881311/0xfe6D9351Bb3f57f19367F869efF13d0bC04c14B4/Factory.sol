// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "./Timelock.sol";
import "./ITokenBaseDeployer.sol";
import "./INFTBaseDeployer.sol";
import "./IFixedPeriodDeployer.sol";
import "./IFixedPriceDeployer.sol";
import "./Clones.sol";

contract Factory is OwnableUpgradeable {
  address public immutable TIMELOCK_IMPL;

  address private tokenBaseDeployer; // staking erc20 tokens to mint PASS
  address private nftBaseDeployer; // staking erc721 tokens to mint PASS
  address private fixedPeriodDeployer; // pay erc20 tokens to mint PASS in a fixed period with linearly decreasing price
  address private fixedPriceDeployer; // pay erc20 tokens to mint PASS with fixed price

  address public timelock;
  address payable public platform; // The PASS platform commission account
  uint256 public platformRate; // The PASS platform commission rate in pph

  constructor(
    address _timelock,
    address _tokenBaseDeployer,
    address _nftBaseDeployer,
    address _fixedPeriodDeployer,
    address _fixedPriceDeployer,
    address payable _platform,
    uint256 _platformRate
  ) {
    __Ownable_init(_timelock);
    timelock = _timelock;
    tokenBaseDeployer = _tokenBaseDeployer;
    nftBaseDeployer = _nftBaseDeployer;
    fixedPeriodDeployer = _fixedPeriodDeployer;
    fixedPriceDeployer = _fixedPriceDeployer;
    _setPlatformParms(_platform, _platformRate);

    TIMELOCK_IMPL = address(new Timelock());
  }

  event TokenBaseDeploy(
    address indexed _addr, // address of deployed NFT PASS contract
    string _name, // name of PASS
    string _symbol, // symbol of PASS
    string _bURI, // baseuri of NFT PASS
    address _erc20, // address of staked erc20 tokens
    uint256 _rate // staking rate of erc20 tokens/PASS
  );
  event NFTBaseDeploy(
    address indexed _addr,
    string _name,
    string _symbol,
    string _bURI,
    address _erc721 // address of staked erc721 tokens
  );
  event FixedPeriodDeploy(
    address indexed _addr,
    string _name,
    string _symbol,
    string _bURI,
    address _erc20, // payment erc20 tokens
    address _platform,
    address _receivingAddress, // creator's receivingAddress account to receive erc20 tokens
    uint256 _initialRate, // initial exchange rate of erc20 tokens/PASS
    uint256 _startTime, // start time of sales period
    uint256 _endTime, // start time of sales
    uint256 _maxSupply, // maximum supply of PASS
    uint256 _platformRate
  );

  event FixedPriceDeploy(
    address indexed _addr,
    string _name,
    string _symbol,
    string _bURI,
    address _erc20, // payment erc20 tokens
    address _platform,
    address _receivingAddress,
    uint256 _rate,
    uint256 _maxSupply,
    uint256 _platformRate
  );

  event SetPlatformParms(address _platform, uint256 _platformRate);

  // set the platform account and commission rate, only operable by contract owner, _platformRate is in pph
  function setPlatformParms(address payable _platform, uint256 _platformRate)
    public
    onlyOwner
  {
    _setPlatformParms(_platform, _platformRate);
  }

  // set up the platform parameters internal
  function _setPlatformParms(address payable _platform, uint256 _platformRate)
    internal
  {
    require(_platform != address(0), "Curve: platform address is zero");
    require(_platformRate <= 100, "Curve: wrong rate");

    platform = _platform;
    platformRate = _platformRate;

    emit SetPlatformParms(_platform, _platformRate);
  }

  function tokenBaseDeploy(
    string memory _name,
    string memory _symbol,
    string memory _bURI,
    address _erc20,
    uint256 _rate,
    address _timelock
  ) public {
    ITokenBaseDeployer factory = ITokenBaseDeployer(tokenBaseDeployer);
    //return the address of deployed NFT PASS contract
    address addr = factory.deployTokenBase(
      _name,
      _symbol,
      _bURI,
      _timelock == address(0) ? cloneTimelock() : _timelock,
      _erc20,
      _rate
    );
    emit TokenBaseDeploy(addr, _name, _symbol, _bURI, _erc20, _rate);
  }

  function nftBaseDeploy(
    string memory _name,
    string memory _symbol,
    string memory _bURI,
    address _erc721,
    address _timelock
  ) public {
    INFTBaseDeployer factory = INFTBaseDeployer(nftBaseDeployer);
    address addr = factory.deployNFTBase(
      _name,
      _symbol,
      _bURI,
      _timelock == address(0) ? cloneTimelock() : _timelock,
      _erc721
    );
    emit NFTBaseDeploy(addr, _name, _symbol, _bURI, _erc721);
  }

  function fixedPeriodDeploy(
    string memory _name,
    string memory _symbol,
    string memory _bURI,
    address _erc20,
    address payable _receivingAddress,
    uint256 _initialRate,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _maxSupply,
    address _timelock
  ) public {
    address addr = IFixedPeriodDeployer(fixedPeriodDeployer).deployFixedPeriod(
      _name,
      _symbol,
      _bURI,
      _timelock == address(0) ? cloneTimelock() : _timelock,
      _erc20,
      platform,
      _receivingAddress,
      _initialRate,
      _startTime,
      _endTime,
      _maxSupply,
      platformRate
    );
    emit FixedPeriodDeploy(
      addr,
      _name,
      _symbol,
      _bURI,
      _erc20,
      platform,
      _receivingAddress,
      _initialRate,
      _startTime,
      _endTime,
      _maxSupply,
      platformRate
    );
  }

  function fixedPriceDeploy(
    string memory _name,
    string memory _symbol,
    string memory _bURI,
    address _erc20,
    address payable _receivingAddress,
    uint256 _rate,
    uint256 _maxSupply,
    address _timelock
  ) public {
    IFixedPriceDeployer factory = IFixedPriceDeployer(fixedPriceDeployer);
    address addr = factory.deployFixedPrice(
      _name,
      _symbol,
      _bURI,
      _timelock == address(0) ? cloneTimelock() : _timelock,
      _erc20,
      platform,
      _receivingAddress,
      _rate,
      _maxSupply,
      platformRate
    );
    emit FixedPriceDeploy(
      addr,
      _name,
      _symbol,
      _bURI,
      _erc20,
      platform,
      _receivingAddress,
      _rate,
      _maxSupply,
      platformRate
    );
  }

  function cloneTimelock() private returns (address payable newTimelock) {
    newTimelock = payable(Clones.clone(TIMELOCK_IMPL));

    uint256 minDelay = 2 days;
    address[] memory proposers = new address[](1);
    address[] memory executors = new address[](1);
    proposers[0] = msg.sender;
    executors[0] = address(0);

    Timelock(newTimelock).initialize(minDelay, proposers, executors);
    (minDelay, proposers, executors);

    return newTimelock;
  }
}
