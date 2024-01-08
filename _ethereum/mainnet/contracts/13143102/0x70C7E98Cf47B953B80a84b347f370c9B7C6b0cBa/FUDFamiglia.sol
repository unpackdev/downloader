/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./IFUDFamiglia.sol";



contract FUDFamiglia is ERC721Enumerable,Ownable,IFUDFamiglia {
    using Strings for uint256;

    bool mintActive=false;
    uint256 public _airdrop_giveaway_amount = 0;
    uint256 public _fudfSupply = 0;
    uint256 public _fudfPrice = 0; 

    uint256 _totalPresale=0;
    bool revealed = false;
    
    mapping(uint256 => string) private _tokenNames;
    mapping(string => bool) private _namesUsed;
    mapping(bytes32 => bool) public airdrop_giveaway_code;

    string private _BaseURI = '';
    string private _tokenRevealedBaseURI  = '';
    event Named(uint256 indexed index, string name);

    constructor(uint256 supply,uint256 price ,string memory provenence) public ERC721("FUDFamiglia","FUDFAM") {
        _fudfSupply = supply;
        _fudfPrice = price;
        _BaseURI= string(abi.encodePacked('https://www.fudfamiglia.com/', provenence, "/asset.php?token_Id="));
        mintActive=false;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');
        return string(abi.encodePacked(_BaseURI, tokenId.toString()));
    }
    
    function setBaseURI(string calldata URI) public onlyOwner {
        _BaseURI = URI;
    }
    

    
    function mintMafia(uint amount) external override payable {
           
        require(amount<11,"Amount is to much ");
        require(mintActive,"Mint Function is not Active yet");
        require(msg.value >= _fudfPrice * amount , "Ether value sent is not enough");
        uint256 bonus=0;
        if(amount == 10)
        {
            bonus=1;
        }
        uint256 total=amount+bonus;
        minting(total);
    }
    
    function giftMafia(address _to, uint amount) external override onlyOwner{
      
        require(totalSupply()+amount <= _fudfSupply, "Minting would exceed max supply");
        
        for(uint i = 0; i < amount; i++) {
            uint lastIndex = totalSupply();
            _mint(_to, lastIndex);
        }
    }
    
    function airdrop(string memory code) external override {
        bytes32 decode=byte_encrypt(STB(code));
        
        require(_airdrop_giveaway_amount > 0,"No giveway is available right now");
        require(airdrop_giveaway_code[decode],"A gift for this code does not exist");
        
        delete airdrop_giveaway_code[decode];
        _airdrop_giveaway_amount -= 1;
        minting(1);
    }


    function minting(uint amount) internal{
  
        require(totalSupply() + amount <= (_fudfSupply + 1 - _airdrop_giveaway_amount), "Minting would exceed max supply");
        
        for(uint i = 0; i < amount; i++) {
            uint lastIndex = totalSupply();
            _mint(msg.sender, lastIndex);
        }
    }
    
    function massiveCodeCreation(bytes32[] memory hashed_code) external override onlyOwner
    {
        require(totalSupply() +hashed_code.length <= _fudfSupply,"Codes would exceed max supply");

        for (uint256 i = 0; i < hashed_code.length; i++) {
            require(!airdrop_giveaway_code[hashed_code[i]],"Item with this code already exist");
            require(totalSupply() + 1  <= _fudfSupply,"Codes would exceed max supply");
            airdrop_giveaway_code[hashed_code[i]] = true;
            _airdrop_giveaway_amount += 1;
        }
        
    }
    function withdrawAll() external override onlyOwner 
    {
      uint256 balance = address(this).balance;

     payable(msg.sender).transfer(balance);
    }
    
    function withdraw(uint256 amount) external override onlyOwner 
    {
      uint256 balance = address(this).balance;

     payable(msg.sender).transfer(amount);
    }
    
    function disableAirdrop() external override onlyOwner {
        _airdrop_giveaway_amount = 0;
    }
    
    function STB(string memory stringkey) internal returns(bytes memory){
         bytes memory byteskey = bytes(stringkey);
         return byteskey;
    }
    
    function byte_encrypt(bytes memory byteskey) internal returns(bytes32 ){
        bytes32 bhash = sha256(byteskey);
        return bhash;
    }
    
    function revealAttribute(string memory baseURI) external override onlyOwner {
        revealed=true;
        _BaseURI = baseURI;
    }
    
    function setActive() external override onlyOwner{
        mintActive=true;
    }
    
    function setNonActive() external override onlyOwner{
        mintActive=false;
    }
    
    function setPrice(uint256 newprice) external override  onlyOwner{
        _fudfPrice=newprice;
    }
    
    function reserveIndexZero() external override  onlyOwner{
        _mint(msg.sender,0);
    }
    
    function price() public view virtual returns (uint256) {
        return _fudfPrice;
    }

    function max_supply() public view virtual returns (uint256) {
        return _fudfSupply;
    }
    
    function baseTokenURI() public view returns (string memory) {
        return _BaseURI;
    }
       function isNameUsed(string memory nameString) public view returns (bool) {
        return _namesUsed[toLower(nameString)];
    }
    
      function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    
     function setName(uint256 tokenId, string memory name) public {
        require(revealed, "!reveal");
        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "!token.owner");
        
        require(validateName(name) == true, "!name.valid");
        require(isNameUsed(name) == false, "name.used");
        if (bytes(_tokenNames[tokenId]).length > 0) {
            _namesUsed[toLower(_tokenNames[tokenId])] = false;
        }
        _namesUsed[toLower(name)] = true;
        _tokenNames[tokenId] = name;
        emit Named(tokenId, name);
    }
    
     function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 3) return false;
        if (b.length > 32) return false;
        if (b[0] == 0x20) return false;
        if (b[b.length - 1] == 0x20) return false;
        bytes1 lastChar = b[0];
        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];
            if (char == 0x20 && lastChar == 0x20) return false;
            if (
                !(char >= 0x41 && char <= 0x5A) &&
                !(char >= 0x61 && char <= 0x7A) &&
                !(char == 0x20)
            ) return false;
            lastChar = char;
        }
        return true;
    }
    
}