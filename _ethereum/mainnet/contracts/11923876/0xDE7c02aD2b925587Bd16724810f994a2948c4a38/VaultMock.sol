// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./VaultInterface.sol";
import "./IERC20.sol";

/**
 * @title Mock for yearn-style vaults for use in tests.
 */
contract VaultMock is VaultInterface {
    IERC20 public override token;
    uint256 private pricePerFullShare = 0;

    constructor(IERC20 _token) public {
        token = _token;
    }

    function getPricePerFullShare() external view override returns (uint256) {
        return pricePerFullShare;
    }

    function setPricePerFullShare(uint256 _pricePerFullShare) external {
        pricePerFullShare = _pricePerFullShare;
    }
}
