// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract Rektyou is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 10000;
    uint256 public MAX_PUBLIC_MINT = 2;
    uint256 public MAX_WHITELIST_MINT = 3;
    uint256 public PUBLIC_SALE_PRICE = .01 ether;
    uint256 public FRIENDSHIP_SALE_PRICE = 0 ether;
    uint256 public WHITELIST_SALE_PRICE = 0 ether;

    uint64 private  password;
    string private  baseTokenUri;
    string public   baseExtension = ".json";
    
    bool public publicSale;
    bool public friendshipSale;
    bool public whiteListSale;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;

    constructor() ERC721A("Rektyou", "REKTYOU"){
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "Not Yet Active");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond Max Supply");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "Cannot mint beyond public max mint!");
        require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "Payment is below the price");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function friendshipmint(uint64 _password, uint256 _quantity) external payable callerIsUser{
        require(friendshipSale, "Not Yet Active");
        require(password == _password, "Incorrect password");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond Max Supply");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "Cannot mint beyond public max mint!");
        require(msg.value >= (FRIENDSHIP_SALE_PRICE * _quantity), "Payment is below the price");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser{
        require(whiteListSale, "Not Yet Active");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond Max Supply");
        require((totalWhitelistMint[msg.sender] + _quantity)  <= MAX_WHITELIST_MINT, "Cannot mint beyond whitelist max mint!");
        require(msg.value >= (WHITELIST_SALE_PRICE * _quantity), "Payment is below the price");
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), " You are not whitelisted");

        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function reserveMint(uint256 _quantity) external onlyOwner {
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Cannot mint beyond max supply");
        _safeMint(msg.sender, _quantity);
    }

    function devMint(address _to, uint256 _quantity) external onlyOwner {
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Cannot mint beyond max supply");
        _safeMint(_to, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId;

        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), baseExtension)) : "";
    }

    // @dev walletOf() function shouldn't be called on-chain due to gas consumption
    function walletOf() external view returns(uint256[] memory){
        address _owner = msg.sender;
        uint256 numberOfOwnedNFT = balanceOf(_owner);
        uint256[] memory ownerIds = new uint256[](numberOfOwnedNFT);

        for(uint256 index = 0; index < numberOfOwnedNFT; index++){
            ownerIds[index] = tokenOfOwnerByIndex(_owner, index);
        }

        return ownerIds;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleFriendshipSale() external onlyOwner{
        friendshipSale = !friendshipSale;
    }

    function toggleWhiteListSale() external onlyOwner{
        whiteListSale = !whiteListSale;
    }

    function setSupply(uint256 _newSupply) external onlyOwner {
        MAX_SUPPLY = _newSupply;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        PUBLIC_SALE_PRICE = _newPrice;
    }

    function setPassword(uint64 _newPassword) external onlyOwner {
        password = _newPassword;
    }
    
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function withdraw() external onlyOwner{
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "transfer failed");
    }
}