// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IEMates.sol";
import "./IEthereumMix.sol";

interface IEMatesMinter {
    event SetMintPrice(uint256 mintPrice);
    event SetLimit(uint256 limit);

    function emates() external view returns (IEMates);
    function emix() external view returns (IEthereumMix);
    function mintPrice() external view returns (uint256);
    function limit() external view returns (uint256);

    function mint() external returns (uint256 id);
    function mintWithPermit(
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 id);
}
