// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract DimensionDoorsOpened is ERC721Enumerable, Ownable {
    
    using SafeMath for uint256;
    
    address private _manager;
    
    /**
     * @dev Returns the address of the current manager.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(manager() == _msgSender(), "Caller is not the manager");
        _;
    }
    
    /**
     * @dev Throws if called by any account other than the owner or manager.
     */
    modifier ownerOrManager() {
        require(owner() == _msgSender() || manager() == _msgSender(), "Caller is not the manager or owner");
        _;
    }
    
    /**
     * @dev Transfers management of the contract to a new account (`newManager`).
     * Can only be called by the current owner.
     */
    function transferManagement(address newManager) public virtual onlyOwner {
        require(newManager != address(0), "New owner is the zero address");
        _manager = newManager;
    }

    // Doors will be released on a batch-basis spanned over time. So not all doors are mintable upon release
    // There will be 50 batches in total
    uint256 constant MAX_BATCHES = 50;
    
    // The provenance hashes per batch for opened doors
    mapping(uint256 => string) public OPENDOORS_PROVENANCE_BATCH;
        
    // This is the master provenance hash for opened doors
    string public OPENDOORS_PROVENANCE_MASTER = "";
    
    string private URI;

    constructor() ERC721("Dimension Doors - Opened", "DIMDOORO") {}
    
    function setOpenedMasterProvenanceHash(string memory _provenanceHash) public onlyOwner {
        OPENDOORS_PROVENANCE_MASTER = _provenanceHash;
    }
    
    function setOpenedBatchProvenanceHash(uint256 _batchId, string memory _provenanceHash) public onlyOwner {
        require(_batchId < MAX_BATCHES + 1);
        OPENDOORS_PROVENANCE_BATCH[_batchId] = _provenanceHash;
    }

    /**
     * Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     * @param _tokenId the token ID to mint
     */
    function mintTo(address _to, uint256 _tokenId) public onlyManager {
        _mint(_to, _tokenId);
    }
    
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function tokenSupplies() external view returns (bool[] memory) {
        uint256 supply = 60 * MAX_BATCHES;
        bool[] memory existences = new bool[](supply);
        for(uint256 i = 0; i < supply; i++) {
            existences[i] = _exists(i);
        }
        return existences;
    }

    function setBaseURI(string memory _URI) public onlyOwner {
        URI = _URI;
    }
    
    function baseURI() external view returns (string memory) {
        return _baseURI();
    } 

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function tokensByOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }    
    
    function _baseURI() internal view override returns (string memory) {
        return URI;
    }
    
}