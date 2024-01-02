// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./Ownable.sol";
import "./ERC2981.sol";

// Uncomment this line to use console.log
// import "./console.sol";

contract BeyondHumanAvatars is ERC721AQueryable, ERC2981, Ownable {
    uint16 public constant TOKEN_LIMIT = 1000;
    mapping(uint => bool) private _mintedNumbers;
    mapping(uint => string) private _uris;
    
    bool nukeMetadata = false;
    uint256 private mintPrice = 0.01 ether;
    address private mintSigner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    constructor() ERC721A("BeyondHumanAvatars", "BHA") { 
        _setDefaultRoyalty(_msgSender(), 500);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, IERC721A, ERC2981)
        returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Payments
    function withdraw() public onlyOwner {
        address payable owner = payable(owner());        
        owner.transfer(address(this).balance);
    }

    // For OpenSea

    function contractURI() public pure returns (string memory) {
        return "https://mint.beyondhuman.ai/storefront-metadata";
    }

    // Minting

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function mintFree(string memory uri, uint number, bytes memory sig) public {        
        require(isValidSig(keccak256(abi.encodePacked(uri, msg.sender, number, true)), sig), "Invalid signature");
        require(_mintedNumbers[number] == false, "Already minted");

        uint256 tokenId = _nextTokenId();
        _mintedNumbers[number] = true;
        _uris[tokenId] = uri;
        _safeMint(msg.sender, 1);
    }

    function mintPaid(string[] memory uris, uint[] memory numbers, bytes memory sig) public payable {        
        require(msg.value >= mintPrice * uris.length, "Not enough ETH");

        string memory uriString = uris[0];
        for (uint i = 1; i < uris.length; i++) {
            uriString = string(abi.encodePacked(uriString, uris[i]));
        }
        
        require(isValidSig(keccak256(abi.encodePacked(uriString, msg.sender, numbers)), sig), "Invalid signature");

        uint256 tokenId = _nextTokenId();
        for (uint i = 0; i < uris.length; i++) {
            require(_mintedNumbers[numbers[i]] == false, "Already minted");
            _mintedNumbers[numbers[i]] = true;
            _uris[tokenId + i] = uris[i];
        }
        _safeMint(msg.sender, uris.length);
    }

    function setMintSigner(address _mintSigner) public onlyOwner {
        mintSigner = _mintSigner;
    }

    // Returning minted NFTs

    function isMinted(uint number) public view returns (bool) {
        return _mintedNumbers[number];
    }   

    function allMinted() public view returns (bool[] memory) {
        bool[] memory minted = new bool[](TOKEN_LIMIT + 1);
        minted[0] = false;
        for (uint i = 1; i <= TOKEN_LIMIT; i++) {
            minted[i] = _mintedNumbers[i];
        }
        
        return minted;
    }   

    // Metadata nuking, in case of contract migration to new blockchain

    function setNukeMetadata(bool _nukeMetadata) public onlyOwner {
        nukeMetadata = _nukeMetadata;
    }

    // Token URI
    
    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(!nukeMetadata, "METADATA_NUKED");
        return _uris[tokenId];
    }

    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner {
        _uris[tokenId] = uri;
    }

    // Sig verification

    function isValidSig(bytes32 hashedMessage, bytes memory sig) internal view returns(bool) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashedMessage = keccak256(abi.encodePacked(prefix, hashedMessage));
        // console.logBytes(abi.encodePacked(prefixedHashedMessage));

        address signer = recoverSigner(prefixedHashedMessage, sig);

        return (signer == mintSigner);
    }
    
    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (r, s, v) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "signature length must be 65");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        // implicitly return (r, s, v)
    }
}
