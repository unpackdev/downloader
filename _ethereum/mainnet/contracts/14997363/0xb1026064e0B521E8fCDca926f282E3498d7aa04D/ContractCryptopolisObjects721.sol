// SPDX-License-Identifier: CryptopolisGame

pragma solidity ^0.8.11;

import "./ERC721Burnable.sol";
import "./ERC721URIStorage.sol";

contract ContractCryptopolisObjects721 is ERC721Burnable, ERC721URIStorage {

    /**
     * @dev
     * public address for the owner of the contract
     */
    address public owner;

     /**
     * @dev
     * public address which holds the next available id
     */
    uint public idCount = 0;

    /**
     * @dev
     * public id which holds the next available id for the uri mapping
     */
    uint8 public idToUriCount = 0;

     /**
     * @dev Base Uri variable
     */
    string public baseUri;

    event OwnerChanged(address _newOwner);

    modifier onlyOwner {
        require(msg.sender == owner, "Only the current owner can call this function");
        _;
    }

    /**
     * @dev
     * constructor which gets called once during deployment
     * sets the owner to the deploying wallet
     * generates the basic mappings for the metadata uris
     */
    constructor(string memory name_, string memory symbol_, string memory _initialBaseUri) ERC721(name_, symbol_) {
        owner = msg.sender;
        baseUri = _initialBaseUri;
    }

    /**
     * @dev
     * Setter for the baseuri variable, callable by the owner of the contract
     */
    function setBaseUri(string calldata _newBaseUri) public onlyOwner {
        baseUri =  _newBaseUri;
    }

    /**
     * @dev
     * public function to transfer the ownership of the contract
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    /**
     * @dev
     * public function which allows the owner to mint a single new nft
     */
    function mintObject(address to, string calldata _uri) public onlyOwner {
        _mint(to, idCount);
        _setTokenURI(idCount, _uri);
        idCount += 1;
    }

     /**
     * @dev
     * public function which allows the owner to batch mint new nfts
     * the limit is ~450 for each batch
     */
    function mintObjectBatch(address to, string[] calldata _uri) public onlyOwner {
        require(_uri.length > 0, "The uri array needs to hold at least one value.");
        for(uint x = 0 ; x < _uri.length ; x++) {
            _mint(to, idCount);
            _setTokenURI(idCount, _uri[x]);
            idCount += 1;
        }
    }

    /**
    * @dev
    * method to transfer a batch of tokenids to an array of addresses
    */
    function batchTransfer(address[] calldata _to, uint256[] calldata _tokenId) public {
        require(_to.length == _tokenId.length,"The length of the provided arrays do not match.");
        for (uint i = 0; i < _tokenId.length; i++) {
            safeTransferFrom(msg.sender, _to[i], _tokenId[i]);
        }
    }

    /**
    * @dev
    * method to transfer a batch of tokenids to an array of addresses
    */
    function batchTransferToSameAddress(address _to, uint256[] calldata _tokenId) public {
        for (uint i = 0; i < _tokenId.length; i++) {
            safeTransferFrom(msg.sender, _to, _tokenId[i]);
        }
    }

    /**
    * @dev
    * method to transfer a batch of tokenids to the same address
    */
    function transferAll(address _to, uint256[] calldata _tokenId) public {
        for (uint i = 0; i < _tokenId.length; i++) {
            safeTransferFrom(msg.sender, _to, _tokenId[i]);
        }
    }

     /**
     * @dev
     * wrapper for the burn functionality of the ERC721Burnable
     * implements the _burn function from the ERC721URIStorage to delete the metadata mapping on burn
     */
    function burn(uint256 _tokenId) public override {
        require(msg.sender == ownerOf(_tokenId) || msg.sender == getApproved(_tokenId), "Authorization to burn the token required.");
        _burn(_tokenId);
    }

     /**
     * @dev
     * wrapper for the tokenURI functionality of the ERC721URIStorage
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

     /**
     * @dev
     * wrapper for the _setTokenURI functionality of the ERC721URIStorage
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal override(ERC721URIStorage) {
        super._setTokenURI(tokenId, _tokenURI);
    }

     /**
     * @dev
     * wrapper for the _burn functionality of the ERC721URIStorage
     */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

}
