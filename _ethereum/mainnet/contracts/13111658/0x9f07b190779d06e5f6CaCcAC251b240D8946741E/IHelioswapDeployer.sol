// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Helioswap.sol";

interface IHelioswapDeployer {
    function deploy(
        IERC20 token1,
        IERC20 token2,
        string calldata name,
        string calldata symbol,
        address poolOwner
    ) external returns (Helioswap pool);
}