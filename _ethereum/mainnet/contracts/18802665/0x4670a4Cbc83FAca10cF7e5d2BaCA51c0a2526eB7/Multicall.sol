// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./IMulticall.sol";

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) external virtual override returns (bytes[] memory) {
        bytes[] memory results = new bytes[](data.length);
        for (uint256 i; i < data.length;) {
            /// @custom:oz-upgrades-unsafe-allow-reachable delegatecall
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (success) {
                results[i] = result;
            } else {
                // Next 4 lines from
                // https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/utils/AddressUpgradeable.sol#L229
                if (result.length > 0) {
                    assembly {
                        let returndata_size := mload(result)
                        revert(add(32, result), returndata_size)
                    }
                } else {
                    revert FailedMulticall();
                }
            }

            unchecked {
                ++i;
            }
        }

        return results;
    }
}
