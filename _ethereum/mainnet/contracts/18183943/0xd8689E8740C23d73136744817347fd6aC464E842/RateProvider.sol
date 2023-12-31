// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IRateProvider.sol";
import "./IERC4626.sol";
import "./Errors.sol";

contract RateProvider is IRateProvider {
    uint256 private constant _ONE = 1e18;

    IERC4626 public immutable token;

    constructor(IERC4626 _token) {
        if (address(_token) == address(0)) {
            revert KUMA_PROTOCOL_ERRORS.CANNOT_SET_TO_ADDRESS_ZERO();
        }

        token = _token;
    }

    /**
     * @return Value of token in terms of underlying asset in 18 decimal
     */
    function getRate() external view override returns (uint256) {
        return token.convertToAssets(_ONE);
    }
}
