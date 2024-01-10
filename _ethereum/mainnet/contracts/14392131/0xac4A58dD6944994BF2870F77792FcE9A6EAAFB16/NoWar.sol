// SPDX-License-Identifier: UNLICENSES
pragma solidity ^0.8.11;

import "./ERC1155Supply.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract NoWarNFT is ERC1155Supply, Pausable, Ownable {
    string public name = "NoWar NFT";
    string public symbol = "NWNFT";
    uint256 public minMintableToken = 0;
    uint256 public maxMintableToken = 9;
    uint256 public minMintPrice = 0.01 ether;

    uint256 private nonce = 0;
    uint256 private mintBase = 25;
    uint256 private mintCount = 10;
    uint256 private mintBucket = 25**4;
    string private _license = "";

    mapping(uint256 => string) private _tokenURI;

    constructor(address _newowner) ERC1155("") {
        _transferOwnership(_newowner);
        _setTokenURI(0, "ipfs://QmUtot7eesxezsSg4AyeKNb4NQaxKyDv4A2EdhVxX8UW5j"); 
        _setTokenURI(1, "ipfs://QmVD8jDazoLqei4RHtZ2pjqyKQxp2H7Z9LSmtN6T79PEti"); 
        _setTokenURI(2, "ipfs://QmP39mJK1YZd6DQjPhH48v9CY7hb49z1aG2q9P1K2hKDYZ"); 
        _setTokenURI(3, "ipfs://Qma17x9eFPiVW8cZL5CbNav5aF4XLmGoHwtdxMAGDyXgEB"); 
        _setTokenURI(4, "ipfs://QmYdcSo8Y71ZzarxaRdxHuPe8MFCXZU4yRYNFc4K6ZfCxd"); 
        _setTokenURI(5, "ipfs://QmVyUBeuEM4ionHgJWkQs3ergKQXCS2aVp5sPNp4Q55ACt"); 
        _setTokenURI(6, "ipfs://Qmc9SiJU2VPC6cV9jv5GtuUFzaamTSFDBAT81nKFt67xKK"); 
        _setTokenURI(7, "ipfs://Qmeu1EnyCYsC8fEGiN1JBsxf2UdYDVHQ7eVFvvzm2LBJZp"); 
        _setTokenURI(8, "ipfs://QmRqMFCN6Q3crjNr1UMENaoXyZCgJHaLBbeCW6DGr7gs23"); 
        _setTokenURI(9, "ipfs://QmNupUDcsYALehUudSUFNs4mDbbVjccw128y2CGQG5xyEm"); 
    }

    function setMintParams(
        uint256 _min,
        uint256 _max,
        uint256 _minprice,
        uint256 _base
    ) public onlyOwner {
        require(_max >= _min);
        _setMintParams(_min, _max, _minprice, _base);
    }

    function _setMintParams(
        uint256 _min,
        uint256 _max,
        uint256 _minprice,
        uint256 _base
    ) internal {
        uint256 _mintCount = (_max + 1 - _min);
        require(_mintCount % 2 == 0, "Count should be even");

        minMintableToken = _min;
        maxMintableToken = _max;
        mintCount = _mintCount;
        mintBase = _base**2;
        mintBucket = mintBase**((mintCount>> 1) - 1);
        minMintPrice = _minprice;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory _newuri) public onlyOwner {
        _setURI(_newuri);
    }

    function setTokenURI(uint256 _id, string memory _uri) public onlyOwner {
        _setTokenURI(_id, _uri);
    }

    function _setTokenURI(uint256 _id, string memory _uri) internal {
        _tokenURI[_id] = _uri;
    }

    function setLicense(string memory _newlicense) public onlyOwner {
        _setLicense(_newlicense);
    }

    function _setLicense(string memory _newlicense) internal {
        _license = _newlicense;
    }

    function license() public view returns (string memory) {
        return _license;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        string memory tokenUri = _tokenURI[_id];
        if (bytes(tokenUri).length != 0) {
            return tokenUri;
        }
        return super.uri(_id);
    }

    function mint() public payable whenNotPaused {
        require(msg.value >= minMintPrice, "Insufficient funds!");
        nonce++;
        address _sender = _msgSender();
        uint256 _random = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    _sender,
                    nonce,
                    block.difficulty,
                    blockhash(block.number - 1)
                )
            )
        );
        uint256 x = ((((_random % mintBucket) * minMintPrice) / msg.value) *
            minMintPrice) / msg.value;
        uint256 y = mintCount-1;
        while (x > 0) {
            if (y > 2) y -= 2;
            x /= mintBase;
        }
        y -= 1- (((_random / mintBucket) % 3) % 2);
        y += minMintableToken;
        _mint(_sender, y, 1, "");
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
