// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./Proxy.sol";
import "./Address.sol";
import "./StorageSlot.sol";

/**
 * @title Interface for PolyOneCreator
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Interface for the PolyOneCreator Proxy contract
 */
interface IPolyOneCreator {
  /**
   * @notice The original creator of the contract. This is the only address that can reclaim ownership of the contract from PolyOneCore
   * @return The address of the creator
   */
  function creator() external view returns (address);

  /**
   * @notice The address of the Manifold implementation contract (ERC721CreatorImplementation or ERC1155CreatorImplementation)
   * @return The address of the implementation contract
   */
  function implementation() external view returns (address);
}

/**
 * @title PolyOneCreator
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @custom:contributor manifoldxyz (manifold.xyz)
 * @notice Deployable Proxy contract that delagates implementation to Manifold Core and registers the PolyOneCore contract as administrator
 */
contract PolyOneCreator is Proxy, IPolyOneCreator {
  address public immutable creator;

  /**
   * @param _name The name of the collection
   * @param _symbol The symbol for the collection
   * @param _implementationContract The address of the Manifold implementation contract (ERC721CreatorImplementation or ERC1155CreatorImplementation)
   * @param _polyOneCore The address of the PolyOneCore contract
   * @param _operatorFilter The address of the OpenSea Filter Registry contract
   */
  constructor(string memory _name, string memory _symbol, address _implementationContract, address _polyOneCore, address _operatorFilter) {
    assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _implementationContract;

    require(_implementationContract != address(0), "Implementation cannot be 0x0");
    require(_implementationContract.code.length > 0, "Implementation must be a contract");
    (bool initSuccess, ) = _implementationContract.delegatecall(abi.encodeWithSignature("initialize(string,string)", _name, _symbol));
    require(initSuccess, "Initialization failed");

    require(_operatorFilter != address(0), "Operator Filter cannot be 0x0");
    require(_operatorFilter.code.length > 0, "Operator Filter must be a contract");
    (bool approveOpenSeaSuccess, ) = _implementationContract.delegatecall(
      abi.encodeWithSignature("setApproveTransfer(address)", _operatorFilter)
    );
    require(approveOpenSeaSuccess, "OpenSea Registry approval failed");

    require(_polyOneCore != address(0), "PolyOneCore cannot be 0x0");
    require(_polyOneCore.code.length > 0, "PolyOneCore must be a contract");
    (bool approvePolyOneSuccess, ) = _implementationContract.delegatecall(
      abi.encodeWithSignature("transferOwnership(address)", _polyOneCore)
    );
    require(approvePolyOneSuccess, "PolyOneCore transfer failed");

    creator = msg.sender;
  }

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  function implementation() public view returns (address) {
    return _implementation();
  }

  function _implementation() internal view override returns (address) {
    return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
  }
}
