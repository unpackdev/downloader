// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

/// @title Library for pagination of address array
/// @author Radiant Devs
/// @dev All function calls are currently implemented without side effects
library AddressPagination {
    /**
     * @notice Paginate address array.
	 * @param array source address array.
	 * @param page number
	 * @param limit per page
	 * @return result address array.
	 */
    function paginate(
        address[] memory array,
        uint256 page,
        uint256 limit
    ) internal pure returns (address[] memory result) {
        result = new address[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (page * limit + i >= array.length) {
                result[i] = address(0);
            } else {
                result[i] = array[page * limit + i];
            }
        }
    }
}
