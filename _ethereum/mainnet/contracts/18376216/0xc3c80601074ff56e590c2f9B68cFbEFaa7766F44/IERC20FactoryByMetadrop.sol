// SPDX-License-Identifier: MIT
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.21;

import "./IERC20.sol";
import "./IConfigStructures.sol";
import "./IErrors.sol";
import "./IERC20ConfigByMetadrop.sol";

/**
 * @dev Metadrop ERC-20 factory, interface
 */
interface IERC20FactoryByMetadrop is
  IConfigStructures,
  IErrors,
  IERC20ConfigByMetadrop
{
  event DriPoolAddressUpdated(address oldAddress, address newAddress);

  event ERC20Created(
    string metaId,
    address indexed deployer,
    address contractInstance,
    address driPoolInstance,
    string symbol,
    string name
  );

  event MachineAddressUpdated(address oldAddress, address newAddress);

  event OracleAddressUpdated(address oldAddress, address newAddress);

  event MessageValidityInSecondsUpdated(
    uint256 oldMessageValidityInSeconds,
    uint256 newMessageValidityInSeconds
  );

  event PlatformTreasuryUpdated(address oldAddress, address newAddress);

  /**
   * @dev function {initialiseMachineAddress}
   *
   * Initialise the machine template address. This needs to be separate from
   * the constructor as the machine needs the factory address on its constructor.
   *
   * This must ALWAYS be called as part of deployment.
   *
   * @param machineTemplate_ the machine address
   */
  function initialiseMachineAddress(address machineTemplate_) external;

  /**
   * @dev function {decommissionFactory} onlySuperAdmin
   *
   * Make this factory unusable for creating new ERC20s, forever
   *
   */
  function decommissionFactory() external;

  /**
   * @dev function {setMetadropOracleAddress} onlyPlatformAdmin
   *
   * Set the metadrop trusted oracle address
   *
   * @param metadropOracleAddress_ Trusted metadrop oracle address
   */
  function setMetadropOracleAddress(address metadropOracleAddress_) external;

  /**
   * @dev function {setMessageValidityInSeconds} onlyPlatformAdmin
   *
   * Set the validity period of signed messages
   *
   * @param messageValidityInSeconds_ Validity period in seconds for messages signed by the trusted oracle
   */
  function setMessageValidityInSeconds(
    uint256 messageValidityInSeconds_
  ) external;

  /**
   * @dev function {setPlatformTreasury} onlySuperAdmin
   *
   * Set the address that platform fees will be paid to / can be withdrawn to.
   * Note that this is restricted to the highest authority level, the super
   * admin. Platform admins can trigger a withdrawal to the treasury, but only
   * the default admin can set or alter the treasury address. It is recommended
   * that the default admin is highly secured and restrited e.g. a multi-sig.
   *
   * @param platformTreasury_ New treasury address
   */
  function setPlatformTreasury(address platformTreasury_) external;

  /**
   * @dev function {setMachineAddress} onlyPlatformAdmin
   *
   * Set a new machine template address
   *
   * @param newMachineAddress_ the new machine address
   */
  function setMachineAddress(address newMachineAddress_) external;

  /**
   * @dev function {setDriPoolAddress} onlyPlatformAdmin
   *
   * Set a new launch pool template address
   *
   * @param newDriPoolAddress_ the new launch pool address
   */
  function setDriPoolAddress(address newDriPoolAddress_) external;

  /**
   * @dev function {withdrawETH} onlyPlatformAdmin
   *
   * A withdraw function to allow ETH to be withdrawn to the treasury
   *
   * @param amount_ The amount to withdraw
   */
  function withdrawETH(uint256 amount_) external;

  /**
   * @dev function {withdrawERC20} onlyPlatformAdmin
   *
   * A withdraw function to allow ERC20s to be withdrawn to the treasury
   *
   * @param token_ The contract address of the token being withdrawn
   * @param amount_ The amount to withdraw
   */
  function withdrawERC20(IERC20 token_, uint256 amount_) external;

  /**
   * @dev function {createERC20}
   *
   * Create an ERC-20
   *
   * @param metaId_ The drop Id being approved
   * @param salt_ Salt for create2
   * @param erc20Config_ ERC20 configuration
   * @param signedMessage_ The signed message object
   * @param vaultFee_ The fee for the token vault
   * @param deploymentFee_ The fee for deployment, if any
   * @return deployedAddress_ The deployed ERC20 contract address
   */
  function createERC20(
    string calldata metaId_,
    bytes32 salt_,
    ERC20Config calldata erc20Config_,
    SignedDropMessageDetails calldata signedMessage_,
    uint256 vaultFee_,
    uint256 deploymentFee_
  ) external payable returns (address deployedAddress_);

  /**
   * @dev function {createConfigHash}
   *
   * Create the config hash
   *
   * @param metaId_ The drop Id being approved
   * @param salt_ Salt for create2
   * @param erc20Config_ ERC20 configuration
   * @param messageTimeStamp_ When the message for this config hash was signed
   * @param vaultFee_ The fee for the token vault
   * @param deploymentFee_ The fee for deployment, if any
   * @param deployer_ Address performing the deployment
   * @return configHash_ The bytes32 config hash
   */
  function createConfigHash(
    string calldata metaId_,
    bytes32 salt_,
    ERC20Config calldata erc20Config_,
    uint256 messageTimeStamp_,
    uint256 vaultFee_,
    uint256 deploymentFee_,
    address deployer_
  ) external pure returns (bytes32 configHash_);
}
