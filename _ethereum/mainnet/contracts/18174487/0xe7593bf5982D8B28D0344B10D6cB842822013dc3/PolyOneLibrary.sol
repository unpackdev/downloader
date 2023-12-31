// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./ICreatorCore.sol";
import "./Ownable.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC721Metadata.sol";
import "./IERC165.sol";
import "./Strings.sol";
import "./PolyOneCreator.sol";
import "./IPolyOneDrop.sol";

/**
 * @notice Shared helpers for Poly One contracts
 */
library PolyOneLibrary {
  /**
   * @dev Thrown whenever a zero-address check fails
   * @param field The name of the field on which the zero-address check failed
   */
  error ZeroAddress(string field);

  /**
   * @notice Thrown when attempting to validate a collection which is not of the expected ERC721Creator or ERC1155Creator type
   */
  error InvalidContractType();

  /**
   * @notice Throw if the caller is not the expected caller
   * @param _caller The caller of the function
   */
  error InvalidCaller(address _caller);

  /**
   * @notice Thrown if the total sale distribution percentage is not 100
   */
  error InvalidSaleDistribution();

  /**
   * @notice Thrown if an array total does not match
   */
  error ArrayTotalMismatch();

  /**
   * @notice Check if a field is the zero address, if so revert with the field name
   * @param _address The address to check
   * @param _field The name of the field to check
   */
  function checkZeroAddress(address _address, string memory _field) internal pure {
    if (_address == address(0)) {
      revert ZeroAddress(_field);
    }
  }

  bytes4 constant ERC721_INTERFACE_ID = type(IERC721Metadata).interfaceId;
  bytes4 constant ERC1155_INTERFACE_ID = type(IERC1155MetadataURI).interfaceId;
  bytes4 constant CREATOR_CORE_INTERFACE_ID = type(ICreatorCore).interfaceId;

  /**
   * @notice Validate that a contract conforms to the expected standard by validating the interface support of an implementation contract
   *         via ERC165 `supportInterface` (see https://eips.ethereum.org/EIPS/eip-165)
   * @dev This will throw an unexpected error if the contract does not support ERC165
   * @param _contractAddress The address of the contract to validate
   * @param _isERC721 Whether the contract is an ERC721 (true) or ERC1155 (false)
   */
  function validateProxyCreatorContract(address _contractAddress, bool _isERC721) internal view {
    bytes4 expectedInterfaceId = _isERC721 ? ERC721_INTERFACE_ID : ERC1155_INTERFACE_ID;
    IERC165 implementation = IERC165(IPolyOneCreator(_contractAddress).implementation());
    if (!implementation.supportsInterface(expectedInterfaceId) || !implementation.supportsInterface(CREATOR_CORE_INTERFACE_ID)) {
      revert InvalidContractType();
    }
  }

  /**
   * @notice Validate that a contract implements the IPolyOneDrop interface
   * @param _contractAddress The address of the contract to validate
   */
  function validateDropContract(address _contractAddress) internal view {
    IERC165 implementation = IERC165(_contractAddress);
    if (!implementation.supportsInterface(type(IPolyOneDrop).interfaceId)) {
      revert InvalidContractType();
    }
  }

  /**
   * @notice Validate that a caller is the owner of a collection
   * @dev The contract address being check must inerit the OpenZeppelin Ownable standard
   * @param _contractAddress The address of the collection to validate
   * @param _caller The address of the owner to validate
   * @return True if the caller is the owner of the contract
   */
  function validateContractOwner(address _contractAddress, address _caller) internal view returns (bool) {
    address owner = Ownable(_contractAddress).owner();
    if (owner != _caller) {
      revert InvalidCaller(_caller);
    }
    return true;
  }

  /**
   * @notice Validate that a caller is the creator of a PolyOneCreator contract
   * @param _contractAddress The address of the collection to validate
   * @param _caller The address of the caller to validate
   * @return True if the caller is the creator of the contract
   */
  function validateContractCreator(address _contractAddress, address _caller) internal view returns (bool) {
    address creator = IPolyOneCreator(_contractAddress).creator();
    if (creator != _caller) {
      revert InvalidCaller(_caller);
    }
    return true;
  }

  /**
   * @notice Check if a date is in the past (before the current block timestamp)
   *         If the timestamps are equal, this is considered to be in the past
   */
  function isDateInPast(uint256 _date) internal view returns (bool) {
    return block.timestamp >= _date;
  }

  /**
   * @dev Validate that the sum of all items in a uint array is equal to a given total
   * @param _array The array to validate
   * @param _total The total to validate against
   */
  function validateArrayTotal(uint256[] memory _array, uint256 _total) internal pure {
    uint256 total = 0;
    for (uint i = 0; i < _array.length; i++) {
      total += _array[i];
    }
    if (total != _total) {
      revert ArrayTotalMismatch();
    }
  }

  /**
   * @dev Convert an address to an array of length 1 with a single address
   * @param _address The address to convert
   * @return A length 1 array containing _address
   */
  function addressToAddressArray(address _address) internal pure returns (address[] memory) {
    address[] memory array = new address[](1);
    array[0] = _address;
    return array;
  }

  /**
   * @dev Convert a uint to an array of length 1 with a single address
   * @param _uint The uint to convert
   * @return A length 1 array containing _uint
   */
  function uintToUintArray(uint256 _uint) internal pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = _uint;
    return array;
  }

  /**
   * @dev Convert a string array to an array of length 1 with a single string
   * @param _string The string to convert
   * @return A length 1 array containing _string
   */
  function stringToStringArray(string memory _string) internal pure returns (string[] memory) {
    string[] memory array = new string[](1);
    array[0] = _string;
    return array;
  }

  /**
   * @dev Check if an address is a contract
   * @param _address The address to check
   */
  function isContract(address _address) internal view returns (bool) {
    uint32 size;
    assembly {
      size := extcodesize(_address)
    }
    return (size > 0);
  }
}
