// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*****************************************************************************************************
 ██████╗░███████╗░██████╗░███████╗███╗░░██╗  ██████╗░░██╗░░░░░░░██╗░█████╗░██████╗░███████╗░██████╗
 ██╔══██╗██╔════╝██╔════╝░██╔════╝████╗░██║  ██╔══██╗░██║░░██╗░░██║██╔══██╗██╔══██╗██╔════╝██╔════╝
 ██║░░██║█████╗░░██║░░██╗░█████╗░░██╔██╗██║  ██║░░██║░╚██╗████╗██╔╝███████║██████╔╝█████╗░░╚█████╗░
 ██║░░██║██╔══╝░░██║░░╚██╗██╔══╝░░██║╚████║  ██║░░██║░░████╔═████║░██╔══██║██╔══██╗██╔══╝░░░╚═══██╗
 ██████╔╝███████╗╚██████╔╝███████╗██║░╚███║  ██████╔╝░░╚██╔╝░╚██╔╝░██║░░██║██║░░██║██║░░░░░██████╔╝
 ╚═════╝░╚══════╝░╚═════╝░╚══════╝╚═╝░░╚══╝  ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░░░░╚═════╝░
  Contract Developer: Stinky (@nomamesgwei)
  Description: Degen Dwarfs Community Art Collection includes exclusive 1/1's donated by 
               community members.
******************************************************************************************************/

import "./Strings.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract CommunityArtCollection is ERC721, ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;

    /// @notice Counter for number of mints
    Counters.Counter public _artIds;
    /// @dev Base URI used for token metadata
    string private _baseTokenUri;

    struct Art {
        // Collection ID #
        uint256 id;
        // Mint Date
        uint256 mintDate;
        // Winners Address
        address winner;
        // Address for Artist Donation
        address artistDonation;
        // Count of Donations
        uint256 donationCount;
    }

    /// @dev Array of Art (Collection)
    mapping(uint256 => Art) internal _collection;


    /*
     * @notice This contract is designed to be used by Multisigs
     * @param _tokenURI the URL for the tokenURI (metadata)          
     */    
    constructor(
        string memory _tokenURI
    ) ERC721("Degen Dwarfs Community Art Collection", "DDCAC") {
        _baseTokenUri = _tokenURI;
    }

    /*
     * @notice Mint a Degen Dwarf NFT directly into the winners address
     * @param _winner Address of the winner   
     * @param _artist Address for Artist Donations         
     */    
    function reward(address _winner, address _artist) external whenNotPaused onlyOwner {   
        uint256 id = _artIds.current();     
        _collection[id] = Art(id, block.timestamp, _winner, _artist, 0);
        _safeMint(_winner,  id);
        _artIds.increment();
    }

    /*
     * @notice Donate ERC-20 Token(s) to Artist of a specific Art piece
     * @param _artId Address of the winner
     * @param _tokenAddress Address for ERC-20 Token you want to Donate
     * @param _amount Number in whole tokens that you want to donate. (WEI value not ETHER!)
     */    
    function artistTokenDonation(uint256 _artId, address _tokenAddress, uint256 _amount) external {
        require(_amount > 0, "Donations must be greater than 0");
        require(IERC20(_tokenAddress).balanceOf(_msgSender()) > _amount, "You don't own enough tokens to send this amount.");
        require(IERC20(_tokenAddress).allowance(_msgSender(), address(this)) > _amount, "Not enough token allowance.");
        IERC20(_tokenAddress).transferFrom(_msgSender(), _collection[_artId].artistDonation, _amount);
        _collection[_artId].donationCount++;
    }

    /*
     * @notice Donate to Artist of a specific Art piece
     * @param _artId Address of the winner    
     */    
    function artistDonation(uint256 _artId) payable external {
        require(msg.value > 0, "Donations must be greater than 0");
        payable(_collection[_artId].artistDonation).transfer(msg.value);
        _collection[_artId].donationCount++;
    }

    /* @notice Pause Degen Dwarf minting */  
    function pauseMinting() external onlyOwner {
        _pause();
    }

    /* @notice Resume Degen Dwarf minting*/  
    function unpauseMinting() external onlyOwner {
        _unpause();
    }      

    // Internal functions

    /* @notice Returns the baseURI */      
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenUri;
    }

    // public functions

    /* @notice Returns an address array of winners 
     * @param _artId Address of the winner    
     */   
    function getArtPiece(uint256 _artId) public view returns(Art memory) {
        return _collection[_artId];
    }

    /* @notice Returns an array of winning addresses */   
    function getWinners() public view returns(address[] memory) {
        address[] memory winners;
        for (uint256 i = 0; i < totalSupply(); i++) {
            winners[i] = _collection[i].winner;
        }
        return winners;
    }    

    /* @notice Returns an array of all Art */   
    function getCollection() public view returns(Art[] memory) {
        Art[] memory collection = new Art[](totalSupply());
        for (uint256 i = 0; i < totalSupply(); i++) {
            Art storage art = _collection[i];
            collection[i] = art;
        }
        return collection;
    }    

    /*
     * @notice set the baseURI
     * @param baseURI
     */  
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenUri = baseURI;
    }      
    /* 
     * @notice Returns the baseURI 
     * @param tokenId 
     */         
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseURI(), toString(tokenId), ".json"));
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }    

    /*
     * Why Override? Without this, you will get the 2 errors below. 
     * Derived contract must override function "_beforeTokenTransfer". Two or more base classes define function with same name and parameter types.
     * Derived contract must override function "supportsInterface". Two or more base classes define function with same name and parameter types.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);

        // do stuff before every transfer
        // e.g. check that vote (other than when minted) 
        // being transferred to registered candidate
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }    
}