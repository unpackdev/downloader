//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract OnOGenesis is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.06 ether;
    uint256 public whitelistCost = 0.05 ether;
    uint256 public maxSupply = 314;
    uint256 public maxMintAmount = 10;

    bool public giftSaleOpen = false;
    bool public whitelistSaleOpen = false;
    bool public generalSaleOpen = false;
    bytes32 public whitelistRoot;
    mapping(address => uint256) public giftList;
    mapping(address => uint256) public giftsClaimed;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        uint256 _initMintNumber
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        if (_initMintNumber > 0) {
            ownerMint(msg.sender, _initMintNumber);
        }
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    modifier mintBaseConditionsFullfilled(uint256 _mintAmount) {
        require(totalSupply() + _mintAmount <= maxSupply, "not enough tokens left");
        require(_mintAmount <= maxMintAmount, "request exceeds max minting amount");
        require(_mintAmount > 0, "must mint at least one token");
        _;
    }

    modifier giftClaimable(uint256 _mintAmount) {
        require(giftSaleOpen, "gift minting is currently closed");
        require(giftsClaimed[msg.sender] + _mintAmount <= giftList[msg.sender], "you do not have enough gifts left");
        _;
    }

    modifier isOnWhitelist(bytes32[] calldata _merkleProof) {
        require(onWhitelist(msg.sender, _merkleProof) == true, "address not on whitelist");
        _;
    }

    modifier whitelistSaleIsOpen() {
        require(whitelistSaleOpen || generalSaleOpen, "minting for whitelist is currently closed");
        _;
    }

    modifier generalSaleIsOpen() {
        require(generalSaleOpen, "minting for general public is currently closed");
        _;
    }

    function ownerMint(address _to, uint256 _mintAmount) public onlyOwner nonReentrant {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "must mint at least one token");
        require(supply + _mintAmount <= maxSupply, "not enough tokens left");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    // public
    function giftMint(address _to, uint256 _mintAmount)
        public
        giftClaimable(_mintAmount)
        mintBaseConditionsFullfilled(_mintAmount)
        nonReentrant
    {
        uint256 supply = totalSupply();
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
        giftsClaimed[msg.sender] += _mintAmount;
    }

    function whitelistMint(address _to, uint256 _mintAmount, bytes32[] calldata _merkleProof)
        public
        payable
        whitelistSaleIsOpen
        isOnWhitelist(_merkleProof)
        mintBaseConditionsFullfilled(_mintAmount)
        nonReentrant
    {
        uint256 supply = totalSupply();
        require(msg.value >= whitelistCost * _mintAmount, "not enough funds to mint");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function generalMint(address _to, uint256 _mintAmount)
        public
        payable
        generalSaleIsOpen
        mintBaseConditionsFullfilled(_mintAmount)
        nonReentrant
    {
        uint256 supply = totalSupply();
        require(msg.value >= cost * _mintAmount, "not enough funds to mint");
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
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

    function onWhitelist(address _to, bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_to));
        return MerkleProof.verify(_merkleProof, whitelistRoot, leaf);
    }

    function onGiftList(address _to) public view returns(bool) {
        return giftList[_to] > 0;
    }

    function hasGiftsClaimable(address _to) public view returns(bool) {
        return giftList[_to] > giftsClaimed[_to];
    }

    function giftsClaimable(address _to) public view returns(uint256) {
        return giftList[_to] - giftsClaimed[_to];
    }

    //only owner
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setWhitelistCost(uint256 _newCost) public onlyOwner {
        whitelistCost = _newCost;
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
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

    function setGiftSaleOpen(bool _state) public onlyOwner {
        giftSaleOpen = _state;
    }

    function setWhitelistSaleOpen(bool _state) public onlyOwner {
        whitelistSaleOpen = _state;
    }

    function setGeneralSaleOpen(bool _state) public onlyOwner {
        generalSaleOpen = _state;
    }

    function addToGiftList(address _to, uint256 _amount) public onlyOwner {
        giftList[_to] = _amount;
    }

    function setWhitelistRoot(bytes32 _whitelistRoot) external onlyOwner {
        whitelistRoot = _whitelistRoot;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

}
