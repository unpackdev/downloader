// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ERC721Burnable {
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface LazyAirdrop {
    function airdrop(
        address creatorContractAddress,
        uint256 instanceId,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external;
}

contract BurnAirdrop {
    address private core = 0x6D90aA894d7C845c248c8866aA246ac378aA15bf;
    address private burnable = 0x670EaB9e367a2f51441Fce97A4a809437ffE8181;
    address private lazyAirdrop = 0xDb8d79C775452a3929b86ac5DEaB3e9d38e1c006;

    function burnAirdrop(uint256 instanceId, uint256[] calldata amounts, uint256 tokenIdToBurn) public {
        require(amounts.length == 1, "BurnAirdrop: Only one token can be redeemed at a time");

        address tokenOwner = ERC721Burnable(burnable).ownerOf(tokenIdToBurn);
        address[] memory tokenOwners = new address[](1);
        tokenOwners[0] = tokenOwner;

        ERC721Burnable(burnable).burn(tokenIdToBurn);
        LazyAirdrop(lazyAirdrop).airdrop(core, instanceId, tokenOwners, amounts);
    }
}