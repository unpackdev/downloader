// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./IFactoryVersioning.sol";
import "./EnumerableMap.sol";
import "./AccessControl.sol";

contract SynthereumFactoryVersioning is
  ISynthereumFactoryVersioning,
  AccessControl
{
  using EnumerableMap for EnumerableMap.UintToAddressMap;

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  struct Roles {
    address admin;
    address maintainer;
  }

  EnumerableMap.UintToAddressMap private _poolsFactory;

  EnumerableMap.UintToAddressMap private _derivativeFactory;

  event AddPoolFactory(uint8 indexed version, address poolFactory);

  event RemovePoolFactory(uint8 indexed version);

  event AddDerivativeFactory(uint8 indexed version, address derivativeFactory);

  event RemoveDerivativeFactory(uint8 indexed version);

  constructor(Roles memory _roles) public {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _roles.admin);
    _setupRole(MAINTAINER_ROLE, _roles.maintainer);
  }

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  function setPoolFactory(uint8 version, address poolFactory)
    external
    override
    onlyMaintainer
  {
    _poolsFactory.set(version, poolFactory);
    emit AddPoolFactory(version, poolFactory);
  }

  function removePoolFactory(uint8 version) external override onlyMaintainer {
    require(
      _poolsFactory.remove(version),
      'Version of the pool factory does not exist'
    );
    emit RemovePoolFactory(version);
  }

  function setDerivativeFactory(uint8 version, address derivativeFactory)
    external
    override
    onlyMaintainer
  {
    _derivativeFactory.set(version, derivativeFactory);
    emit AddDerivativeFactory(version, derivativeFactory);
  }

  function removeDerivativeFactory(uint8 version)
    external
    override
    onlyMaintainer
  {
    require(
      _derivativeFactory.remove(version),
      'Version of the pool factory does not exist'
    );
    emit RemoveDerivativeFactory(version);
  }

  function getPoolFactoryVersion(uint8 version)
    external
    view
    override
    returns (address poolFactory)
  {
    poolFactory = _poolsFactory.get(version);
  }

  function numberOfVerisonsOfPoolFactory()
    external
    view
    override
    returns (uint256 numberOfVersions)
  {
    numberOfVersions = _poolsFactory.length();
  }

  function getDerivativeFactoryVersion(uint8 version)
    external
    view
    override
    returns (address derivativeFactory)
  {
    derivativeFactory = _derivativeFactory.get(version);
  }

  function numberOfVerisonsOfDerivativeFactory()
    external
    view
    override
    returns (uint256 numberOfVersions)
  {
    numberOfVersions = _derivativeFactory.length();
  }
}
