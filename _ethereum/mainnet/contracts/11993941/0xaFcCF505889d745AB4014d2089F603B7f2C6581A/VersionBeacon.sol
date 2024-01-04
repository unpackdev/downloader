// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./Ownable.sol";
import "./EnumerableSet.sol";


interface IVersionBeacon
{
  event Registered(bytes32 entity, uint256 version, address implementation);


  function exists(bytes32 entity) external view returns (bool status);

  function getLatestVersion(bytes32 entity) external view returns (uint256 version);

  function getLatestImplementation(bytes32 entity) external view returns (address implementation);

  function getImplementationAt(bytes32 entity, uint256 version) external view returns (address implementation);


  function register(bytes32 entity, address implementation) external returns (uint256 version);
}

contract VersionBeacon is IVersionBeacon, Ownable
{
  using EnumerableSet for EnumerableSet.Bytes32Set;


  EnumerableSet.Bytes32Set private _entitySet;
  mapping(bytes32 => address[]) private _versions;


  function getKey (string calldata name) external pure returns (bytes32)
  {
    return keccak256(bytes(name));
  }


  function exists(bytes32 entity) public view override returns (bool status)
  {
    return _entitySet.contains(entity);
  }

  function getImplementationAt(bytes32 entity, uint256 version) public view override returns (address implementation)
  {
    require(exists(entity) && version < _versions[entity].length, "no ver reg'd");

    // return implementation
    return _versions[entity][version];
  }

  function getLatestVersion(bytes32 entity) public view override returns (uint256 version)
  {
    require(exists(entity), "no ver reg'd");

    // get latest version
    return _versions[entity].length - 1;
  }

  function getLatestImplementation(bytes32 entity) public view override returns (address implementation)
  {
    uint256 latestVersion = getLatestVersion(entity);

    // return implementation
    return getImplementationAt(entity, latestVersion);
  }


  function register(bytes32 entity, address implementation) external override onlyOwner returns (uint256 version)
  {
    // get version number
    version = _versions[entity].length;

    // register entity
    _entitySet.add(entity);

    _versions[entity].push(implementation);

    emit Registered(entity, version, implementation);

    return version;
  }
}
