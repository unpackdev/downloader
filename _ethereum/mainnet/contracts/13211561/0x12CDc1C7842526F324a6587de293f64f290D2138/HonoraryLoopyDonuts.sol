// SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

pragma solidity ^0.8.0;

/**
 * @title Honorary Loopy Donuts contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract HonoraryLoopyDonuts is ERC721, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    string public PROVENANCE;

    // Base URIs - one for IPFS and the other for Arweave
    string public IpfsBaseURI;
    string public ArweaveBaseURI;

    uint256 public MAX_HONORARY = 10;

    // Contract lock - when set, prevents altering the base URLs saved in the smart contract
    bool public locked = false;

    enum StorageType { IPFS, ARWEAVE }

    StorageType public mainStorage;

    /**
    @param name - Name of ERC721 as used in openzeppelin
    @param symbol - Symbol of ERC721 as used in openzeppelin
    @param main - The initial StorageType value for mainStorage
    @param provenance - The sha256 string of concatenated sha256 of all images in their natural order - AKA Provenance.
    @param ipfsBase - Base URI for token metadata on IPFS
    @param arweaveBase - Base URI for token metadata on Arweave
     */
    constructor(string memory name,
                string memory symbol,
                StorageType main,
                string memory provenance,
                string memory ipfsBase,
                string memory arweaveBase) ERC721(name, symbol) {
        mainStorage = main;
        PROVENANCE = provenance;
        IpfsBaseURI = ipfsBase;
        ArweaveBaseURI = arweaveBase;
    }

    /**
    * @dev Throws if the contract is already locked
    */
    modifier notLocked() {
        require(!locked, "Contract already locked.");
        _;
    }

    /**
     * @dev Withdraw balance from contract - just in case someone sends here funds which they shouldn't.
    */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*     
    * Set provenance hash - just in case there is an error
    * Provenance hash is set in the contract construction time,
    * ideally there is no reason to ever call it.
    */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner notLocked {
        PROVENANCE = provenanceHash;
    }

    /**
     * @dev locks the contract (prevents changing the metadata base uris)
     */
    function lock() public onlyOwner notLocked {
        require(bytes(IpfsBaseURI).length > 0 &&
                bytes(ArweaveBaseURI).length > 0,
                "Thou shall not lock prematurely!");
        locked = true;
    }

     /**
     * @dev Sets the IPFS Base URI for computing {tokenURI}.
     * Ideally we will have already uploaded everything before deploying the contract.
     * This method - along with {setArweaveBaseURI} - should only be called if we didn't
     * complete uploading the images and metadata to IPFS and Arweave or if there is an unforseen error.
     */
    function setIpfsBaseURI(string memory newURI) public onlyOwner notLocked {
        IpfsBaseURI = newURI;
    }

     /**
     * @dev Sets the Arweave Base URI for computing {arweaveTokenURI}.
     */
    function setArweaveBaseURI(string memory newURI) public onlyOwner notLocked {
        ArweaveBaseURI = newURI;
    }

    /**
     * @dev Sets the main metadata Storage baseUri.
     */
    function setMainStorage(StorageType stype) public onlyOwner notLocked {
        mainStorage = stype;
    }

    /**
    * @dev Returns the URI to the token's metadata stored on Arweave
    */
    function arweaveTokenURI(uint256 tokenId) public view returns (string memory) {
        return getTokenURI(tokenId, StorageType.ARWEAVE);
    }

    /**
    * @dev Returns the URI to the token's metadata stored on IPFS
    */
    function ipfsTokenURI(uint256 tokenId) public view returns (string memory) {
        return getTokenURI(tokenId, StorageType.IPFS);
    }

    /**
     * @dev Returns the tokenURI if exists and using the default -
     * aka main - metadata storage pointer specified by {mainStorage}.
     * See {IERC721Metadata-tokenURI} for more details.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        return getTokenURI(tokenId, mainStorage);
    }

    /**
    * @dev Returns the URI to the token's metadata stored on either Arweave or IPFS.
    * Takes into account the contracts' {startingIndex} which - alone - determines the allocation
    * of Loopy Donuts - ensuring a fair and completely random distribution.
    */
    function getTokenURI(uint256 tokenId, StorageType origin) public view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base;

        if (origin == StorageType.IPFS) {
            base = IpfsBaseURI;
        } else {
            base = ArweaveBaseURI;
        }

        // Deployer should make sure that the selected base has a trailing '/'
        return bytes(base).length > 0 ? string( abi.encodePacked(base, tokenId.toString(), ".json") ) : "";
    }

    /**
    * @dev Returns the base URI. Overrides empty string returned by base class.
    * Unused because we override {tokenURI}.
    * Included for completeness-sake.
    */
    function _baseURI() internal view override(ERC721) returns (string memory) {
        if (mainStorage == StorageType.IPFS) {
            return IpfsBaseURI;
        } else {
            return ArweaveBaseURI;
        }
    }

    /**
    * @dev Returns the base URI. Public facing method.
    * Included for completeness-sake and folks that want just the base.
    */
    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    /**
    * @dev Mints Honorary Loopy Donuts
    */
    function mintDonuts(uint numberOfTokens, address recipient) public onlyOwner notLocked {
        require(totalSupply().add(numberOfTokens) <= MAX_HONORARY, "Purchase would exceed max allowed Honorary.");
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            _safeMint(recipient, mintIndex);
        }
    }

    /**
     * @dev Do not allow renouncing ownership
     */
    function renounceOwnership() public override(Ownable) onlyOwner {}
}
