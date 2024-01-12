// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract justajpeg is ERC721A, Ownable {
    using Strings for uint;
    uint public maxMintAmountPerTxn = 5;
    uint public maxFreeMintPerWalletAmount = 1;
    uint public maxSupply = 5555;
    uint public mintPrice = 0.003 ether;
    bool public paused = true;
    mapping(address => uint) private _walletMintedCount;

    string public baseURI = "";

    constructor() ERC721A("Is this just a jpeg", "itjjpeg") {}

    function mintedCount(address owner) external view returns (uint) {
        return _walletMintedCount[owner];
    }

    function devMint(address to, uint count) external onlyOwner {
		require(_totalMinted() + count <= maxSupply, 'Exceeds max supply');
		_safeMint(to, count);
	}


    function mint(uint count) external payable {
      require(!paused, 'Sales are off');
      require(count <= maxMintAmountPerTxn, 'Exceeds NFT per transaction limit');
      require(_totalMinted() + count <= maxSupply, 'Exceeds max supply');

      uint payForCount = count;
      uint mintedSoFar = _walletMintedCount[msg.sender];
      if(mintedSoFar < 1) {
        uint remainingFreeMints = 1 - mintedSoFar;
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

    function setMaxMints(uint256 _maxMintAmountPerTxn) public onlyOwner {
        maxMintAmountPerTxn = _maxMintAmountPerTxn;
    }

    function setMaxFreeMint(uint256 _maxFreeMintPerWalletAmount) public onlyOwner {
        maxFreeMintPerWalletAmount = _maxFreeMintPerWalletAmount;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }
}