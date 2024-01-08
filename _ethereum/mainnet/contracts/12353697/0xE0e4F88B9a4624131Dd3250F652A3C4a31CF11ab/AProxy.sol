//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

import "./UpgradeableProxy.sol";

contract AProxy is UpgradeableProxy {
  /**
    * @dev Storage slot with the address of the current proxy owner.
    * This is the keccak-256 hash of "eip1967.proxy.owner" subtracted by 1, and is
    * validated in the constructor.
    */
  bytes32 private constant _OWNER_SLOT = 0xa7b53796fd2d99cb1f5ae019b54f9e024446c3d12b483f733ccc62ed04eb126a;

  // eip1967.proxy.finalize - 1
  bytes32 private constant _FINALIZE_SLOT = 0x3e2d199ed03da5cdcce446f3024be9a0d330e8d46406c049ce8858437a7d2ff2;

  modifier onlyOwner() {
    bytes32 ownerSlot = _OWNER_SLOT;
    address owner;
    // solhint-disable-next-line no-inline-assembly
    assembly {
        owner := sload(ownerSlot)
    }
    require(msg.sender == owner, "msg.sender is not the owner");

    _;
  }

  modifier onlyNotFinalized() {
    bytes32 finalizeSlot = _FINALIZE_SLOT;
    bool finalized;
    // solhint-disable-next-line no-inline-assembly
    assembly {
        finalized := sload(finalizeSlot)
    }
    require(!finalized, "Implementation has been finalized.");
    _;
  }

  constructor(address _logic, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
    assert(_OWNER_SLOT == bytes32(uint256(keccak256("eip1967.proxy.owner")) - 1));
    assert(_FINALIZE_SLOT == bytes32(uint256(keccak256("eip1967.proxy.finalize")) - 1));

    // SET OWNER
    bytes32 slot = _OWNER_SLOT;
    address owner = msg.sender;
    // solhint-disable-next-line no-inline-assembly
    assembly {
        sstore(slot, owner)
    }
  }

  function upgradeTo(address _newImplementation) public onlyOwner onlyNotFinalized {
    _upgradeTo(_newImplementation);
  }

  function finalizeImplementation() public  onlyOwner onlyNotFinalized  {
    // SET Finalized
    bytes32 slot = _FINALIZE_SLOT;
    bool flag = true;
    // solhint-disable-next-line no-inline-assembly
    assembly {
        sstore(slot, flag)
    }
  }
}