// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract GrumpyHedgehogs is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 2000;
    uint256 public constant MAX_PUBLIC_MINT = 4;
    uint256 public constant MAX_WHITELIST_MINT = 2;
    uint256 public constant MAX_GOAT_MINT = 2;
    uint256 public constant PUBLIC_SALE_PRICE = .05 ether;
    uint256 public constant WHITELIST_SALE_PRICE = .03 ether;
    string private  baseTokenUri;

    //deploy smart contract, toggle WL, toggle WL when done, toggle publicSale 
    //2 days later toggle reveal
    bool public publicSale;
    bool public whiteListSale;
    bool public goatSale;
    bool public pause;
    bool public teamMinted;

    bytes32 private merkleRoot;
    bytes32 private goatMerkleRoot;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;
    mapping(address => uint256) public totalGoatMint;

    constructor() ERC721A("Grumpy Hedgehog Society", "GHS"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "Minting hasn't started yet.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "We are out of Hedgies :(");
        require((totalPublicMint[msg.sender] +_quantity) <= MAX_PUBLIC_MINT, "Limit exceeds max amount.");
        require(msg.value >= (PUBLIC_SALE_PRICE * _quantity), "Specified payment quantity is incorrect.");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function goatMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser{
        require(goatSale, "Goat mint hasn't started yet.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "We are out of Hedgies :(");
        require((totalGoatMint[msg.sender] + _quantity)  <= MAX_GOAT_MINT, "Limit exceeds max amount.");        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, goatMerkleRoot, sender), "You are not whitelisted for free mint.");
        totalGoatMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser{
        require(whiteListSale, "Whitelist mint hasn't started yet.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "We are out of Hedgies :(");
        require((totalWhitelistMint[msg.sender] + _quantity)  <= MAX_WHITELIST_MINT, "Limit exceeds max amount.");
        require(msg.value >= (WHITELIST_SALE_PRICE * _quantity), "Specified payment quantity is incorrect.");
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "You are not whitelisted");

        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamMint() external onlyOwner{
        require(!teamMinted, "Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 17);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }

    /// @dev walletOf() function shouldn't be called on-chain due to gas consumption
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
   
    function setMaxSupply(uint256 _MAX_SUPPLY) external onlyOwner{
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }
    
    function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

    function setGoatMerkleRoot(bytes32 _goatMerkleRoot) external onlyOwner{
        goatMerkleRoot = _goatMerkleRoot;
    }

    function getGoatMerkleRoot() external view returns (bytes32){
        return goatMerkleRoot;
    }
    
    function togglePause() external onlyOwner{
        pause = !pause;
    }

    function toggleWhiteListSale() external onlyOwner{
        whiteListSale = !whiteListSale;
    }

    function toggleGoatSale() external onlyOwner{
        goatSale = !goatSale;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }



    function withdraw() external onlyOwner{
        //35% to utility/investors wallet
        uint256 withdrawAmount = address(this).balance;
        payable(0x0fffFD62CcCB458faE551Be0EF1058EF854d1808).transfer(withdrawAmount);
        payable(msg.sender).transfer(address(this).balance);
    }

    function count() public view returns (uint256) {
        uint256 numberOfOwnedNFT = balanceOf(msg.sender);
        return numberOfOwnedNFT;
    }

}