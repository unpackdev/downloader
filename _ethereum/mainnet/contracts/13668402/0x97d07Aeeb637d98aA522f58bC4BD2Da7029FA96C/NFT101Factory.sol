//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./NFT101.sol";
import "./Ownable.sol";

contract NFT101Factory is Ownable {
    mapping(address => address) public nft101s;

    event NewNFT101(address indexed creator, address indexed nft101);

    function mintOneOfOne(
        string memory $name,
        string memory $symbol,
        address $minter,
        uint256 $tokenId,
        string memory $uri
    ) external onlyOwner returns (address) {
        NFT101 nft101 = new NFT101($name, $symbol, msg.sender, $minter, $tokenId, $uri);
        nft101s[address(nft101)] = msg.sender;
        emit NewNFT101(msg.sender, address(nft101));
        return address(nft101);
    }
}
