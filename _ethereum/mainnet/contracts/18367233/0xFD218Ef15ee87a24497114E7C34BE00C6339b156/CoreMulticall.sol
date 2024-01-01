// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./ICoreMulticallV1.sol";
import "./Address.sol";
import "./DefinitiveAssets.sol";

/* solhint-disable max-line-length */
/**
 * @notice Implements openzeppelin/contracts/utils/Multicall.sol
 * Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/5b027e517e6aee69f4b4b2f5e78274ac8ee53513/contracts/utils/Multicall.sol solhint-disable max-line-length
 */
/* solhint-enable max-line-length */
abstract contract CoreMulticall is ICoreMulticallV1 {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        uint256 dataLength = data.length;
        results = new bytes[](dataLength);
        for (uint256 i; i < dataLength; ) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getBalance(address assetAddress) public view returns (uint256) {
        return DefinitiveAssets.getBalance(assetAddress);
    }
}
