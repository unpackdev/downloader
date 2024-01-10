// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IENSTogetherNFT {
    function mint(
        address from,
        address to,
        string calldata ens1,
        string calldata ens2
    ) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function ownedNFTS(address _owner) external view returns (uint256[] memory);

    function burn(uint256 tokenId, address _add) external;
}
