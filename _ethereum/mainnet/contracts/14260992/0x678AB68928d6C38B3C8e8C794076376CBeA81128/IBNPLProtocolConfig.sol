// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UpgradeableBeacon.sol";
import "./IERC20.sol";

import "./IBankNodeManager.sol";
import "./BNPLKYCStore.sol";

/// @title BNPL Protocol configuration contract
///
/// @notice
/// - Include:
///     **Network Info**
///     **BNPL token contracts**
///     **BNPL UpBeacon contracts**
///     **BNPL BankNodeManager contract**
///
/// @author BNPL
interface IBNPLProtocolConfig {
    /// @notice Returns blockchain network id
    /// @return networkId blockchain network id
    function networkId() external view returns (uint64);

    /// @notice Returns blockchain network name
    /// @return networkName blockchain network name
    function networkName() external view returns (string memory);

    /// @notice Returns BNPL token address
    /// @return bnplToken BNPL token contract
    function bnplToken() external view returns (IERC20);

    /// @notice Returns bank node manager upBeacon contract
    /// @return upBeaconBankNodeManager bank node manager upBeacon contract
    function upBeaconBankNodeManager() external view returns (UpgradeableBeacon);

    /// @notice Returns bank node upBeacon contract
    /// @return upBeaconBankNode bank node upBeacon contract
    function upBeaconBankNode() external view returns (UpgradeableBeacon);

    /// @notice Returns bank node lending pool token upBeacon contract
    /// @return upBeaconBankNodeLendingPoolToken bank node lending pool token upBeacon contract
    function upBeaconBankNodeLendingPoolToken() external view returns (UpgradeableBeacon);

    /// @notice Returns bank node staking pool upBeacon contract
    /// @return upBeaconBankNodeStakingPool bank node staking pool upBeacon contract
    function upBeaconBankNodeStakingPool() external view returns (UpgradeableBeacon);

    /// @notice Returns bank node staking pool token upBeacon contract
    /// @return upBeaconBankNodeStakingPoolToken bank node staking pool token upBeacon contract
    function upBeaconBankNodeStakingPoolToken() external view returns (UpgradeableBeacon);

    /// @notice Returns bank node lending rewards upBeacon contract
    /// @return upBeaconBankNodeLendingRewards bank node lending rewards upBeacon contract
    function upBeaconBankNodeLendingRewards() external view returns (UpgradeableBeacon);

    /// @notice Returns BNPL KYC store upBeacon contract
    /// @return upBeaconBNPLKYCStore BNPL KYC store upBeacon contract
    function upBeaconBNPLKYCStore() external view returns (UpgradeableBeacon);

    /// @notice Returns BankNodeManager contract
    /// @return bankNodeManager BankNodeManager contract
    function bankNodeManager() external view returns (IBankNodeManager);
}
