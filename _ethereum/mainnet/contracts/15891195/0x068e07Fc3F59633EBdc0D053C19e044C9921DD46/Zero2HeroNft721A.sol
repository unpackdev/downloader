// SPDX-License-Identifier: GPL-3.0

/**

                                          /$$$$$$  /$$                                                        
                                         /$$__  $$| $$                                                        
 /$$$$$$$$  /$$$$$$   /$$$$$$   /$$$$$$ |__/  \ $$| $$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$                     
|____ /$$/ /$$__  $$ /$$__  $$ /$$__  $$  /$$$$$$/| $$__  $$ /$$__  $$ /$$__  $$ /$$__  $$                    
   /$$$$/ | $$$$$$$$| $$  \__/| $$  \ $$ /$$____/ | $$  \ $$| $$$$$$$$| $$  \__/| $$  \ $$                    
  /$$__/  | $$_____/| $$      | $$  | $$| $$      | $$  | $$| $$_____/| $$      | $$  | $$                    
 /$$$$$$$$|  $$$$$$$| $$      |  $$$$$$/| $$$$$$$$| $$  | $$|  $$$$$$$| $$      |  $$$$$$/                    
|________/ \_______/|__/       \______/ |________/|__/  |__/ \_______/|__/       \______/                     
                                                                                                              
                                                                                                              
                                                                                                              
 /$$   /$$ /$$$$$$$$ /$$$$$$$$                                                                                
| $$$ | $$| $$_____/|__  $$__/                                                                                
| $$$$| $$| $$         | $$                                                                                   
| $$ $$ $$| $$$$$      | $$                                                                                   
| $$  $$$$| $$__/      | $$                                                                                   
| $$\  $$$| $$         | $$                                                                                   
| $$ \  $$| $$         | $$                                                                                   
|__/  \__/|__/         |__/                                                                                   
                                                                                                              
                                                                                                              
                                                                                                              
 /$$                       /$$$$$$$                      /$$                      /$$$$$$                     
| $$                      | $$__  $$                    |__/                     /$$__  $$                    
| $$$$$$$  /$$   /$$      | $$  \ $$  /$$$$$$   /$$$$$$$ /$$ /$$$$$$/$$$$       | $$  \__/  /$$$$$$  /$$$$$$$ 
| $$__  $$| $$  | $$      | $$$$$$$/ |____  $$ /$$_____/| $$| $$_  $$_  $$      |  $$$$$$  /$$__  $$| $$__  $$
| $$  \ $$| $$  | $$      | $$__  $$  /$$$$$$$|  $$$$$$ | $$| $$ \ $$ \ $$       \____  $$| $$$$$$$$| $$  \ $$
| $$  | $$| $$  | $$      | $$  \ $$ /$$__  $$ \____  $$| $$| $$ | $$ | $$       /$$  \ $$| $$_____/| $$  | $$
| $$$$$$$/|  $$$$$$$      | $$  | $$|  $$$$$$$ /$$$$$$$/| $$| $$ | $$ | $$      |  $$$$$$/|  $$$$$$$| $$  | $$
|_______/  \____  $$      |__/  |__/ \_______/|_______/ |__/|__/ |__/ |__/       \______/  \_______/|__/  |__/
           /$$  | $$                                                                                          
          |  $$$$$$/                                                                                          
           \______/                                                                                           
*/ 

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract Zero2HeroNft721A is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.01 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 10000;
  bool public paused = false;
  mapping(address => bool) public whitelisted;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    uint256 _mintAmount,
    uint256 _cost
) ERC721A(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setCost(_cost);
    mint(msg.sender, _mintAmount);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    if (msg.sender != owner()) {
       if(whitelisted[msg.sender] != true) {
          require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
       }
    }
    _;
  }
  function mint(address _to, uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // require(!paused);
    require(!paused, 'The contract is paused!');

    if (_to != owner()) {
        if(whitelisted[_to] != true) {
          require(msg.value >= cost * _mintAmount);
        }
    }

    _safeMint(_msgSender(), _mintAmount+1);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }
  //only owner
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }
  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
 function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function withdraw() public payable onlyOwner nonReentrant {
    // This will payout the owner 95% of the contract balance.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}
