//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./console.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract Waifu is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;
    
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public cost = 0.05 ether;
    uint256 public whitelistCost = 0.069 ether;
    uint256 public maxSupply = 6969;
    uint256 private ownerMinted = 0;

    bool public paused = true;
    bool public revealed = false;
    bool public onlyWhitelisted = true;
    
    bytes32 public merkleRoot;

    address private a1 = 0x943405d0d429C865affcC487270A1cFE3a6B9A71;
    address private a2 = 0x38482Dc0050Dc32c66e41b9D5ae8b7383EC3bb49;
    address private a3 = 0xE9Cd9e74dA2c357B3A0423a06a33d5157B7280AE;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        setHiddenMetadataUri("ipfs://QmWJ5BBdnm4ibqJkzkPchL5priksAgxCCAtsV9xk7Mycfe/hidden.json");
    }


    modifier mintCompliance(uint256 _mintAmount) {
        require(!paused, "Minting is not live yet");
        require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
        uint256 actualCost = onlyWhitelisted ? whitelistCost : cost;
        require(msg.value >= actualCost * _mintAmount, "Insufficient funds!");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
        _mintLoop(msg.sender, _mintAmount);
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");
        _mintLoop(msg.sender, _mintAmount);
    }
  
    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
        _mintLoop(_receiver, _mintAmount);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(_tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : "";
    }

    //only owner
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyWhitelist(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function withdraw() public payable onlyOwner {
        uint256 mintFees = address(this).balance;
        (bool hs, ) = payable(a1).call{value: mintFees * 5500 / 10000}("");
        require(hs);
        (bool os, ) = payable(a2).call{value: mintFees * 2250 / 10000}("");
        require(os);
        (bool ls, ) = payable(a3).call{value: mintFees * 2250 / 10000}("");
        require(ls);
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
        supply.increment();
        _safeMint(_receiver, supply.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
