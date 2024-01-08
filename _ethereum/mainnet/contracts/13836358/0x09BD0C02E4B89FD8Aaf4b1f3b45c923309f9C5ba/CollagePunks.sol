// SPDX-License-Identifier: MIT
/*
_________          .__   .__                            __________                 __            
\_   ___ \   ____  |  |  |  |  _____      ____    ____  \______   \ __ __   ____  |  | __  ______
/    \  \/  /  _ \ |  |  |  |  \__  \    / ___\ _/ __ \  |     ___/|  |  \ /    \ |  |/ / /  ___/
\     \____(  <_> )|  |__|  |__ / __ \_ / /_/  >\  ___/  |    |    |  |  /|   |  \|    <  \___ \ 
 \______  / \____/ |____/|____/(____  / \___  /  \___  > |____|    |____/ |___|  /|__|_ \/____  >
        \/                          \/ /_____/       \/                        \/      \/     \/ 
      ___   ____    ______                                         __    __         __     ___  
    ,'  _| |_   |  |      |  .--.--.    .-----.      .---.-..----.|  |_ |__|.-----.|  |_  |_  `.
    |  |    _|  |_ |  --  |  |  |  | __ |  _  | __   |  _  ||   _||   _||  ||__ --||   _|   |  |
    |  |_  |______||______|  |___  ||__||_____||__|  |___._||__|  |____||__||_____||____|  _|  |
    `.___|                   |_____|                                                      |___,'
*/

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract CollagePunks is ERC721Enumerable, Ownable {
    using Strings for uint256;

    
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant RESERVED_NFT = 3098;
    uint256 public constant MAX_MINT_AMOUNT = 15;
    uint256 public constant ONE_HOUR = 3600;

    string baseURI;
    uint256 public publicPrice = 0.018 ether;
    bool public saleIsActive = false;
    bool public lockedMetadata = false;
    
    mapping(address => bool) public isWinnerGiveaway;
    uint256 public  mintGiveawayLeft = 40;
    
    uint256 public lastHourFreeMintTS; 
    uint256 public freeMintPerHour = 200;
    uint256 public freeMintLeft;
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) 
    {
        setBaseURI(_initBaseURI);
        _safeMint(msg.sender, RESERVED_NFT);
        lastHourFreeMintTS = block.timestamp/ONE_HOUR;
        freeMintLeft = freeMintPerHour;
    }

  
    function mint(uint256 _mintAmount) public payable 
    {
        require(saleIsActive, "Sale must be active");  
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= MAX_SUPPLY - mintGiveawayLeft, "All tokens are minted");    
        
        require(_mintAmount <= MAX_MINT_AMOUNT, "Max 15 tokens at the same time");
        require(_mintAmount > 0, "Nothing to mint");

        renewFreeMintLeft();

        require(msg.value >= publicPrice * _mintAmount, "Amount is to Low");          

        _mintAndSkipReserved(_mintAmount);
    }
  
   function mintFreeGiveawayWinnersOnly() public
    {
        require(saleIsActive, "Sale must be active");  
        uint256 supply = totalSupply();
        require(supply + 1 <= MAX_SUPPLY, "All tokens are minted");
        require(mintGiveawayLeft > 0, "No free giveaway tokens to mint");
        if (msg.sender != owner())
            require(isWinnerGiveaway[msg.sender], "You are not on the Winner Giveaway");
                      
        isWinnerGiveaway[msg.sender]=false;
        mintGiveawayLeft--;
        _mintAndSkipReserved(1);
    }

    function mintFreeWithLimit() public 
    {
        require(saleIsActive, "Sale must be active");  
        uint256 supply = totalSupply();
        require(supply + 1 <= MAX_SUPPLY - mintGiveawayLeft, "All tokens are minted");
        
        renewFreeMintLeft();

        if (msg.sender != owner())
            require(balanceOf(msg.sender) == 0, "Free token is for those who don't own one");   

        require(freeMintLeft > 0, "No tokens for the free mint at now");

        freeMintLeft--;
        _mintAndSkipReserved(1);

    }

    function _mintAndSkipReserved(uint256 _mintAmount) private 
    {
        uint256 supply = totalSupply();
        for(uint256 i = 1; i <= _mintAmount; i++)
        {
            if(supply + i - 1 < RESERVED_NFT)
                _safeMint(msg.sender, supply + i - 1);
            else
                _safeMint(msg.sender, supply + i);
        }      
    }
  

   function renewFreeMintLeft() public 
   {
        uint256 hourTS = block.timestamp/ONE_HOUR;
        if(hourTS >= lastHourFreeMintTS + 1)
        {
            freeMintLeft = freeMintPerHour;
            lastHourFreeMintTS = hourTS;
        }

   }
  
    function _baseURI() internal view virtual override returns (string memory) 
    {
        return baseURI;
    }
  

  
    function setBaseURI(string memory _newBaseURI) public onlyOwner 
    {
        require(!lockedMetadata, "Contract metadata are locked");
        baseURI = _newBaseURI;
    }


    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) 
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        return tokenIds;
    }



    function tokenURI(uint256 tokenId)
        public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
                
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
            : "";
    }

    
    function setWinnerGiveaway(address[] calldata _address) public onlyOwner 
    {
        for (uint256 i = 0; i < _address.length; i++) 
            isWinnerGiveaway[_address[i]] = true;
        
    }

    function setFreeMintPerHour(uint256 _newFreeMintPH) public onlyOwner 
    {
            freeMintPerHour = _newFreeMintPH;
    }
    
    function setMintGiveawayLeft(uint256 _newMintGiveawayLeft) public onlyOwner 
    {
        mintGiveawayLeft = _newMintGiveawayLeft;
    }

    
    function setPublicPrice(uint256 _newPublicPrice) public onlyOwner
    {
        publicPrice = _newPublicPrice;
    }


    function flipSaleState() public onlyOwner 
    {
        saleIsActive = !saleIsActive;
    }
    
    
    function lockMetadata() public onlyOwner 
    {
       lockedMetadata = true;
    }

 
    function withdraw() public payable onlyOwner 
    {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
  
}