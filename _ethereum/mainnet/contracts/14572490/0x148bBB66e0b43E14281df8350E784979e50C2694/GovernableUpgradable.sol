pragma solidity ^0.6.12;
import "./Storage.sol";
import "./Initializable.sol";

// File: contracts/Governable.sol

contract GovernableUpgradable is Initializable {
  Storage public store;

  function __Governable_init(Storage _store) public initializer {
    store = _store;
  }

  function onlyOwner() internal view{
    require(store.owner() == msg.sender, "Not the owner");
  }

  function onlyGovernance() internal view{
    require(store.governance(msg.sender), "Not governance");
  }

  function onlyController() internal view{
    require(store.controller(msg.sender), "Not controller");
  }

  function onlyGovernaneOrController() internal view{
    require(store.controller(msg.sender) || store.governance(msg.sender) , "Not a owner/controller");
  }
}
