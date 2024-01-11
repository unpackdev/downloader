pragma solidity ^0.8.10;
//SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSA.sol";

contract DogeBall is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private _maxTokens = 10000;
    uint256 public _price = 30000000000000000; // 0.03 ETH
    bool private _saleActive = false;

    address _verifyingAccount = 0x072356aD778351fd0cD08Ba57Dee85CDcea4F7D6;

    string public _prefixURI = "https://dogeball.game/metadata/";

    mapping(address => bool) private _hasFreeMinted;


    constructor() ERC721("DogeBall", "DOGEB") 
    {
    }


    //view functions
    function _baseURI() internal view override returns (string memory) {
        return _prefixURI;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function Sale() public view returns (bool) {
        return _saleActive;
    }

    function numSold() public view returns (uint256) {
        return _tokenIds.current();
    }

    function displayMax() public view returns (uint256) {
        return _maxTokens;
    }

    function getAllOwners() public view returns (address[] memory) {
        address[] memory owners = new address[](totalSupply());
        if (totalSupply() > 0){
            for (uint256 i = 0; i < totalSupply(); i++) {
                owners[i] = ownerOf(i+1);
            }
        }
        return owners;
    }


    function getSomeOwners(uint start, uint end) public view returns (address[] memory) {
        address[] memory owners = new address[](end - start + 1);
        if (totalSupply() > 0){
            for (uint256 i = start - 1; i < end; i++) {
                owners[i] = ownerOf(i+1);
            }
        }
        return owners;
    }

    function hasAddressFreeMinted(address _addr) public view returns (bool) {
        return _hasFreeMinted[_addr];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId));

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ""
                    )
                )
                : "";
    } 

    //variable changing functions

    function changeMax(uint256 _newMax) public onlyOwner {
        _maxTokens = _newMax;
    }

    function toggleSale() public onlyOwner {
        _saleActive = !_saleActive;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _prefixURI = _uri;
    }

    function changeVerifyingAccount(address _newVerifier) public onlyOwner {
        _verifyingAccount = _newVerifier;
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        _price = _newPrice;
    }

    //off-chain whitelist verification code
    using ECDSA for bytes32;

    function verifyAccountWithSignature(address message, bytes memory signedMessage) public view returns (bool) {
        return keccak256(abi.encodePacked(message))
        .toEthSignedMessageHash()
        .recover(signedMessage) == _verifyingAccount;
    }


    function hashAddress(address _addr) public pure returns (bytes32){
        return(keccak256(abi.encodePacked(_addr)));
    }


    //onlyOwner contract interactions

    function reserveTo(uint256 quantity, address _addr) public onlyOwner {
        for (uint256 i = 0; i < quantity; i++) {
            _mintItem(_addr);
        }
    }

    function withdraw(address payee) public payable onlyOwner {
        require(payable(payee).send(address(this).balance));
    }

    //minting functionality

    function authMint(bytes memory signedMessage) public {
        require(_saleActive);
        require(verifyAccountWithSignature(msg.sender,signedMessage),"not whitelisted");

        require(!_hasFreeMinted[msg.sender], "Has already free-minted...");
        

        uint256 totalMinted = _tokenIds.current();
        require(totalMinted + 1 <= _maxTokens);

        _mintItem(msg.sender);

        _hasFreeMinted[msg.sender] = true;
    }

    function mintItems(uint256 amount) public payable {
        require(_saleActive);

        uint256 totalMinted = _tokenIds.current();
        require(totalMinted + amount <= _maxTokens);

        require(msg.value >= amount * _price);

        for (uint256 i = 0; i < amount; i++) {
            _mintItem(msg.sender);
        }
    }

    function _mintItem(address to) internal returns (uint256) {
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _mint(to, id);

        return id;
    }

}
