// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; // solhint-disable-line compiler-version
pragma abicoder v2;

import "./IERC20.sol";
import "./Kernel.sol";

abstract contract AirdropRegistryStorage is Kernel {
    struct AirdropInfo {
        address token;
        address beneficiary;
        uint256 amount;
        uint256 nonce;
        uint256 chainID;
    }

    //////////////////////////////////////////
    //
    // AirdropRegistry
    //
    //////////////////////////////////////////

    address public tokenWallet;

    // airdrop info hash => boolean
    mapping(bytes32 => bool) public claimed;
}
