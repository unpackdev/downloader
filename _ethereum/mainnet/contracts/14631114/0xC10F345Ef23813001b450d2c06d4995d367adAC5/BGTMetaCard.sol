pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract BGTMetaCard is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;

    uint256 public TOTAL_SUPPLY = 1_000;
    uint256 public MINT_PRICE = 0.08 ether;
    string public baseTokenURI;

    constructor() ERC721("BGTMetaCard", "BGT"){
        baseTokenURI = "";
    }

    function mintTo(address recipient) public payable whenNotPaused returns (uint256)
    {
        //Ensure that token supply limit is enforeced
        uint256 current = currentTokenId.current();
        require(current <= TOTAL_SUPPLY, "Mint Supply Reached");

        //Require payment to mint
        require((msg.value == MINT_PRICE) || (owner() == msg.sender), "Transaction must include value equal to mint price");
        
        //Mint a new token to the recipient
        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(recipient, newItemId);
        return newItemId;
    }

    function _baseURI() internal view virtual override returns (string memory)
    {
       return baseTokenURI;       
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function withdraw(address payable payee) public onlyOwner {
        uint256 val = address(this).balance;
       (bool sent, bytes memory data) = payee.call{value:val}(""); 
       require(sent, "Failed to send eth");
    }

    function pauseMinting() public onlyOwner {
        super._pause();
    }

    function resumeMinting() public onlyOwner {
        super._unpause();
    }
}
