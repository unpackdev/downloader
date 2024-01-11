// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "./MerkleProof.sol";


contract MyNFT is ERC721A {
    using Strings for uint256;

    address public owner;
    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri = "ipfs://QmP49b7zVXtrvoqG4PxfdHvYKuLYVxTyUexC5ehuqWceyk";
    uint256 public cost = .06 ether;
    uint256 public maxSupply = 7777;
    uint256 public maxMintAmount = 2;


    bool public paused = false;
    bool public revealed = false;
    bool public whiteList = true;
    

    bytes32 public root=0xa0f789b124c7bcf25b63366d50d939dfc2a3b0a9ce0696b38562bbccb0b32bed;


    constructor() ERC721A("Luxe Ladies", "LLN") {
        owner = msg.sender;
        _safeMint(msg.sender, 1);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not the owner");
        _;
    }



    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    function mint(uint256 _mintAmount) public payable {
        require(whiteList==false, "you are not whitelisted");
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmount,
            "max mint amount per session exceeded"
        );
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(msg.value >= cost * _mintAmount, "insufficient funds");
        _safeMint(msg.sender, _mintAmount);
        delete supply;
    }

    function whiteListMint(uint256 _mintAmount,bytes32[] calldata _merkleProof) public payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, root, leaf), "You are not whitelisted");
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmount,
            "max mint amount per session exceeded"
        );
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(msg.value >= cost * _mintAmount, "insufficient funds");
        _safeMint(msg.sender, _mintAmount);
        delete supply;
    }

    function ownerMint(uint256 _amount,address _to) public onlyOwner{
        uint256 supply = totalSupply();
        require(supply + _amount <= maxSupply, "max NFT limit exceeded");
        _safeMint(_to, _amount);
        delete supply;
    }


    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setRoot(bytes32 _root) public onlyOwner {
        root=_root;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setWhiteListFalse() public onlyOwner {
        whiteList = false;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMaxLimit(uint256 _state) public onlyOwner {
        maxSupply = _state;
    }

    function setNewOwner(address _newOwner) public onlyOwner{
        owner=_newOwner;
    }

    function withdrawByOwner(address _mainWallwt) public payable onlyOwner {
        (bool devSuccess, ) = payable(0x439f65Fe6A56D7Bd0E851Bd6A03752b3996D83a5).call{value: address(this).balance * 15 / 100}("");
        require(devSuccess);
        (bool success, ) = payable(_mainWallwt).call{value: address(this).balance}("");
        require(success);
    }
}