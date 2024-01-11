/*
 __  __                   ____  _             
|  \/  | ___   ___  _ __ / ___|| |_ __ _ _ __ 
| |\/| |/ _ \ / _ \| '_ \\___ \| __/ _` | '__|
| |  | | (_) | (_) | | | |___) | || (_| | |   
|_|  |_|\___/ \___/|_| |_|____/ \__\__,_|_|   
                                                                                         
*/
pragma solidity ^0.8.7;
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract MoonStar is ERC721A, Ownable, ReentrancyGuard {

    string public baseURI;
    string public  baseExtension = "";
    string public hiddenMetadataUri;

    uint256 public Price = 0.0066 ether;
    uint256 constant public MoonStars = 6666;
    uint256 public freeSupply = 1666;
    uint256 public maxFree = 5;
    uint256 public maxBuy = 10; 

    bool private saleIsActive = true;
    bool private revealed = false;
    mapping(address => uint256) public howmanyfreeMoonStars;
    mapping(address => uint256) public howmanybuyMoonStars;



    constructor() ERC721A("MoonStar", "MoonStar") {
        
    }

   
    modifier mintCompliance() {
        require(saleIsActive, "Sale is not active yet."); 
        _;
        }

    function mint(uint256 _amount) external payable nonReentrant mintCompliance{
        require(totalSupply() + _amount <= MoonStars, "over  supply");
        require(_amount <= maxBuy);
       require(msg.value == _amount*Price);
        require(howmanybuyMoonStars[msg.sender] < maxBuy);
         _safeMint(msg.sender, _amount);
        howmanybuyMoonStars[msg.sender] += _amount;

    }

     function free_mint(uint256 _mintAmount) external  nonReentrant mintCompliance {
        require(_mintAmount > 0 );
        require(_mintAmount <= maxFree );
        require(totalSupply() + _mintAmount <= freeSupply, "over Free supply");
        require(howmanyfreeMoonStars[msg.sender] < maxFree);

        _safeMint(msg.sender, _mintAmount);
        howmanyfreeMoonStars[msg.sender] += _mintAmount;

    }


   

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        Price = _mintPrice;
    }

  
    function setMaxFree(uint256 _maxfree) external onlyOwner {
        maxFree = _maxfree;
    }
    function setMaxBuy(uint256 _buy) external onlyOwner {
        maxBuy = _buy;
    }

    function setBaseTokenURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
    function setRevealed() public onlyOwner {
           revealed = !revealed;
    }
    function setsaleIsActive() public onlyOwner {
           saleIsActive = !saleIsActive;
    }
    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
        }

    function  setbaseExtension(string memory _baseExtension)external onlyOwner{
        baseExtension = _baseExtension;
    }
    mapping(address => uint256) private howmanyteam;


    function withdrawAll() external onlyOwner  nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to send ether");
    }
    function setFreeSupply(uint256 _amount) external onlyOwner{
        freeSupply = _amount;
    }
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        if (revealed == false) {return hiddenMetadataUri;} 
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(_tokenId),baseExtension)) : "";
    }

}