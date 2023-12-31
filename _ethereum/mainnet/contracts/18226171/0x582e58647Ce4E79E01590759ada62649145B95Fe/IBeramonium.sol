// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721A.sol";

/**
 * @title Interface for the OpenZepplin's {Ownable} contract.
 */
interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
}

interface IBeramonium is IERC721A, IOwnable {
    function setCollectionSize(uint256 size_) external;

    function isTierOn(uint256 tier) external view returns (bool);

    function publicSaleMint(uint256 quantity) external payable;
}
