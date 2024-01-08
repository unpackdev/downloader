//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

interface ICryptoProsciuttiDiParma {
    function mint(address _to, uint256 _tokenId) external;

    function totalSupply() external returns (uint256);
}
