// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IResolverV2 {
    function harvestChecker(address vaultAddress)
        external
        view
        returns (bool canExec, bytes memory execPayload);

    function investChecker(address vaultAddress)
        external
        view
        returns (bool canExec, bytes memory execPayload);
}
