// contracts/NftDresses.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";

contract LibresseDigitalDress is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint8 constant _maxCount = 25;

    string contentURI = "https://gateway.pinata.cloud/ipfs/QmTYuQkEQQwozG99HbDjbEUprQvE4vNqLNENe4nj7BDrQy";

    function mintNft(address receiver, string memory tokenURI)
        public
        returns (uint256)
    {
        uint256 nftTokenId = _tokenIds.current();
        require(nftTokenId < _maxCount, "Counter: maximum number of nft items");

        _tokenIds.increment();

        uint256 newNftTokenId = _tokenIds.current();
        _mint(receiver, newNftTokenId);
        _setTokenURI(newNftTokenId, tokenURI);

        return newNftTokenId;
    }

    constructor() ERC721("Libresse Digital Dress", "LDR") {
        mintNft(0x0E66cc02a1957ddFDA0DC49722E4329fE87F95Cf, contentURI);
        mintNft(0x03a9Fcb35283C9d54205f83fA36C50d5b808321a, contentURI);
        mintNft(0x28790E479911C5d21C660F6cAE30268a2Cb363f6, contentURI);
        mintNft(0x630C630BcDEe9f358F6D1A6c5542bd13D054fCD8, contentURI);
        mintNft(0x9843B1C53DA62104A3d29d35F5E74A111Be372ae, contentURI);
        mintNft(0x8Bd51FD91af9677e226AaDb4Ef6A16b228be20ea, contentURI);
        mintNft(0xFae7998107c554Ec98859a0C14666F35B065F0B7, contentURI);
        mintNft(0x5FdB0f5a26a0284c54bd5c8d6560abc33e528ed1, contentURI);
        mintNft(0x4593dd5c89AFBcBE4bc885Eb7bAB7f2Ff959cDa0, contentURI);
        mintNft(0x1b05b8c2A6b8eB885d237f7f88a24De280abe27b, contentURI);
        mintNft(0x87FB7784d1E4d40E2Ee6a06ABbDBE895c3bb5EfA, contentURI);
        mintNft(0xe89ADb25585B2f0ECBEC1ea0D72BE183320C46b6, contentURI);
        mintNft(0x13d4Cad3840DB77ECb64D0fce1b9094A79f9BaA9, contentURI);
        mintNft(0x781Da6fd9FdfD9201Fb78D2471f7EF29e90B1733, contentURI);
        mintNft(0xfE95356E6Cd5803610767913670E0F21B6bD5454, contentURI);
        mintNft(0x71d4870cb64f2Fb3Ba961993C71a8a54D2fee03e, contentURI);
        mintNft(0xdc4e2D0E7e7aDBEC26a088b1dDDc9736032180BF, contentURI);
        mintNft(0x430a5C888d8456896FB5d264c0C822897ff3544B, contentURI);
        mintNft(0xF3B98cCC0262122E9b68AE4FD48ea2D19Dc8Bf4a, contentURI);
        mintNft(0x3b0cfd435Ad3e6b8cC1A826bC969322272bD2A38, contentURI);
    }
}