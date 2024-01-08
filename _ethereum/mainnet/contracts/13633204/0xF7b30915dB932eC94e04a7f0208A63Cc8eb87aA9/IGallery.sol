// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./IERC721.sol";

interface IGallery is IERC721 {
    function mintNFT(address recipient) external returns (uint256);
    function totalSupply()  external returns (uint256);
}
