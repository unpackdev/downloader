// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract NFT721A is ERC721A, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) internal mintCountMap;
    bool mintAvailable = false;
    string public baseUri;
    uint256 public maxCount = 6464;
    uint256 public individualMintLimit = 20;

    constructor() ERC721A("xia-one", "XIA-ONE") {}

    //******SET UP******
    function setMaxCount(uint256 _maxCount) public onlyOwner {
        maxCount = _maxCount;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseUri = _newURI;
    }

    function setIndividualMintLimit(uint256 _individualMintLimit) public onlyOwner {
        individualMintLimit = _individualMintLimit;
    }

    function setMintAvailable(bool _mintAvailable) public onlyOwner {
        mintAvailable = _mintAvailable;
    }

    //******END SET UP******

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function mint(uint256 quantity) external {
        require(mintAvailable, "Mint not available!");
        require(
            _nextTokenId() + quantity <= maxCount,
            "Not enough stock!"
        );
        require(
            mintCountMap[msg.sender] + quantity <= individualMintLimit,
            "You have reached individual mint limit!"
        );

        _safeMint(msg.sender, quantity);
        mintCountMap[msg.sender] = mintCountMap[msg.sender] + quantity;
    }

    function airdrop(address to, uint256 quantity) public onlyOwner {
        require(quantity > 0, "The quantity is less than 0!");
        require(
            _nextTokenId() + quantity <= maxCount,
            "The quantity exceeds the stock!"
        );
        _safeMint(to, quantity);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }
}