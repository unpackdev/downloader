// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./Strings.sol";

contract EthernalPresents is ERC721, ERC721Enumerable, ERC721Burnable, Ownable, EIP712 {
    using Strings for uint256;

    // Mapping token name hashes (as numbers) to URI data
    mapping(uint256 => bytes32) private nameHashesToUriData;

    // Mapping for token URIs in IPFS
    mapping(uint256 => string) private additionalTokenURIs;

    // Address that authenticates potentially dangerous operations
    address private authSigner;

    string private baseURI;

    // Structure for signed data input for setting additional URI
    struct AdditionalURIData {
        bytes32 nameHash;
        string uri;
        bytes signature;
    }

    string private constant SIGNING_DOMAIN = "ETPAdditionalURIData";
    string private constant SIGNATURE_VERSION = "1";

    // Total pieces allowed
    uint256 public maxSupply;

    // Price for mint
    uint256 public mintPrice;

    constructor() 
        ERC721("Ethernal Presents", "PRESENT")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
    }

    // Minting it through a dedicated web app to generate the required data
    function mintTo(address to, bytes32 nameHash, bytes32 uriData) public payable {
        uint256 tokenId = uint256(nameHash);
        require(!_exists(tokenId), "ERC721: token already minted");
        
        // check payment
        require(msg.value >= mintPrice, "Insufficient ether sent");

        // check number of units minted
        require(totalSupply() < maxSupply, "Max supply reached");

        // check validity of uriData
        require(bytes12(keccak256(abi.encode(nameHash))) == bytes12(uriData), "Invalid URI data");

        _safeMint(to, tokenId);
        nameHashesToUriData[tokenId] = uriData;
    }

    // Minting it through a dedicated web app to generate the required data
    function mint(bytes32 nameHash, bytes32 uriData) public payable {
        mintTo(_msgSender(), nameHash, uriData);
    }

    function mintMultiple(address[] calldata to, bytes32[] calldata nameHash, bytes32[] calldata uriData) public payable {
        require(to.length == nameHash.length, "Bad input data formatting");
        require(to.length == uriData.length, "Bad input data formatting");
        require(msg.value >= (mintPrice * to.length), "Insufficient ether sent");
        require(totalSupply() + to.length <= maxSupply, "Max supply would be exceeded");

        for (uint i = 0; i < to.length; i++) {
            uint256 tokenId = uint256(nameHash[i]);
            require(!_exists(tokenId), "ERC721: token already minted");
        }

        for (uint i = 0; i < to.length; i++) {
            mintTo(to[i], nameHash[i], uriData[i]);
        }
    }

    function setAdditionalTokenURI(AdditionalURIData calldata inputData) public {
        uint256 tokenId = uint256(inputData.nameHash);
        require(ERC721.ownerOf(tokenId) == _msgSender(), "Token is not own");

        // make sure signature is valid and get the address of the signer
        address signer = _verifyAdditionalURIData(inputData);
        require(signer == authSigner, "Signature invalid");

        additionalTokenURIs[tokenId] = inputData.uri;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Returns a hash of the given AdditionalURIData, prepared using EIP712 typed data hashing rules.
    function _hashAdditionalURIData(AdditionalURIData calldata inputData) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("AdditionalURIData(bytes32 nameHash,string uri)"),
            inputData.nameHash,
            keccak256(bytes(inputData.uri))
        )));
    }

    // Verifies the signature for a given AdditionalURIData, returning the address of the signer.
    // Will revert if the signature is invalid.
    function _verifyAdditionalURIData(AdditionalURIData calldata inputData) internal view returns (address) {
        bytes32 digest = _hashAdditionalURIData(inputData);
        return ECDSA.recover(digest, inputData.signature);
    }

    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);

        if (bytes(additionalTokenURIs[tokenId]).length != 0) {
            delete additionalTokenURIs[tokenId];
        }

        delete nameHashesToUriData[tokenId];
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _additionalURI = additionalTokenURIs[tokenId];
        if (bytes(_additionalURI).length > 0) {
            // has IPFS URI
            return string(abi.encodePacked("ipfs://", _additionalURI, "/metadata.json"));
        }

        string memory base = _baseURI();
        uint256 uriData = uint256(nameHashesToUriData[tokenId]);
        string memory uriDataHex = uriData.toHexString(32);
        return string(abi.encodePacked(base, uriDataHex, ".json"));
    }
    
    function initGlobalValues(uint256 price, uint256 supply, address newSigner, string calldata newBaseUri) public onlyOwner {
        mintPrice = price;
        maxSupply = supply;
        authSigner = newSigner;
        baseURI = newBaseUri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function contractURI() public view returns (string memory) {
        string memory base = _baseURI();
        return string(abi.encodePacked(base, "contractmetadata.json"));
    }

    function isTokenAvailable(bytes32 nameHash) public view returns (bool) {
        return nameHashesToUriData[uint256(nameHash)] == 0;
    }
}