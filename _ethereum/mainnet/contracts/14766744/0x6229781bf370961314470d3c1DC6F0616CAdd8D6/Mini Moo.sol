// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);

}



contract MiniMoo is ERC721A, Ownable,ReentrancyGuard {
    using Strings for uint256;

    //Basic Configs
    uint256 public maxSupply = 10000;
    uint256 public _price = 0.02 ether;
    

    //Reveal/NonReveal
    string public _baseTokenURI;
    string public _baseTokenEXT;
    string public notRevealedUri = "https://ipfs.io/ipfs/QmTjDe8WhY1rAjHKbng9sY9xTCmoA5GPahX7XJNqWSnvPJ";
    bool public revealed = false;
    bool public _paused = true;
    uint256 public _reserved = 150;
    uint256 public airDropCount =0;


    //PRESALE MODES
    uint256 public whitelistMaxMint = 10;
    bytes32 public merkleRoot = 0x4c640570a0581d3bed72fb50ac1287c67251a7016ae513b8361e3a061cc1f5b6;
    bytes32 public freeeMintMerkle = 0x4c640570a0581d3bed72fb50ac1287c67251a7016ae513b8361e3a061cc1f5b6;
    bool public whitelistSale = true;
    uint256 public whitelistPrice = 0.04 ether;

    //APECOIN Config
    uint256 public ercCost = 1 ether;
    uint256 public ercWhitelistCost = 0.5 ether;
    address public tokenAddress = 0x4d224452801ACEd8B2F0aebE155379bb5D594381;


    struct MintTracker{
        uint256 _whitelist;
        uint256 _freemint;
    }
    mapping(address => MintTracker) public _totalMinted;

    constructor() ERC721A("MiniMoo", "Moo") {}

    function mint(uint256 _mintAmount,uint256 paymentMode) public payable nonReentrant {
        require(tx.origin == msg.sender,"Contract Calls Not Allowed");
        require(!_paused,"Contract Minting Paused");
        require(!whitelistSale, ": Cannot Mint During Whitelist Sale");
        require(_mintAmount > 0, ": Amount should be greater than 0.");
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply - _reserved , ": No more NFTs to mint, decrease the quantity or check out OpenSea.");
        if(paymentMode == 0){
            require(msg.value >= _price * _mintAmount,"Insufficient FUnd");
        }
        else {
            IERC20 erc20Coin  = IERC20(tokenAddress);
            require(erc20Coin.balanceOf(msg.sender) >= _mintAmount * ercCost ,"You do not have enough ApeCoin.");
            require(erc20Coin.allowance(msg.sender,address(this)) >= _mintAmount * ercCost,"Please Approve Contract to Spend Some of Your Ape Coins");
            erc20Coin.transferFrom(msg.sender, address(this), _mintAmount * ercCost);
        }
        _safeMint(msg.sender, _mintAmount);
    }
    
    function whiteListMint( uint256 _mintAmount,bytes32[] calldata _merkleProof,uint256 paymentMode) public payable nonReentrant {
        require(tx.origin == msg.sender,"Contract Calls Not Allowed");
        require(!_paused,"Contract Minting Paused");
        require(whitelistSale, ": Whitelist is paused.");
        require(_mintAmount > 0, ": Amount should be greater than 0.");
        require(_mintAmount+_totalMinted[msg.sender]._whitelist <= whitelistMaxMint ,"You cant mint more,Decrease MintAmount or Wait For Public Mint" );
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "You are Not whitelisted");
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply -_reserved , ": No more NFTs to mint, decrease the quantity or check out OpenSea.");
        if(paymentMode == 0){
            require(msg.value >= whitelistPrice * _mintAmount,"Insufficient FUnd");
        }
        else {
            IERC20 erc20Coin  = IERC20(tokenAddress);
            require(erc20Coin.balanceOf(msg.sender) >= _mintAmount * ercWhitelistCost ,"You do not have enough ApeCoin.");
            require(erc20Coin.allowance(msg.sender,address(this)) >= _mintAmount * ercWhitelistCost,"Please Approve Contract to Spend Some of Your Ape Coins");
            erc20Coin.transferFrom(msg.sender, address(this), _mintAmount * ercWhitelistCost);
        }
        _safeMint(msg.sender, _mintAmount);
        _totalMinted[msg.sender]._whitelist+=_mintAmount;
    }


    function freeMint(bytes32[] calldata _merkleProof) public payable nonReentrant{
        require(tx.origin == msg.sender,"Contract Calls Not Allowed");
        require(!_paused,"Contract Minting Paused");
        require(whitelistSale, ": Whitelist is paused.");
        require(_totalMinted[msg.sender]._freemint < 1 ,"You cant mint more,Decrease MintAmount or Wait For Public Mint" );
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, freeeMintMerkle, leaf), "You are Not whitelisted");
        uint256 supply = totalSupply();
        require(supply + 1 <= maxSupply -_reserved , ": No more NFTs to mint, decrease the quantity or check out OpenSea.");
        _safeMint(msg.sender, 1);
        _totalMinted[msg.sender]._freemint+=1;
    }

    function _airdrop(uint256 amount,address _address) public onlyOwner {
        require(airDropCount+amount <= _reserved , "Airdrop Limit Drained!");
        _safeMint(_address, amount);
        airDropCount+=amount;
    }


    function startPublicSale() public onlyOwner{
        _paused = false;
        whitelistSale = false;
    }



    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (revealed == false) {
            return notRevealedUri;
        } else {
            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),_baseTokenEXT)) : "";
        }
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function toogleWhiteList() public onlyOwner{
        whitelistSale = !whitelistSale;

    }
    function toogleReveal() public onlyOwner{
        revealed = !revealed;
    }

    function tooglePause() public onlyOwner{
        _paused = !_paused;
    }

    function changeURLParams(string memory _nURL, string memory _nBaseExt) public onlyOwner {
        _baseTokenURI = _nURL;
        _baseTokenEXT = _nBaseExt;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        _price = newPrice;
    }

    function setWLPrice(uint256 newPrice) public onlyOwner {
        whitelistPrice = newPrice;
    }

    function setMerkleRoot(bytes32 merkleHash) public onlyOwner {
        merkleRoot = merkleHash;
    }

    function setFreeMintMerkle(bytes32 merkleHash) public onlyOwner {
        freeeMintMerkle = merkleHash;
    }

    function ercBalance() public view returns(uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
    

    function withdrawMoney(address _sendto) external onlyOwner nonReentrant {
        (bool success, ) =_sendto.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setErcPaymentConfig(uint256 _publicCost , uint256 _whitelistCost,address erc20Address) external onlyOwner {
        ercCost = _publicCost;
        ercWhitelistCost = _whitelistCost;
        tokenAddress = erc20Address;
    }

    function withdrawErc(address _sendto) external onlyOwner nonReentrant {
        uint256 balance = ercBalance();
        require( balance > 0,"Insufficient Fund");
        IERC20(tokenAddress).transfer(_sendto,balance);
    }
    
}