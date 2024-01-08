pragma solidity ^0.8.0;

// Importing ERC 721 standard contracts from OpenZeppelin
import "./Strings.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./console.sol";

contract EvolutioNFT is
    ERC721Enumerable,
    Ownable
{
    
    using SafeMath for uint256;
       
    uint256 public _currentTokenId = 0;

    uint256 MAX_SUPPLY =  5555;
    string public baseTokenURI = "Nothing Yet";
   
    uint256 public Mint_price = 0.022 ether;
    uint256 public buy3_Discount = 0.048 ether;
    uint256 public Discount = 0.016 ether;
    
    
    string _name = "EvolutioNFT";
    string _symbol = "EVO";
    

    constructor() ERC721(_name, _symbol) {
        // baseTokenURI = _uri;
    }
    
  
    //Allows users to claim for free
    
    function mintFree() external {
        require(balanceOf(_msgSender()) <= 3, "Sorry, you've claimed your freebies for the day.");
        require(_currentTokenId < 1000, "Sorry all freebies have been claimed.");
        _mint(_msgSender(), _getNextTokenId());
        _incrementTokenId();
    }
    

    function mint3discount() public payable {
        require(msg.value >= buy3_Discount, "Incorrect Ether amount.");
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
 
    function mintMultiples(uint amountToMint) external payable {
        require(amountToMint.mul(Discount) <= msg.value);
        require(amountToMint <= 12, "Only 12 per transaction");
        require(_currentTokenId.add(amountToMint) < MAX_SUPPLY, "Max Supply Reached");
        _mint(_msgSender(), _getNextTokenId());
            _incrementTokenId();
    }   
    

    function burn(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender);

        //Burn mechanic
        _transfer(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            _tokenId
        );
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
     * @dev change the EvolutionURI if there are future problems with the API service
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