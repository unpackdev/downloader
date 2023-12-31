// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IDegenopolyPlayBoard {
    function mintableNode(address) external view returns (address);

    function setNodeMinted(address _account) external;
}
