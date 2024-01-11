// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//                        _     __         __
//      __  ______  _____(_)___/ /__  ____/ /___ _      ______  ___  _________
//     / / / / __ \/ ___/ / __  / _ \/ __  / __ \ | /| / / __ \/ _ \/ ___/_  /
//    / /_/ / /_/ (__  ) / /_/ /  __/ /_/ / /_/ / |/ |/ / / / /  __/ /    / /_
//    \__,_/ .___/____/_/\__,_/\___/\__,_/\____/|__/|__/_/ /_/\___/_/    /___/
//        /_/
//
//      https://upsidedownerz.xyz

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract UpsideDownerz is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public price = 0.01 ether;
    uint8 public mintsPerWallet;
    uint256 public freeSupply;
    uint256 public maxSupply;
    uint256 public reservedSupply;
    bytes32 public merkleRoot;

    bool public paused = true;
    bool public reserved = true;
    bool public revealed = false;

    string public hiddenMetadataUri;
    string public baseURI;

    constructor(
        uint256 _maxSupply,
        uint256 _freeSupply,
        uint8 _mintsPerWallet
    ) ERC721A("UpsideDownerz", "UPDOWN") {
        maxSupply = _maxSupply;
        freeSupply = _freeSupply;
        mintsPerWallet = _mintsPerWallet;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint8 _mintAmount) public payable {
        require(msg.value >= price * _mintAmount, "Insufficent payment");
        require(!paused, "Paused");
        require(
            _mintAmount + _numberMinted(msg.sender) <= mintsPerWallet,
            "Allowance exceeded"
        );
        require(_totalMinted() + _mintAmount <= maxSupply, "No more remain");
        require(
            (price == 0 && reserved == false) ||
                (price == 0 &&
                    reserved == true &&
                    _totalMinted() + _mintAmount <=
                    maxSupply - reservedSupply) ||
                (price > 0 &&
                    _totalMinted() + _mintAmount <= maxSupply - freeSupply),
            "No supply available"
        );
        _safeMint(msg.sender, _mintAmount);
    }

    function mintReserved(bytes32[] calldata proof) public {
        require(!paused, "Paused");
        require(reserved == true && price == 0, "Invalid claim period");
        require(
            mintsPerWallet + _numberMinted(msg.sender) <= mintsPerWallet,
            "Allowance exceeded"
        );
        require(_totalMinted() + mintsPerWallet <= maxSupply, "No more remain");
        require(
            MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Invalid proof"
        );

        _safeMint(msg.sender, mintsPerWallet);
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function remainingMints(address userAddress) public view returns (uint256) {
        return mintsPerWallet - _numberMinted(userAddress);
    }

    function freeMint() public onlyOwner {
        price = 0 ether;
    }

    function setReservedList(bytes32 _merkleRoot, uint256 _reservedSupply)
        external
        onlyOwner
    {
        merkleRoot = _merkleRoot;
        reservedSupply = _reservedSupply;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Token does not exist");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString()))
                : "";
    }

    function setRevealed(bool _revealed) public onlyOwner {
        revealed = _revealed;
    }

    function setReserved(bool _reserved) public onlyOwner {
        reserved = _reserved;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setBaseUri(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}
