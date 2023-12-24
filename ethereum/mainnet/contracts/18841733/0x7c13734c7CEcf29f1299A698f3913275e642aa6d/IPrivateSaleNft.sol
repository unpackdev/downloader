// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "./IERC721Upgradeable.sol";


interface IPrivateSaleNft is IERC721Upgradeable {
    error NotUpgrader();

    function mint(address, uint) external;

}
