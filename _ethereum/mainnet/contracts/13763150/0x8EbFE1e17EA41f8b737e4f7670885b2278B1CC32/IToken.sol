// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "./IERC20.sol";

interface IToken is IERC20 {
    struct Distribution {
        address recipient;
        uint256 amount;
    }

    error NonZeroTotalSupply(uint256 totalSupply);

    /**
     * @notice Mints tokens according to `distributions` array, only one distribution is possible
     *
     * @param distributions Array of the Distribution structs,
     * which describe recipients and the corresponding amounts
     *
     * Requirements:
     *
     * - `_msgSender()` should be an owner
     * - `totalSupply()` should be equal to zero
     */
    function distribute(Distribution[] calldata distributions) external;
}
