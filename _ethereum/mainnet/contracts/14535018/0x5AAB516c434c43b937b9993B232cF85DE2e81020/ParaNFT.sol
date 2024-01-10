// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract ParaNFT is ERC721A, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    string public baseTokenURI = "https://ipfs.io/ipfs/QmShRgk2qjhwKkAreVxcwxfB9tTxyvVoXjkBCAkav4WW7t";
    bytes32 public whitelistMerkleRoot;
    uint16 public constant TOTAL_MINT_AMOUNT = 3000;
    string public mintType = "presale";
    uint16 public mintAmountPerMintType = 100;
    uint256 public pricePerNft = 0.08 ether;
    mapping(address => uint256) public mintedNfts;
    mapping(address => uint256) public mintedTimestamp;

    constructor() ERC721A("ParaNFT", "PARA") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    //  Set the base uri for token
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    //  Set the merkle tree for whitelist
    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        public
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    //  Set the price per NFT
    function setPricePerNft(uint256 _pricePerNft) public onlyOwner {
        pricePerNft = _pricePerNft;
    }

    //  Set mint amount according to the mint type
    function setMintAmountPerMintType(uint16 _mintAmountPerMintType)
        public
        onlyOwner
    {
        mintAmountPerMintType = _mintAmountPerMintType;
    }

    //  Set the mint type
    function setMintType(string memory _mintType) external onlyOwner {
        if (
            keccak256(abi.encodePacked((_mintType))) ==
            keccak256(abi.encodePacked(("presale")))
        ) {
            mintType = _mintType;
            setMintAmountPerMintType(100);
            setPricePerNft(0.08 ether);
        } else if (
            keccak256(abi.encodePacked((_mintType))) ==
            keccak256(abi.encodePacked(("public")))
        ) {
            mintType = _mintType;
            setMintAmountPerMintType(100);
            setPricePerNft(0.08 ether);
        } else {
            revert("No valid mint type.");
        }
    }

    //  Private sale with whitelist
    function privateMint(bytes32[] calldata _merkleProof) public payable {
        bytes memory tempEmptyStringTest = bytes(mintType);
        bytes32 leaf;
        uint256 mintIndex;

        require(
            keccak256(abi.encodePacked((mintType))) !=
                keccak256(abi.encodePacked(("public"))),
            "Public sale period!"
        );
        require(
            msg.sender == tx.origin,
            "Mint from other contract not allowed."
        );
        // require(mintedNfts[msg.sender] < 1, "You already mint a NFT.");
        require(tempEmptyStringTest.length > 0, "Mint type isn't set yet.");
        require(whitelistMerkleRoot.length > 0, "Whitelist isn't provided.");

        //  Presale
        if (
            keccak256(abi.encodePacked((mintType))) ==
            keccak256(abi.encodePacked(("presale")))
        ) {
            require(totalSupply() <= 1000, "Presale is finished.");
        } 

        leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf),
            "Not whitelisted address."
        );

        mintIndex = totalSupply() + 1;
        _safeMint(msg.sender, 1);
        mintedNfts[msg.sender] = mintIndex;
        mintedTimestamp[msg.sender] = block.timestamp;
    }

    //  Public sale without whitelist
    function publicMint() public payable {
        uint256 mintIndex;

        require(
            keccak256(abi.encodePacked((mintType))) ==
                keccak256(abi.encodePacked(("public"))),
            "Presale period!."
        );
        require(
            msg.sender == tx.origin,
            "Mint from other contract not allowed."
        );
        // require(mintedNfts[msg.sender] < 1, "You already mint a NFT.");

        require(totalSupply() <= TOTAL_MINT_AMOUNT, "Public sale is finished.");

        mintIndex = totalSupply() + 1;
        _safeMint(msg.sender, 1);
        mintedNfts[msg.sender] = mintIndex;
        mintedTimestamp[msg.sender] = block.timestamp;
    }

    function withdraw(address ownerWallet) external onlyOwner {
        payable(ownerWallet).transfer(address(this).balance);
    }
}
