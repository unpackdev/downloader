// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";


contract SOT is ERC721Upgradeable, UUPSUpgradeable, OwnableUpgradeable {

    // total number of SOTs minted
    uint256 public _sotCounter;
    // total supply which can be different from sotCounter in case some tokens are burned
    uint256 private _currentSupply;

    // map SOT's token id to its tokenURI
    mapping(uint256 => string) public tokenURIs;
    // check if token URI exists
    mapping(string => bool) public tokenURIExists;

    //No constructor in upgradeable contracts, replaced by initilize() function
    function initialize() public initializer{
        
        __ERC721_init('FingeRate', "SOT");
        __Ownable_init();
        
    }
    
    //function to authorize upgrade, onlyOwner can do it here
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner{} 

    //overriding the default implementation of tokenURI in ERC721Upgradeable
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {

        //check if the token against a tokenId exists or not
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return tokenURIs[tokenId];

    }

    function mint(address to, string memory _tokenURI) public virtual onlyOwner  {

        // check if the minting limit has reached or not
        require(_currentSupply < 1200000, "Minting limit reached!");
        
        // check if the token URI already exists or not
        require(!tokenURIExists[_tokenURI], "Token URI already exists!");

        //setting the tokenURI and tokenURIExsits flag to true for the token that is being minted
        tokenURIs[_sotCounter] = _tokenURI;
        tokenURIExists[_tokenURI] = true;

        //minting the token
        _mint(to, _sotCounter);
        
        //incrementing the counter and the supply
        _sotCounter ++;
        _currentSupply ++;
    }

    function burn(uint256 tokenId) public virtual onlyOwner {
        
        // check if the token exists or not
        require(_exists(tokenId), "Token does not exist");

        //burning the token
        _burn(tokenId);

        //decrementing the supply
        _currentSupply -= 1;

    }
    
    // get metadata of the token
    function getTokenMetaData(uint _tokenId) public view returns(string memory) {

        //returning the metadata URL i.e. the tokenURI 
        string memory tokenMetaData = tokenURIs[_tokenId];
        return tokenMetaData;
    }

    //get current supply
    function getSupply() public view returns(uint256 supply){
        return _currentSupply;
    }

    //get current tokenId
    function getSotCount() public view returns(uint256 counter){
        return _sotCounter;
    }

}