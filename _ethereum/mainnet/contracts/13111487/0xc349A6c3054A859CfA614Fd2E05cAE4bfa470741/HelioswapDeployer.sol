// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Helioswap.sol";

contract HelioswapDeployer {
    function deploy(
        IERC20 token1,
        IERC20 token2,
        string calldata name,
        string calldata symbol,
        address poolOwner
    ) external returns(Helioswap pool) {
        pool = new Helioswap(
            token1,
            token2,
            name,
            symbol,
            IBaseHelioswapFactory(msg.sender)
        );

        pool.transferOwnership(poolOwner);
    }
}
