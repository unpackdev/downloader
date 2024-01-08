// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./AutoRefactorCoinageWithTokenId.sol";
import "./IStakeCoinageFactory.sol";

contract StakeCoinageFactory is IStakeCoinageFactory {
    uint256 public constant RAY = 10**27; // 1 RAY
    uint256 internal constant _DEFAULT_FACTOR = RAY;

    function deploy(address owner) external override returns (address) {
        AutoRefactorCoinageWithTokenId c =
            new AutoRefactorCoinageWithTokenId(_DEFAULT_FACTOR);

        c.transferAdmin(owner);

        return address(c);
    }
}
