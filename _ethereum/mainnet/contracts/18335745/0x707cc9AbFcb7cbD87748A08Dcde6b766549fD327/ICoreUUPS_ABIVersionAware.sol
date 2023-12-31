// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

// solhint-disable-next-line contract-name-camelcase
interface ICoreUUPS_ABIVersionAware {
    /// @notice Define this with a `constant`
    /// @dev EG: `uint256 public constant ABI_VERSION = 1;`
    function ABI_VERSION() external view returns (uint256);

    /// @notice This method should return `Initializable._getInitializedVersion()`
    function getVersion() external view returns (uint256);
}
