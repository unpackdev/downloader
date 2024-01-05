// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./KeeperCompatible.sol";

contract UpkeepMock is KeeperCompatible {
  bool public canCheck;
  bool public canPerform;

  event UpkeepPerformedWith(bytes upkeepData);

  function setCanCheck(bool value)
    public
  {
    canCheck = value;
  }

  function setCanPerform(bool value)
    public
  {
    canPerform = value;
  }

  function checkUpkeep(bytes calldata data)
    external
    override
    cannotExecute()
    returns (
      bool callable,
      bytes calldata executedata
    )
  {
    bool couldCheck = canCheck;

    setCanCheck(false); // test that state modifcations don't stick

    return (couldCheck, data);
  }

  function performUpkeep(
    bytes calldata data
  )
    external
    override
  {
    require(canPerform, "Cannot perform");

    setCanPerform(false);

    emit UpkeepPerformedWith(data);
  }

}
