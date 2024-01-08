pragma solidity ^0.8.0;

// Importing ERC 721 standard contracts from OpenZeppelin
import "./Strings.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./console.sol";

contract Terrestrial is
    ERC721Enumerable,
    Ownable
{
    /*
 _______  _______  ______    ______    _______  _______  _______  ______    ___   _______  ___      _______ 
|       ||       ||    _ |  |    _ |  |       ||       ||       ||    _ |  |   | |   _   ||   |    |       |
|_     _||    ___||   | ||  |   | ||  |    ___||  _____||_     _||   | ||  |   | |  |_|  ||   |    |  _____|
  |   |  |   |___ |   |_||_ |   |_||_ |   |___ | |_____   |   |  |   |_||_ |   | |       ||   |    | |_____ 
  |   |  |    ___||    __  ||    __  ||    ___||_____  |  |   |  |    __  ||   | |       ||   |___ |_____  |
  |   |  |   |___ |   |  | ||   |  | ||   |___  _____| |  |   |  |   |  | ||   | |   _   ||       | _____| |
  |___|  |_______||___|  |_||___|  |_||_______||_______|  |___|  |___|  |_||___| |__| |__||_______||_______|
  
  */
    
    using SafeMath for uint256;
       
    uint256 public _currentTokenId = 0;

    uint256 MAX_SUPPLY =  4096;
    string public baseTokenURI = "https://gateway.pinata.cloud/ipfs/QmUyXkPFrhtq1m7cFD9raPpVAmrqMK1GsjsBo3gTY6ruim/";
   
    uint256 public Mint_price = 0.022 ether;
    uint256 public buy3_Discount = 0.051 ether;
    uint256 public Discount = 0.017 ether;
    
    
    string _name = "Ether Terrestrial";
    string _symbol = "ET";
    

    constructor() ERC721(_name, _symbol) {
        // baseTokenURI = _uri;
    }
    
  
    //Allows users to claim their first Terrestrial for free, and buy a pack of 3 for a discount
    
    function adoptFree() external {
        require(balanceOf(_msgSender()) == 0, "Sorry human, you've claimed your freebie for the day.");
        _mint(_msgSender(), _getNextTokenId());
        _incrementTokenId();
    }
    
    function adopt3Discount() public payable {
        require(msg.value <= buy3_Discount, "Incorrect Ether amount.");
        uint256 num = 3; 
        if(balanceOf(_msgSender()) == 0 ){
            num = num + 1;
        }
        require(_currentTokenId.add(num) < MAX_SUPPLY, "Max Supply Reached");
        for(uint256 i=0; i<num; i++){

            _mint(_msgSender(), _getNextTokenId());
            _incrementTokenId();
        }
    }
 
    function adoptMultiples(uint amountofTerrestrials) external payable {
        require(amountofTerrestrials.mul(Discount) <= msg.value);
        require(amountofTerrestrials <= 12, "Only 12 can fit in the spaceship");
        require(_currentTokenId.add(amountofTerrestrials) < MAX_SUPPLY, "Max Supply Reached");
        _mint(_msgSender(), _getNextTokenId());
            _incrementTokenId();
    }   
    
    //////////Owner Mint Functions
    
    function mintMany(uint256 num, address _to) public onlyOwner {
        require(_currentTokenId + num < MAX_SUPPLY, "Max Limit");
        require(num <= 20, "Max 20 Allowed.");
        for(uint256 i=0; i<num; i++){

            _mint(_to, _getNextTokenId());
            _incrementTokenId();
        }
    }
    
    function mintTo(address _to) public onlyOwner {
        require(_currentTokenId < MAX_SUPPLY, "Max Limit");
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();
    }
    
    

  
 
  
  function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * @dev increments the value of _currentTokenId  
     */
    function _incrementTokenId() private {
        require(_currentTokenId < MAX_SUPPLY);

        _currentTokenId++;
    }

    /**
     * @dev change the TerrestrialURI if there are future problems with the API service
     */
    function setBaseUri(string memory _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId), ".json"));
    }

}