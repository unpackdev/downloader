pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract DoKwoblins is ERC721A, Ownable, ReentrancyGuard {
    string public baseURI;
    uint256 public maxPerAddress = 69;
    bool public mintEnabled = false;
    uint256 maxSupply = 10000;
    mapping (address => uint256) public numMintedPerAddress;


    constructor() ERC721A("Do Kwoblins", "DOKWOBLINS") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function mint(uint256 _quantity) external nonReentrant {
  	    uint256 totalMinted = totalSupply();
        require(mintEnabled, "Mint not enabled yet");
        require(totalMinted + _quantity <= maxSupply, "cannot mint more than maxSupply of 10000");
        require(msg.sender == tx.origin, "No bots please");
        // prevent overflow
    	require (_quantity <= maxPerAddress, "Don't be greedy! No more than 69 per address!");
    	require (numMintedPerAddress[msg.sender] + _quantity <= maxPerAddress, "Don't be greedy! No more than 69 per address!");
        _safeMint(msg.sender, _quantity);
        numMintedPerAddress[msg.sender] += _quantity;
        // [msg.sender] += goblinbyebye;
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
    }

    function mintHonoraries(address _destAddress, uint256 _nKwoblins) public onlyOwner {
        uint256 totalMinted = totalSupply();
        require(totalMinted + _nKwoblins <= maxSupply);
        _safeMint(_destAddress, _nKwoblins);
    }

    function setMintStatus(bool _status) external onlyOwner {
        mintEnabled = _status;
    }

    function sumthinboutfunds() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}

}