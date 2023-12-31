// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "./IERC20.sol";

contract RequiredDecimals {
    uint256 private constant _MAX_TOKEN_DECIMALS = 38;

    /**
     * Tries to fetch the decimals of a token, if not existent, fails with a require statement
     *
     * @param token An instance of IERC20
     * @return The decimals of a token
     */
    function tryDecimals(IERC20 token) internal view returns (uint8) {
        // solhint-disable-line private-vars-leading-underscore
        bytes memory payload = abi.encodeWithSignature("decimals()");
        // solhint-disable avoid-low-level-calls
        (bool success, bytes memory returnData) = address(token).staticcall(payload);

        require(success, "RequiredDecimals: required decimals");
        uint8 decimals = abi.decode(returnData, (uint8));
        require(decimals < _MAX_TOKEN_DECIMALS, "RequiredDecimals: token decimals should be lower than 38");

        return decimals;
    }
}
