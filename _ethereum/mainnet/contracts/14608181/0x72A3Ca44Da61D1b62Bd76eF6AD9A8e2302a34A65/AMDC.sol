// Alkie Monk Drinking Group is a sustainable, 
// long term NFT project built for alcohol lovers.
// Website : https://alkiemonkdrinking.club
// Linktr  : https://linktr.ee/alkiemonkdrinkingclub


pragma solidity ^0.8.0;


import "./Ownable.sol";
import "./ERC721A.sol";

contract AMDC is ERC721A ,Ownable  {

    
    using Strings for uint256;
    uint256 public immutable amountForDevs;
    uint256 public salephase;
    uint256 public Salestime; //1651309200= 4-30 1500 GMT+8
    uint256 public maxsupply = 5000;
    uint256 public salesprice; //100000000000000000 = 0.1eth
    uint256 public mintlimit;
    uint256 public phasemax;
    string private _baseURIextended ='https://alkiemonkdrinking.club/blindbox/';
    bool public wlRequired;
    string[5] private revealURI;
    address payable public shareholderAddress;
    address payable public treasuryAddress;
    


    constructor() ERC721A("Alkie Monk Drinking Club", "AMDC",10,maxsupply) {
       
        shareholderAddress = payable(msg.sender);
        amountForDevs=300;
        salephase = 0;
        Salestime = 1651309200;
        salesprice = 100000000000000000;
        wlRequired = true;
    }

    function mint(uint numberOfTokens, uint256 amount, uint256 nonce, bytes memory signature) public payable {
        require( block.timestamp >= Salestime , "Sales not start yet");
        require( salephase >0, "salephase must be active.");
        require( mintlimit >= numberOfTokens , "Exceeded max token purchase");
        require( maxsupply >= totalSupply() + numberOfTokens , "Purchase would exceed max supply of tokens");
        require( msg.value >= salesprice * numberOfTokens , "Ether value sent is not correct");
        require( submitOrder(msg.sender,amount,nonce,signature), " whitelisted members only!");

        phasemax = salephase * 1000;
        require( phasemax >= totalSupply() + numberOfTokens , "Purchase would exceed Phase max");

        _safeMint(msg.sender, numberOfTokens);
         
    }


    function submitOrder(address owner, uint256 amount, uint256 nonce, bytes memory signature) internal pure returns(bool) {
        
        bytes32 hash = keccak256(abi.encodePacked(owner, amount, nonce));
        address signer = recover(hash,signature);
        if(signer == owner){return true;}else{return false;}


        
    }
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
        return (address(0));
        }
        assembly {
        r := mload(add(signature, 0x20))
        s := mload(add(signature, 0x40))
        v := byte(0, mload(add(signature, 0x60)))
        }
        if (v < 27) {
        v += 27;
        }
        if (v != 27 && v != 28) {
        return (address(0));
        } else {
        return ecrecover(hash, v, r, s);
        }
    }



    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }
    function showBaseURI() view public returns (string memory){
        return _baseURIextended;
    }
    function setSalestime(uint256 _timer) external onlyOwner() {
        Salestime = _timer;
    }
 
    function setRevealURI(uint256 mudphase,string memory _muduri) external onlyOwner() {
        revealURI[mudphase] = _muduri;
    }
    function showRevealURI(uint256 _phase) view external onlyOwner() returns (string memory){
        return revealURI[_phase];
    }




    function setPrice(uint _myprice) public onlyOwner() {
        salesprice = _myprice;
    }
    function setmintlimit(uint _limit) public onlyOwner() {
        mintlimit = _limit;
    }

    function setwlRequired (bool _wlRequired) public onlyOwner(){
        wlRequired = _wlRequired;
    }


    
    // For marketing etc.
    function devMint(uint256 quantity) external onlyOwner {
        require(
        totalSupply() + quantity <= amountForDevs,
        "too many already minted before dev mint"
        );
        require(
        quantity % maxBatchSize == 0,
        "can only mint a multiple of the maxBatchSize"
        );
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
        _safeMint(msg.sender, maxBatchSize);
        }
    }



    function setSalephase(uint256 newPhase) public onlyOwner() {
        salephase = newPhase;
    }

    function tokenURI(uint256 tokenId)public view virtual override returns (string memory){
            
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
            string memory strid=tokenId.toString();
            if(tokenId>=0 && tokenId<=999 && bytes(revealURI[0]).length>0){
                return string(abi.encodePacked(revealURI[0], strid));
            } else if  (tokenId>=1000 && tokenId<=1999 && bytes(revealURI[1]).length>0){
                return string(abi.encodePacked(revealURI[1], strid));
            } else if  (tokenId>=2000 && tokenId<=2999 && bytes(revealURI[2]).length>0){
                return string(abi.encodePacked(revealURI[2], strid));
            } else if  (tokenId>=3000 && tokenId<=3999 && bytes(revealURI[3]).length>0){
                return string(abi.encodePacked(revealURI[3], strid));
            } else if  (tokenId>=4000 && tokenId<=4999 && bytes(revealURI[4]).length>0){
                return string(abi.encodePacked(revealURI[4], strid));
            } else {
                
                return bytes(showBaseURI()).length != 0 ? string(abi.encodePacked(showBaseURI(), strid)) : '';
            }
        
    }

    function setAddress(address payable _teamAddress,address payable _treasureAddress)public onlyOwner{
        shareholderAddress=_teamAddress;
        treasuryAddress=_treasureAddress;
    }

    function withdraw() public onlyOwner {
        require (treasuryAddress != 0x0000000000000000000000000000000000000000,'Wrong treasury address');
        uint256 balance = address(this).balance;
        if (balance % 2 == 1)   //money is an odd number, make it even
        {balance=balance-1;}
        Address.sendValue(shareholderAddress, balance/2);
        Address.sendValue(treasuryAddress, balance/2);
    }


}
// SPDX-License-Identifier: MIT
