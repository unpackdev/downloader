// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./IERC20.sol";
import "./IVault.sol";
import "./IMintableOwnedERC20.sol";


struct ProjectParams {
    // used to circumvent 'Stack too deep' error when creating a _new project

    address projectVault;
    address projectToken;
    address paymentToken;

    string tokenName;
    string tokenSymbol;
    uint minPledgedSum;
    uint initialTokenSupply;

    bytes32 cid; // ref to metadata
}
