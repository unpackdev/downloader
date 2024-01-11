// contracts/pfpidNft.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// imports
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract pfpid is ERC721URIStorage, Ownable {
    address public admin;
    uint256 public mintPrice;
    bool public revealed = true;
    string public prerevealMetadataUri;
    string public contractMetadataUri;
    mapping(uint256 => bool) usedNonces;

    // required to use ECDSA for signature verificaiton
    using ECDSA for bytes32;

    // events
    event MintEvent(address to, uint256 tokenId);
    event BurnEvent(address account, uint256 tokenId);

    constructor(
        address _admin,
        uint256 _mintPrice,
        string memory _prerevealMetadataUri,
        string memory _contractMetadataUri
    ) ERC721("pfpid", "PFPID") {
        admin = _admin;
        mintPrice = _mintPrice;
        prerevealMetadataUri = _prerevealMetadataUri;
        contractMetadataUri = _contractMetadataUri;
    }

    function mintItem(
        string memory _tokenURI,
        uint256 tokenId,
        uint256 nonce,
        bytes memory signature
    ) public payable returns (uint256) {
        require(!usedNonces[nonce], "Nonce has been used.");
        require(msg.value >= mintPrice, "Not enough Eth passed for mint fee.");
        address owner = owner();
        payable(address(owner)).transfer(msg.value);
        usedNonces[nonce] = true;
        bool isValid = isValidSignature(_tokenURI, tokenId, nonce, signature);
        require(isValid, "Invalid signature.");
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        emit MintEvent(msg.sender, tokenId);
        return tokenId;
    }

    function isValidSignature(
        string memory _tokenURI,
        uint256 tokenId,
        uint256 nonce,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(msg.sender, _tokenURI, tokenId, nonce, this)
        );
        return hash.toEthSignedMessageHash().recover(signature) == admin;
    }

    function updateMintPrice(uint256 newMintPrice)
        public
        onlyOwner
        returns (uint256)
    {
        mintPrice = newMintPrice;
        return mintPrice;
    }

    function updateAdmin(address newAdmin) public onlyOwner returns (address) {
        admin = newAdmin;
        return admin;
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        emit BurnEvent(msg.sender, tokenId);
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (revealed == false) {
            return prerevealMetadataUri;
        }
        return super.tokenURI(tokenId);
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function contractURI() public view returns (string memory) {
        return contractMetadataUri;
    }

    // removing ability to transfer nft once minted

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        revert("Forbidden operation");
    }

    function approve(address, uint256) public pure override {
        revert("Forbidden operation");
    }

    function getApproved(uint256) public pure override returns (address) {
        revert("Forbidden operation");
    }

    function setApprovalForAll(address, bool) public pure override {
        revert("Forbidden operation");
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert("Forbidden operation");
    }

    function isApprovedForAll(address, address)
        public
        pure
        override
        returns (bool)
    {
        revert("Forbidden operation");
    }

    function safeTransferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert("Forbidden operation");
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override {
        revert("Forbidden operation");
    }
}
