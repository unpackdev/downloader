// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

import "./IERC20Metadata.sol";

interface IUSDC is IERC20Metadata {
    function configureMinter(
        address minter,
        uint256 minterAllowedAmount
    ) external;

    function mint(address account, uint256 amount) external;

    function bridgeMint(address account, uint256 amount) external;
}
