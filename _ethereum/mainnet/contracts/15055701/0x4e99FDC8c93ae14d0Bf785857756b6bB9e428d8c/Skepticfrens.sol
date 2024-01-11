// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721AQueryable.sol";

contract Skepticfrens is
	ERC721AQueryable,
    Pausable,
    Ownable
{
	constructor() ERC721A("SkepticFrens", "SKCF") {}

    uint256 public price = 5000000000000000;
    uint256 public maxSupply = 10000;
    uint256 public maxMinting = 4;
    uint256 public maxMintPerWallet=8;
    uint256 public maxFreeMintPerWallet=2;
	string tokenUri;
    string baseUrl;
	uint256 tokenCounter;
	
    mapping(address => uint256) private free;
    mapping(address => uint256) public minted;
	

    function adminMint(uint256 quantity) external payable onlyOwner {
        _mint(msg.sender, quantity);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    //========================= Versioning start here
    
    function mint(uint256 quantity) external payable {
        require(totalSupply() <= maxSupply, "Minting Ends");
        require(tokenCounter <= maxSupply, "Tokens are out there now");
        require(
            quantity <= maxMinting,
            "Minting need to be less then maxMinting"
        );
        require(
            _numberMinted(msg.sender) + quantity <= maxMintPerWallet,
            "Too many mint for an address"
        );
        require(
            minted[msg.sender] <= maxMintPerWallet,
            "Only 10 allowed per mint"
        );

        if (
            free[msg.sender] + quantity <= maxFreeMintPerWallet
        ) {

            _mint(msg.sender, quantity);
			
            minted[msg.sender] += quantity;
            free[msg.sender] += quantity;

            tokenCounter++;
        } else if (
            free[msg.sender] <= maxFreeMintPerWallet &&
            quantity <= maxMintPerWallet
        ) {
            uint256 currentFreeMint = maxFreeMintPerWallet - free[msg.sender];
            require(
                price * (quantity - currentFreeMint) <= msg.value,
                "Ether value sent is not correct"
            ); 
            _mint(msg.sender, quantity);

            minted[msg.sender] += quantity;
            free[msg.sender] = currentFreeMint + free[msg.sender];

            tokenCounter += quantity;
        } else {
            require(
                price * quantity <= msg.value,
                "Ether value sent is not correct"
            );
            _mint(msg.sender, quantity);
            minted[msg.sender] += quantity;
			
            tokenCounter += quantity;
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
        string memory prefix = ".json";
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(_tokenId)))
                : string(
                    abi.encodePacked(baseUrl, _toString(_tokenId), prefix)
                );
    }

    function setBaseUrl(string memory _uri) public onlyOwner {
        baseUrl = _uri;
    }

    function getFreeMint(address _address) external view returns (uint256) {
        return free[_address];
    }

}
