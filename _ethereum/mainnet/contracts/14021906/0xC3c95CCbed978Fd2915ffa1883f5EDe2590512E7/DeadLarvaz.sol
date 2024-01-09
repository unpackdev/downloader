pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract Deadlarvaz is ERC721A,Ownable{

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bool openForMint=false;
	uint256 public _larvazPrice = 0.03 ether; 
    uint256 public larvazSupply =6666;
    uint public freesupply=666;
	bool unveil = false;
    bool openForFree=false;
	string private _BaseURI = '';
    string private _tokenRevealedBaseURI  = '';
    mapping(address => uint256) private _claimed;
    
    constructor(  uint256 maxBatchSize_, uint256 collectionSize_) ERC721A("Deadlarvaz","DLZ",  maxBatchSize_, collectionSize_) {
        _BaseURI = '';
    }
    
    function mintlarvaz(uint amount) external payable {
        require(msg.value >= _larvazPrice * amount , "Ether value sent is not enough");
        require(openForMint,"Mint Function is not Active yet");
        require(totalSupply()+amount<=larvazSupply,"All minted");
        require(amount>0,"Cannot mint 0 or below 0");
         require(amount<=15,"Cannot mint over 15");
        _safeMint(msg.sender,amount);
    }
    
    function freeMint(uint amount) external payable {
        require(amount>0,"Cannot mint 0 or below 0");
        require(amount<=2,"Cannot mint 3 or more");
        require(openForFree, "Free minting is not active");
        require(totalSupply()+amount <= freesupply,"Free token is all claimed");
        _safeMint(msg.sender, amount);
    }

   function devMint(uint256 amount) external onlyOwner{
        _safeMint(msg.sender, amount);
   }
    
    function withdraw() external onlyOwner 
    {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
       
    function withdrawPart(uint256 amount) external onlyOwner 
    {
        payable(msg.sender).transfer(amount);
    }

    function reveal(string memory baseURI) external onlyOwner {
        unveil=true;
        _BaseURI = baseURI;
    }
    
    function setActive() external onlyOwner{
        openForMint=true;
        openForFree=true;
    }
   
    function setNonActive() external onlyOwner{
        openForMint=false;
        openForFree=false;
    }

    function max_supply() public view virtual returns (uint256) {
        return larvazSupply;
    }

   function price() public view virtual returns (uint256){
       return _larvazPrice;
   }

    function _baseURI() internal view override returns (string memory) {
        return _BaseURI;
    }
    
    function setBaseURI(string calldata URI) public onlyOwner {
        _BaseURI = URI;
    }   
    
}