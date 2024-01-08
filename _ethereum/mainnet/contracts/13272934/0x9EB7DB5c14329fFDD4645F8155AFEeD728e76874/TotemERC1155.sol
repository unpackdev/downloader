// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract TotemERC1155 is ERC1155, Ownable {
    address private _signer;
    string private _baseURI = "https://nifty-island-totem-public.s3.us-east-2.amazonaws.com/";
    string private _contractMetadataURI = "totem_contract.json";
    mapping(uint256 => string) public tokenMetadata;
    mapping(uint256 => bool) private usedNonces;

    constructor(address signer) ERC1155("https://nifty-island-totem-public.s3.us-east-2.amazonaws.com/") {
        _signer = signer;
        tokenMetadata[0] = "globe_totem.json";
        tokenMetadata[1] = "socrates_totem.json";
    }

    function updateSigner(address newSigner) external onlyOwner {
        _signer = newSigner;
    }

    function mint(address to, uint256 nonce, uint256 tokenId, bytes calldata signature)
        external {
        require(usedNonces[nonce] == false, "can't use the same signature twice");
        usedNonces[nonce] = true;

        bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(to, nonce, tokenId)));
        require(ECDSA.recover(hash, signature) == _signer, "Signature failed to recover");

        _mint(to, tokenId, 1, "");
    }

    function updateMetadata(uint256 tokenId, string memory metadata)
        external
        onlyOwner {
        tokenMetadata[tokenId] = metadata;
    }

    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    function updateBaseURI(string memory newURI) external onlyOwner {
        _baseURI = newURI;
    }

    function uri(uint256 id) public view override returns (string memory) {
        string memory base = baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenMetadata[id])) : ""; 
    }

    function contractURI() public view returns (string memory) {
        string memory base = baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, _contractMetadataURI)) : ""; 
    }

    function updateContractURI(string memory newURI) external onlyOwner {
        _contractMetadataURI = newURI;
    }
}