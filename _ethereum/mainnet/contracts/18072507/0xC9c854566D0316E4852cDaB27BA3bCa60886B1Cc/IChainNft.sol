// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {IERC721Enumerable} from "IERC721Enumerable.sol";

import {IChainRegistry} from "IChainRegistry.sol";

type NftId is uint96;

using {
    eqNftId as ==,
    neNftId as !=
}
    for NftId global;

function eqNftId(NftId a, NftId b) pure returns(bool isSame) { return NftId.unwrap(a) == NftId.unwrap(b); }
function neNftId(NftId a, NftId b) pure returns(bool isDifferent) { return NftId.unwrap(a) != NftId.unwrap(b); }
function gtz(NftId a) pure returns(bool) { return NftId.unwrap(a) > 0; }
function zeroNftId() pure returns(NftId) { return NftId.wrap(0); }

function toNftId(uint256 tokenId) pure returns(NftId) { return NftId.wrap(uint96(tokenId)); }

interface IChainNft is 
    IERC721Enumerable 
{

    function mint(address to, string memory uri) external returns(uint256 tokenId);
    function burn(uint256 tokenId) external;
    function setURI(uint256 tokenId, string memory uri) external;

    function getRegistry() external view returns(IChainRegistry registry);
    function exists(uint256 tokenId) external view returns(bool);
    function totalMinted() external view returns(uint256);

    function implementsIChainNft() external pure returns (bool);
}
