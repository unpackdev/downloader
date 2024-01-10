// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IKaijuNFT {
    function mintTo(address to, bytes32 nfcId, string calldata tokenURI, uint256 birthDate)
    external
    returns (bool);
}
