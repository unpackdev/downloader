// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC20.sol";
import "./IERC4626.sol";

interface IWrappedRebaseTokenFactory {
    event newWrappedRebaseTokenContractDeployed(address deployer, address newWrappedRebaseTokenContract);

    function deploy(IERC20 asset, string memory name, string memory symbol)
        external
        returns (IERC4626 newWrappedRebaseTokenContract);
}
