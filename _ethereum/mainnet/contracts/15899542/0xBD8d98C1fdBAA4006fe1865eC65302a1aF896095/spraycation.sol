// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ERC165Checker.sol";

/*
https://www.spraycation.co.uk/

SPRAYCATION
SPRAYCATION
SPRAYCATION
SPRAYCATION
SPRAYCATION
SPRAYCATION
SPRAYCATION
SPRAYCATION
SPRAYCATION
SPRAYCATION
SPRAYCATION
*/

contract Spray is ERC721A, Ownable {

    // Tracks the sprayId to the URI
    mapping(uint => string) public spraycation;

    // Contract address -> token id -> bool
    mapping(address => mapping(uint => bool)) public addressTokensSprayed;

    bytes4 private ERC721InterfaceId = 0x80ac58cd;
    bytes4 private ERC1155MetadataInterfaceId = 0x0e89341c;

    uint public price = 0.01 ether;
    uint public sprayCount;
    uint public constant MAX_SUPPLY = 500;

    string public _baseTokenURI = "https://spraycation.s3.amazonaws.com/metadata/";

    bool public mintEnabled;
    bool public sprayEnabled = true;
    mapping(address => uint256) public mintClaimed;

    // Errors

    error AlreadyMinted();
    error alreadySprayed();
    error MintClosed();
    error MintedOut();
    error NoContracts();
    error policeAround();
    error WrongPrice();

    // Events

    event Setter(uint indexed sprayId, uint indexed usingTokenId, address indexed usingContractNFT);

    // Constructor

    constructor() ERC721A("SPRAY By Anonymous Artist", "SPRAY") {
        _mint(msg.sender, 1);
    }

    // Mint

    function mint(uint256 _quantity) external payable {
        if (msg.sender != tx.origin) revert NoContracts();
        if (mintEnabled == false) revert MintClosed();
        if (totalSupply() + _quantity > MAX_SUPPLY) revert MintedOut();
        if (msg.value >= price*_quantity) revert WrongPrice();
        require(mintClaimed[msg.sender] + _quantity <= 1, "MINT_MAXED");
        unchecked {
            mintClaimed[msg.sender] += _quantity;
        }
        _mint(msg.sender, _quantity);
    }

    function hasTokenBeenSprayed(address _contractAddress, uint _tokenId) view public returns (bool){
            return addressTokensSprayed[_contractAddress][_tokenId];
    }

    // Once someone sprays an NFT, you can't spray that same NFT again
    function spray(uint sprayId, address usingContractNFT, uint usingTokenId) external {
        // The block is hot, no spraying... yet.
        if (sprayEnabled == false) revert policeAround();

        // Prevents a token from being re-sprayed
        if (hasTokenBeenSprayed(usingContractNFT, usingTokenId)) revert alreadySprayed();

        require(ownerOf(sprayId) == msg.sender, "Not your spray");

        // ERC-721 check
        if (ERC165Checker.supportsInterface(usingContractNFT, ERC721InterfaceId)) {
            (bool success, bytes memory bytesUri) = usingContractNFT.call(
                abi.encodeWithSignature("tokenURI(uint256)", usingTokenId)
            );

            require(success, "Error getting tokenURI data");

            string memory uri = abi.decode(bytesUri, (string));

            spraycation[sprayId] = uri;
            addressTokensSprayed[usingContractNFT][usingTokenId] = true;
            unchecked { ++sprayCount; }

            emit Setter(sprayId, usingTokenId, usingContractNFT);

        // ERC-1155 check
        } else if (ERC165Checker.supportsInterface(usingContractNFT,ERC1155MetadataInterfaceId)) {
            (bool success, bytes memory bytesUri) = usingContractNFT.call(
                abi.encodeWithSignature("uri(uint256)", usingTokenId)
            );

            require(success, "Error getting URI data");
            string memory uri = abi.decode(bytesUri, (string));

            spraycation[sprayId] = uri;
            addressTokensSprayed[usingContractNFT][usingTokenId] = true;
            unchecked { ++sprayCount; }

            emit Setter(sprayId, usingTokenId, usingContractNFT);

        // Punks check
        } else if (usingContractNFT == 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB) {
            string memory uri = string.concat('punk ', toString(usingTokenId));

            spraycation[sprayId] = uri;
            addressTokensSprayed[usingContractNFT][usingTokenId] = true;
            unchecked { ++sprayCount; }

            emit Setter(sprayId, usingTokenId, usingContractNFT);

        } else {
            revert("Not an ERC-721 or ERC-1155");
        }
    }

    // Retrieved from OpenZeppelin's Strings.sol
    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
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

    function tokenURI(uint256 tokenId)
        public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(_baseTokenURI, _toString(tokenId), ".json"));
    }

    function _startTokenId() internal view virtual override returns (uint) {
        return 1;
    }

    // Setters

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        _baseTokenURI = _baseURI;
    }

    function setMintOpen(bool _val) external onlyOwner {
        mintEnabled = _val;
    }

    function setSprayOpen(bool _val) external onlyOwner {
        sprayEnabled = _val;
    }

    function setPrice(uint _wei) external onlyOwner {
        price = _wei;
    }

    // Withdraw

    function withdraw() external onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(sent, "Withdraw failed");
    }

}