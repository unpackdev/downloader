// SPDX-License-Identifier: BUSL-1.1
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.21;

import "./Context.sol";
import "./ERC20ByMetadrop.sol";
import "./IERC20MachineByMetadrop.sol";
import "./Revert.sol";

/**
 * @dev Metadrop ERC-20 contract deployer
 *
 * @dev Implementation of the {IERC20MachineByMetasdrop} interface.
 *
 * Lightweight deployment module for use with template contracts
 */
contract ERC20MachineByMetadrop is Context, IERC20MachineByMetadrop, Revert {
  address public immutable factory;
  uint256 public immutable bytesStartPosition;

  /**
   * @dev {constructor}
   *
   * @param factory_ Address of the factory
   */
  constructor(address factory_) {
    factory = factory_;

    (bool validStartPosition, uint256 startPosition) = getBytesStartPosition();

    if (!validStartPosition) {
      _revert(DeploymentError.selector);
    } else {
      bytesStartPosition = startPosition;
    }
  }

  /**
   * @dev {onlyFactory}
   *
   * Throws if called by any account other than the factory.
   */
  modifier onlyFactory() {
    if (factory != _msgSender()) {
      _revert(CallerIsNotFactory.selector);
    }
    _;
  }

  /**
   * @dev function {deploy} Deploy a fresh instance
   *
   * @param metaIdHash_ The hash of this token deployment identifier
   * @param salt_ Provided sale for create2
   * @param args_ Constructor arguments
   */
  function deploy(
    bytes32 metaIdHash_,
    bytes32 salt_,
    bytes memory args_
  ) external payable onlyFactory returns (address erc20ContractAddress_) {
    // First check the metadIdHash_ is valid:
    if (_startsWithEmptyByte(metaIdHash_)) {
      _revert(InvalidHash.selector);
    }

    // 1) Get the deployment bytecode:
    bytes memory deploymentBytecode = type(ERC20ByMetadrop).creationCode;

    uint256 startPositionInMemoryForAssembly = bytesStartPosition;

    // 2) Modify the bytecode, replacing the default metaIdHash with the received value.
    // This allows us to verify the contract code (with comments) for every token,
    // rather than matching the deployed code (and comments) of previous tokens.
    assembly {
      // Define the start position
      let start := add(deploymentBytecode, startPositionInMemoryForAssembly)

      // Copy the bytes32 value to the specified position
      mstore(add(start, 0x20), metaIdHash_)
    }
    // 3) Add the args to the bytecode:
    bytes memory deploymentData = abi.encodePacked(deploymentBytecode, args_);

    // 4) Deploy it:
    assembly {
      erc20ContractAddress_ := create2(
        0,
        add(deploymentData, 0x20),
        mload(deploymentData),
        salt_
      )
      if iszero(extcodesize(erc20ContractAddress_)) {
        revert(0, 0)
      }
    }

    return (erc20ContractAddress_);
  }

  /**
   * @dev function {_startsWithEmptyByte} Does the passed hash start with
   * an empty byte?
   *
   * @param hash_ The bytes32 hash
   * @return bool The hash does / doesn't start with an empty tybe
   */
  function _startsWithEmptyByte(bytes32 hash_) internal pure returns (bool) {
    return bytes1(hash_) == 0x00;
  }

  /**
   * @dev function {getBytesStartPosition} Get the replacement bytes start position
   *
   * @return found_ If the bytes have been found
   * @return startPosition_ The start position of the bytes
   */
  function getBytesStartPosition()
    public
    pure
    returns (bool found_, uint256 startPosition_)
  {
    bytes
      memory bytesTarget = hex"4D45544144524F504D45544144524F504D45544144524F504D45544144524F50";
    bytes memory deploymentCode = type(ERC20ByMetadrop).creationCode;

    // Iterate through the bytecode to find the search bytes.
    // Start at a reasonable position: byte 5000
    for (
      uint256 i = 5000;
      i < deploymentCode.length - bytesTarget.length + 1;
      i += 1
    ) {
      bool found = true;

      // Check if the current chunk matches the search string
      for (uint256 j = 0; j < bytesTarget.length; j++) {
        if (deploymentCode[i + j] != bytesTarget[j]) {
          found = false;
          break;
        }
      }

      if (found) {
        return (true, i);
      }
    }

    return (false, 0);
  }
}
