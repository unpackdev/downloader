// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract TheMigrantsNft is ERC721A, Ownable {
    uint256 public maxMintAmountPerTxn = 10;
    uint256 public maxFreeMintPerWalletAmount = 1;
    uint256 public maxSupply = 6666;
    uint256 public mintPrice = 0.001 ether;
    bool public paused = true;
    mapping(address => uint) private _walletMintedCount;

    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmS2moBz1gSJaG9DVjztHctrGb7cchCYRKdMhCXAQaZFyQ/";

    constructor() ERC721A("The Migrants", "THEMIG") {}

    function mintedCount(address owner) external view returns (uint256) {
        return _walletMintedCount[owner];
    }

    function devMint(address to, uint256 count) external onlyOwner {
		require(_totalMinted() + count <= maxSupply, 'Exceeds max supply');
		_safeMint(to, count);
	}


    function mint(uint256 count) external payable {
      require(!paused, 'Sales are off');
      require(count <= maxMintAmountPerTxn, 'Exceeds NFT per transaction limit');
      require(_totalMinted() + count <= maxSupply, 'Exceeds max supply');

      uint256 payForCount = count;
      uint256 mintedSoFar = _walletMintedCount[msg.sender];
      if(mintedSoFar < 1) {
        uint256 remainingFreeMints = 1 - mintedSoFar;
        if(count > remainingFreeMints) {
            payForCount = count - remainingFreeMints;
        }
        else {
            payForCount = 0;
        }
      }

    require(msg.value >= payForCount * mintPrice, 'Ether value sent is not sufficient');

		_walletMintedCount[msg.sender] += count;
		_safeMint(msg.sender, count);
	}

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

      function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
}