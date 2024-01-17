// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721A.sol";
import "./Ownable.sol";

contract pepeworks is ERC721A, Ownable {
    uint256 public maxSupply = 2222;
    uint256 constant public maxMintAmountPerTxn = 5;
	uint256 constant public maxFreePerWallet = 5;
	uint256 constant public freeSupply = 1500;
    uint256 constant public mintPrice = 0.003 ether;
    bool public paused = true;
    string public baseURI = "";
    mapping(address => uint) private _walletMintedCount;

    constructor() ERC721A("Pepe Works", "PEWO") {}

    function mintTo(address to, uint256 count) external onlyOwner {
		require(_totalMinted() + count <= maxSupply, 'Too much');
		_safeMint(to, count);
	}

    function mint(uint256 count) external payable {
      require(!paused, 'Paused');
      require(count <= maxMintAmountPerTxn, 'Too many amount');
      require(_totalMinted() + count <= maxSupply, 'Sold out');
      uint256 payedFor = count;
      uint256 minted = _walletMintedCount[msg.sender];
      uint256 remainingFree = 0;

      if(_totalMinted() + count <= freeSupply && minted < maxFreePerWallet){
        remainingFree = maxFreePerWallet - minted;
        if(count > remainingFree){
            payedFor = count - remainingFree;
        }
        else{
            payedFor = 0;
        }
      }

        require(msg.value >= mintPrice * payedFor, 'Not enough balance');
        _walletMintedCount[msg.sender] += count;
        _safeMint(msg.sender, count);
	}

    function mintedCount(address owner) external view returns (uint256) {
        return _walletMintedCount[owner];
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setPaused(bool _state) external onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }
}