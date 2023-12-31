//SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.7;  
  
import "./ERC721A.sol";  
import "./Counters.sol";
import "./MerkleProof.sol";
import "./IERC721.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract NomemeneSolo is ERC721A, ERC2981, Ownable {  
    using Counters for Counters.Counter;
    
    address public royaltySplit;

    string public baseURI;

    bool public baseURILocked = false;

    uint96 private royaltyBps = 1000;

    constructor() ERC721A("NomemeneSolo", "NOMEMENE") {} 

    function mint(uint256 quantity) public payable onlyOwner {
        _safeMint(msg.sender, quantity);
    }

    function updateRoyalty(uint96 _royaltyBps) public onlyOwner {
        require(royaltySplit!=address(0), "split address not set, please set split address before updating royalty");
        royaltyBps = _royaltyBps;
        _setDefaultRoyalty(royaltySplit, royaltyBps);
    }

    function updateBaseURI(string calldata givenBaseURI) public onlyOwner {
        require(!baseURILocked, "base uri locked");
       
        baseURI = givenBaseURI;
    }

    function lockBaseURI() public onlyOwner {
        baseURILocked = true;
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, Strings.toString(tokenID)));
    }
 
    function setSplitAddress(address _address) public onlyOwner {
        royaltySplit = _address;
        _setDefaultRoyalty(royaltySplit, royaltyBps);
    }

    function supportsInterface(
    bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }
}