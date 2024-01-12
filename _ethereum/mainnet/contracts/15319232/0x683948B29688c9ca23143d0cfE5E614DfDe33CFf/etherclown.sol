// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract etherclown is ERC721A, Ownable {
    uint256 public maxSupply = 1000;
    uint256 public mintPrice = 0.003 ether;
    bool public paused = true;
    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmXvf9gNp9N2WvR7q7ZV32BWe2eH8NZgM86hFbrduT4y3E/";
    mapping(address => uint) private _walletMintedCount;

    constructor() ERC721A("EtherClowns", "ETHC") {}

    function mintTo(address to, uint256 count) external onlyOwner {
		require(_totalMinted() + count <= maxSupply, 'Too much');
		_safeMint(to, count);
	}

        function mint(uint256 count) external payable {
      require(!paused, 'Paused');
      require(count <= 5, 'Too many amount');
      require(_totalMinted() + count <= maxSupply, 'Sold out');
      uint256 price = 0;
      if(_totalMinted() + count <= 700 && _walletMintedCount[msg.sender] + count <= 5) {
        price = 0;
      }
      else {
        price = mintPrice;
      }
        require(msg.value >= count * price, 'Not enough balance');
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
}