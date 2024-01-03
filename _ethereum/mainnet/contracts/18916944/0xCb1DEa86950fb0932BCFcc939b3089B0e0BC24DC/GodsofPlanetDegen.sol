// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ERC721A.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";


contract GodsofPlanetDegen is ERC721A, Ownable, ReentrancyGuard, Pausable{

    // uint256 variables
    uint256 public maxSupply = 250;
    uint256 public publicSupply = 113;
    uint256 public mintPrice = 0.099 ether; // @dev 10 finney = 0.01 ether
    uint256 public wlMaxMint = 1;
    uint256 public wlMintPrice = 0.099 ether;

    //base uri
    string public baseURI;

    // booleans
    bool public publicMintEnabled = false;
    bool public wlMintEnabled = false;

    // mappings to keep track of # of minted tokens per user
    mapping(address => uint256) public totalWlMint;
    mapping(address => uint256) public totalPubMints;

    bytes32 public root;

    constructor (
        string memory _initBaseURI,
        bytes32 _root
        ) ERC721A("Gods of Planet Degen", "PDG") {
            setBaseURI(_initBaseURI);
            setRoot(_root); 
    }

    function airdrop(address[] calldata _address, uint256 _amount) external onlyOwner nonReentrant {

        require(totalSupply() + _amount <= maxSupply, "Error: max supply reached");

        for (uint i = 0; i < _address.length; i++) {
            _safeMint(_address[i], _amount);
        }
    }

    // Whitelist mint that requires merkle proof; user receives 1 free 
    function whitelistMint(uint256 _quantity, bytes32[] memory proof) external payable whenNotPaused nonReentrant {
        
            require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of whitelist");
            require(wlMintEnabled, "Whitelist mint is currently paused");
            require(totalSupply() + _quantity <= publicSupply, "Error: max supply reached");
            require((totalWlMint[msg.sender] + _quantity) <= wlMaxMint, "Error: Cannot mint more than 1");
            require(msg.value >= (_quantity * wlMintPrice), "Not enough ether sent");

            totalWlMint[msg.sender] += _quantity;
            _safeMint(msg.sender, _quantity);

    }
    

    // verify merkle proof with a buf2hex(keccak256(address)) or keccak256(abi.encodePacked(address))
    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns(bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    // Public mint with 5 per tx limit

    function publicMint(uint256 _quantity) external payable whenNotPaused nonReentrant {
        require(publicMintEnabled, "Public mint is currently paused");
        require(msg.value >= (_quantity * mintPrice), "Not enough ether sent");
        require(totalSupply() + _quantity <= publicSupply, "Error: max supply reached");

        totalPubMints[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    

    // returns the baseuri of collection
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // override _startTokenId() from erc721a to start tokenId at 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // return tokenUri given the tokenId

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
    ? string(abi.encodePacked(currentBaseURI, _toString(tokenId)))
    : "";
        
    }

    // owner updates and functions

    function togglePublicMint() external onlyOwner nonReentrant{
        publicMintEnabled = !publicMintEnabled;
    }

    function toggleWlMint() external onlyOwner nonReentrant{
        wlMintEnabled = !wlMintEnabled;
    }

    function enableBothMints() external onlyOwner nonReentrant{
        wlMintEnabled = true;
        publicMintEnabled = true;
    }

    function setPrice(uint256 _mintPrice) external onlyOwner nonReentrant{
    mintPrice = _mintPrice;
    }

    function setWlPrice(uint256 _wlMintPrice) external onlyOwner nonReentrant{
    wlMintPrice = _wlMintPrice;
    }

    function setmaxWl(uint256 _wlMaxMint) external onlyOwner nonReentrant{
    wlMaxMint = _wlMaxMint;
    }
  
    function pause() public onlyOwner nonReentrant{ 
        _pause();
    }

    function unpause() public onlyOwner nonReentrant{
        _unpause();
    }

    function setBaseURI(string memory _newURI) public onlyOwner nonReentrant{
        baseURI = _newURI;
    }

    function setRoot(bytes32 _root) public onlyOwner nonReentrant {
        root = _root;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner nonReentrant {
        maxSupply = _maxSupply;
    }

    function setPublicSupply(uint256 _publicSupply) external onlyOwner nonReentrant {
        publicSupply = _publicSupply;
    }

    function withdraw() external onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawPercentage(uint256 _percent) external onlyOwner nonReentrant {
        require(_percent <= 100, "Percent cannot be greater than 100");
        payable(owner()).transfer(address(this).balance * _percent / 100);
    }
    

}