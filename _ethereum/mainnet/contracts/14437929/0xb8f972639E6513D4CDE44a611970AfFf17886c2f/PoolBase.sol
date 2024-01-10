// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import "./ERC165.sol";
import "./ERC1155Enumerable.sol";
import "./IERC20Metadata.sol";
import "./Multicall.sol";

import "./PoolStorage.sol";
import "./PoolInternal.sol";

/**
 * @title Premia option pool
 * @dev deployed standalone and referenced by PoolProxy
 */
contract PoolBase is PoolInternal, ERC1155Enumerable, ERC165, Multicall {
    constructor(
        address ivolOracle,
        address weth,
        address premiaMining,
        address feeReceiver,
        address feeDiscountAddress,
        int128 feePremium64x64,
        int128 feeApy64x64
    )
        PoolInternal(
            ivolOracle,
            weth,
            premiaMining,
            feeReceiver,
            feeDiscountAddress,
            feePremium64x64,
            feeApy64x64
        )
    {}

    /**
     * @notice see IPoolBase; inheritance not possible due to linearization issues
     */
    function name() external view returns (string memory) {
        PoolStorage.Layout storage l = PoolStorage.layout();

        return
            string(
                abi.encodePacked(
                    IERC20Metadata(l.underlying).symbol(),
                    " / ",
                    IERC20Metadata(l.base).symbol(),
                    " - Premia Options Pool"
                )
            );
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(PoolInternal, ERC1155Enumerable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
