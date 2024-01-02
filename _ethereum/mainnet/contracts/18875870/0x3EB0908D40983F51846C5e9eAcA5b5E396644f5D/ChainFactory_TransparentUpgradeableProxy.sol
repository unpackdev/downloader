/*
   ________          _       ______           __                  
  / ____/ /_  ____ _(_)___  / ____/___ ______/ /_____  _______  __
 / /   / __ \/ __ `/ / __ \/ /_  / __ `/ ___/ __/ __ \/ ___/ / / /
/ /___/ / / / /_/ / / / / / __/ / /_/ / /__/ /_/ /_/ / /  / /_/ / 
\____/_/ /_/\__,_/_/_/ /_/_/    \__,_/\___/\__/\____/_/   \__, /  
                                                         /____/   
  ChainFactory Transparent Upgradeable Proxy

  Web:      https://chainfactory.app/
  X:        https://x.com/ChainFactoryApp
  Telegram: https://t.me/ChainFactory
  Discord:  https://discord.gg/fpjxD39v3k
  YouTube:  https://youtube.com/@UpfrontDeFi

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

library Address {
  function isContract(address _contract) internal view returns (bool) {
    return _contract.code.length > 0;
  }
}

library StorageSlot {
  function getAddressSlot(bytes32 _slot) internal view returns (address) {
    address addr;

    assembly {
      addr := sload(_slot)
    }

    return addr;
  }

  function setAddressSlot(bytes32 _slot, address _addr) internal {
    assembly {
      sstore(_slot, _addr)
    }
  }
}

contract ChainFactory_TransparentUpgradeableProxy {
  bytes32 private constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
  bytes32 private constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event ImplementationUpgraded(address indexed implementation);

  modifier onlyOwner() {
    if (msg.sender == owner()) {
      _;
    } else {
      _fallback();
    }
  }

  constructor() {
    _transferOwnership(msg.sender);
  }

  function owner() public view returns (address) {
    return StorageSlot.getAddressSlot(ADMIN_SLOT);
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0));

    _transferOwnership(newOwner);
  }

  function getImplementation() external view returns (address) {
    return _getImplementation();
  }

  function setImplementation(address _implementation) external onlyOwner {
    _setImplementation(_implementation);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));

    address oldOwner = owner();

    StorageSlot.setAddressSlot(ADMIN_SLOT, newOwner);

    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function _getImplementation() internal view returns (address) {
    return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT);
  }

  function _setImplementation(address _implementation) internal {
    require(Address.isContract(_implementation), "Not a contract");

    StorageSlot.setAddressSlot(IMPLEMENTATION_SLOT, _implementation);

    emit ImplementationUpgraded(_implementation);
  }

  function _delegate(address _implementation) internal returns (bytes memory) {
    assembly {
      let csize := calldatasize()

      calldatacopy(0, 0, csize)

      let result := delegatecall(gas(), _implementation, 0, csize, 0, 0)
      let rsize := returndatasize()

      returndatacopy(0, 0, rsize)

      switch result
        case 0 { revert(0, rsize) }
        default { return(0, rsize) }
    }
  }

  function _fallback() internal {
    _delegate(_getImplementation());
  }

  receive() external payable { _fallback(); }
  fallback() external payable { _fallback(); }
}