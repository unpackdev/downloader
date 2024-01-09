// SPDX-License-Identifier: MIT

// █▀▀ █▀█ ▄▀█ █▄░█ █▀▄   █▄▄ ▄▀█ ▀█ ▄▀█ ▄▀█ █▀█
// █▄█ █▀▄ █▀█ █░▀█ █▄▀   █▄█ █▀█ █▄ █▀█ █▀█ █▀▄

//@author GB Team
//@title The Paradise Palaces Contract

pragma solidity ^0.6.6;

import "./ERC721.sol";
import "./Ownable.sol";



contract GBPalaces is Ownable, ERC721 {

    string public _baseTokenURI;
    uint256[] public palaces;
    uint nonce;

    uint256 public constant PUBLIC_PRICE = 0.038 ether;
    uint256 public constant WHITELIST_PRICE = 0.032 ether;
    uint256 public constant RUGLIST_PRICE = 0.025 ether;

    bool public publicSaleActive = false;
    bool public rugListSaleActive = false;


    mapping(address => bool) private rugList;
    mapping(address => bool) private whiteList;


    //@dev constructor simply sets the basetokenURI
    constructor() public
    ERC721("GrandBazaarPalace", "PALACE") {
        _baseTokenURI = "https://gateway.pinata.cloud/ipfs/QmQ2S2DexGfjLZ1z4tpN64UcfRvywvAoYCwj1YLgoPEN5Q/";
    }   

    //@dev sets public mint boolean state
    function setPublicMintActive(bool _setPublicMint) public onlyOwner{
        publicSaleActive = _setPublicMint;
    }

    //@dev checks if public sale is active
    function checkPublicMintIsActive() external view returns( bool ){
        return publicSaleActive;
    }

    //@dev sets ruglist mint boolean state
    function setRugListMintActive(bool _setRugListMint) public onlyOwner{
        rugListSaleActive = _setRugListMint;
    }

    //@dev checks if rug list sale is active
    function checkRugListMintIsActive() external view returns( bool ){
        return rugListSaleActive;
    }

    //@dev function for setting ruglist addresses
    function setRugList(address[] calldata addresses, bool setBoolean) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            rugList[addresses[i]] = setBoolean;
        }
    }

    //@dev for checking if an address is in the ruglist
    function checkRugList(address addr) external view returns (bool) {
        return rugList[addr];
    }

    //@dev for setting whitelist addresses
    function setWhiteList(address[] calldata addresses, bool setBoolean) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whiteList[addresses[i]] = setBoolean;
        }
    }

    //@dev for checking if an address is in the whitelist
    function checkWhiteList(address addr) external view returns (bool) {
        return whiteList[addr];
    }



    //@dev the mint function, a few requirements to mint 
    function mint(uint8 numToMint) 
    external payable {
        uint totalMinted = totalSupply();
        require( numToMint <= 20, "you can only mint 20 tokens at one time");
        require( publicSaleActive, "minting has not begun for the public yet" );
        require( totalMinted + numToMint <= 7777, "This NFT is sold out!" );
        require( uint8(balanceOf(msg.sender)) + numToMint <= 50, "You are attemping to mint more tokens than you are able" ); 
        require( msg.value >= PUBLIC_PRICE * numToMint, "Minting this NFT costs 0.038 ether per token for public minters" ); 

        for(int i = 0; i < numToMint; i++){
            uint256 randomNumber = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce)));
            nonce++;
            uint newId = palaces.length;
            palaces.push(randomNumber);
            _safeMint(msg.sender, newId);
        }
    }

    //@dev the mint function for ruglisters, a few requirements to mint 
    function rugMint(uint8 numToMint) 
    external payable {
        uint totalMinted = totalSupply();
        require( rugListSaleActive, "minting has not begun yet" );
        require( numToMint <= 20, "you can only mint 20 tokens at one time");
        require( rugList[msg.sender], "You are not on the ruglist" );
        require( totalMinted + numToMint <= 7777, "This NFT is sold out!" );
        require( msg.value >= RUGLIST_PRICE * numToMint, "Minting this NFT costs 0.025 ether per token for public minters" ); 

        for(int i = 0; i < numToMint; i++){
            uint256 randomNumber = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce)));
            nonce++;
            uint newId = palaces.length;
            palaces.push(randomNumber);
            _safeMint(msg.sender, newId);
        }
    }

    //@dev the mint function for whitelisters, a few requirements to mint 
    function whiteListMint(uint8 numToMint) 
    external payable {
        uint totalMinted = totalSupply();
        require( publicSaleActive, "minting has not begun for the public yet" );
        require( numToMint <= 20, "you can only mint 20 tokens at one time");
        require( whiteList[msg.sender], "You are not on the whitelist" );
        require( totalMinted + numToMint <= 7777, "This NFT is sold out!" );
        require( uint8(balanceOf(msg.sender)) + numToMint <= 50, "You are attemping to mint more tokens than you are able"); 
        require( msg.value >= WHITELIST_PRICE * numToMint, "Minting this NFT costs 0.032 ether per token for public minters" ); 

        for(int i = 0; i < numToMint; i++){
            uint256 randomNumber = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce)));
            nonce++;
            uint newId = palaces.length;
            palaces.push(randomNumber);
            _safeMint(msg.sender, newId);
        }
    }

        //@dev for setting the baseURI on IPFS push
        function setBaseTokenURI(string memory URI) public onlyOwner {
            _baseTokenURI = URI;
        }

        //@dev function that returns baseURI 
        function baseURI() public view virtual override returns (string memory) {
            return _baseTokenURI;
        }

        //@dev overriding default OZ function that concatenates token ID and base URI to also add ".json"
        function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
            string memory _baseURI = baseURI();
            string memory _tokenURI = string(abi.encodePacked(_baseURI, tokenId.toString()));
            return string(abi.encodePacked(_tokenURI, ".json"));
        }

        //@dev function to reserve a certain amount of NFT's for giveaways and the like
        function reserve(uint256 n) public onlyOwner {
            uint supply = totalSupply();
            uint j;
            for (j = 0; j < n; j++) {
                uint256 randomNumber = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce)));
                nonce++;
                palaces.push(randomNumber);
                _safeMint(msg.sender, supply + j);
            }
        }

        //@dev function to reserve a certain amount of NFT's for giveaways and the like
        function customMint(uint256 n) public onlyOwner {
            uint supply = totalSupply();
            uint j;
            for (j = 0; j < n; j++) {
                palaces.push(j);
                _safeMint(msg.sender, supply + j);
            }
        }

        //@dev sets tokenURI in unforseen case where an indidual palace may need to be altered
        function setTokenURI(uint256 tokenId, string memory _tokenURI)  public onlyOwner{
            _setTokenURI(tokenId, _tokenURI);
        }

        //@dev withdraws contract's ether balance into owner wallet 
        function withdraw()  public onlyOwner{
            address payable companyWallet = 0xF82050a46c97731D75Fa1c9d2375d34c1Cf8b75d;
            companyWallet.transfer(address(this).balance);
        }


}