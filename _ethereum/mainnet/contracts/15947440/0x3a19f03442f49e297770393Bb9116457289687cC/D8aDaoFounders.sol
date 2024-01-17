// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

import "./ERC721AUpgradeable.sol";
import "./Initializable.sol";

/*
* @title D8a Dao
* @author lileddie.eth / Enefte Studio
*/
contract D8aDaoFounders is Initializable, ERC721AUpgradeable {
 

    string public BASE_URI;
      
    mapping(address => bool) private _dev;  
    address private _owner;
    
    /**
    * @notice sets the URI of where metadata will be hosted, gets appended with the token id
    *
    * @param _uri the amount URI address
    */
    function setBaseURI(string memory _uri) external onlyDevOrOwner {
        BASE_URI = _uri;
    }

    
    /**
    * @notice returns the URI that is used for the metadata
    */
    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    
    /**
     * @dev notice if called by any account other than the dev or owner.
     */
    modifier onlyDevOrOwner() {
        require(owner() == msg.sender || _dev[msg.sender], "Ownable: caller is not the owner or dev");
        _;
    }  

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Adds a new dev role user
     */
    function addDev(address _newDev) external onlyOwner {
        _dev[_newDev] = true;
    }

    /**
     * @notice Removes address from dev role
     */
    function removeDev(address _removeDev) external onlyOwner {
        delete _dev[_removeDev];
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    /**
    * @notice Initialize the contract and it's inherited contracts, data is then stored on the proxy for future use/changes
    *
    * @param name_ the name of the contract
    * @param symbol_ the symbol of the contract
    */
    function initialize(string memory name_, string memory symbol_) public initializer {   
        __ERC721A_init(name_, symbol_);
        BASE_URI = "https://enefte.info/d8adao/founder.php?token_id=";
        _dev[msg.sender] = true;
        _owner = msg.sender;
        _mint(address(0x2749Fa69c1f011b1a0164A01A35BEF781832d21D), 300);
        
    }

}