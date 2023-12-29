// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./Ownable.sol";

contract DexTracker is Ownable {
  error DexConflict(uint256 dexIndex);
  error DexDisabled();
  error DexTypeInvalid();
  event AddDex(address indexed executor, uint256 indexed dexId);
  event UpdateDex(address indexed executor, uint256 indexed dexId);

  struct Dex {
    uint64 id;
    address router;
    bool disabled;
    address payable wNative;
    DexType dexType;
    string name;
  }
  enum DexType {
    UNKNOWN,
    UNI_V2,
    UNI_V3,
    BAL_V2,
    PITEAS
  }
  Dex[] public dexInfo;
  function dexInfoSize() external view returns(uint256) {
    return dexInfo.length;
  }
  /**
   * @notice map a router to a dex to check
   * if the router was already added, the addition should fail
   */
  mapping(address => uint256) public routerToDex;
  /**
   * @notice Add new Dex
   * @dev This also generate id of the Dex
   * @param _dexName Name of the Dex
   * @param _router address of the dex router
   */
  function addDex(
    string calldata _dexName,
    address _router,
    address payable _wNative,
    DexType dexType
  ) external payable onlyOwner {
    _addDex(_dexName, _router, _wNative, dexType);
  }
  function _addDex(
    string calldata _dexName,
    address _router,
    address payable _wNative,
    DexType dexType
  ) internal {
    if (dexType == DexType.UNKNOWN) {
      revert DexTypeInvalid();
    }
    uint256 id = dexInfo.length;
    dexInfo.push(Dex({
      name: _dexName,
      router: _router,
      id: uint64(id),
      wNative: _wNative,
      dexType: dexType,
      disabled: false
    }));
    if (routerToDex[_router] != 0) {
      revert DexConflict(routerToDex[_router]);
    }
    routerToDex[_router] = dexInfo.length;
    emit AddDex(msg.sender, id);
  }

  /**
   * Updates dex info
   * @param index the id to update in dexInfo array
   * @param _name pass anything other than an empty string to update the name
   * @notice _factory is not used in these contracts
   * it is held for external services to utilize
   */
  function updateDex(
    uint256 index,
    string memory _name,
    address payable _wNative,
    DexType dexType
  ) external payable onlyOwner {
    _updateDex(index, _name, _wNative, dexType);
  }
  function _updateDex(
    uint256 index,
    string memory _name,
    address payable _wNative,
    DexType dexType
  ) internal {
    if (bytes(_name).length == 0) {
      return;
    }
    dexInfo[index].name = _name;
    dexInfo[index].wNative = _wNative;
    dexInfo[index].dexType = dexType;
    emit UpdateDex(msg.sender, index);
  }

  /**
   * sets disabled flag on a dex
   * @param id the dex id to disable
   * @param disabled the boolean denoting whether to disable or enable
   */
  function disableDex(uint256 id, bool disabled) external payable onlyOwner {
    if (dexInfo[id].disabled == disabled) {
      return;
    }
    dexInfo[id].disabled = disabled;
    emit UpdateDex(msg.sender, id);
  }
}
