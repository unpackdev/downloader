// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract BallyOnTheBlock is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant MAX_WHITELIST_MINT = 7;

    uint256 public constant PHASE_1_SUPPLY = 250;
    uint256 public constant PHASE_2_SUPPLY = 777;
    uint256 public constant PHASE_3_SUPPLY = 1777;
    uint256 public constant PHASE_4_SUPPLY = 4277;
    uint256 public constant PHASE_5_SUPPLY = 7777;

    uint256 public constant PHASE_1_PRICE = .03 ether;
    uint256 public constant PHASE_2_PRICE = .04 ether;
    uint256 public constant PHASE_3_PRICE = .05 ether;
    uint256 public constant PHASE_4_PRICE = .06 ether;
    uint256 public constant PHASE_5_PRICE = .07 ether;

    string public  baseTokenUri;

    bool public isRevealed;
    bool public publicSale;
    bool public whiteListSale;
    bool public pause;

    uint256 public max_supply_current;
    uint256 public sale_price_current;

    bytes32 private merkleRoot;

    mapping(address => uint256) public totalPublicMint;
    mapping(address => uint256) public totalWhitelistMint;

    constructor() ERC721A("Bally on the Block", "BOTB") {

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Bally on the Block :: Cannot be called by a contract");
        _;
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(pause == false, "BOTB :: Minting Paused");
        require(publicSale, "BOTB :: Public sale not yet Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "BOTB :: Beyond max Supply");
        require((totalSupply() + _quantity) <= max_supply_current, "BOTB :: Beyond max supply of current phase");
        require(msg.value >= (sale_price_current * _quantity), "BOTB :: Below current sale price");
        require(_quantity <= 10, "BOTB :: 10 tokens max per transaction");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser{
        require(pause == false, "BOTB :: Minting Paused");
        require(whiteListSale, "BOTB :: Whitelist sale not yet active");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "BOTB :: Cannot mint beyond max supply");
        require((totalWhitelistMint[msg.sender] + _quantity)  <= MAX_WHITELIST_MINT, "BOTB :: Cannot mint beyond whitelist max mint!");
        require(msg.value >= (sale_price_current * _quantity), "BOTB :: Payment is below the price");
        require(_quantity <= 7, "BOTB :: 7 tokens max per transaction");
        //create leaf node
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, sender), "BOTB :: You are not whitelisted");

        totalWhitelistMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, tokenId.toString(), ".json")) : "";
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

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner{
        merkleRoot = _merkleRoot;
    }

    function getMerkleRoot() external view returns (bytes32){
        return merkleRoot;
    }

    function togglePause() external onlyOwner{
        pause = !pause;
    }

    function toggleWhiteListSale() external onlyOwner{
        whiteListSale = !whiteListSale;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner{
        uint256 withdrawAmount_600 = address(this).balance * 60/100;
        uint256 withdrawAmount_225 = address(this).balance * 225/1000;
        uint256 withdrawAmount_50 = address(this).balance * 5/100;
        uint256 withdrawAmount_25 = address(this).balance * 25/1000;
        uint256 withdrawAmount_10 = address(this).balance - withdrawAmount_600 - withdrawAmount_225 - withdrawAmount_50 - withdrawAmount_25;
        
        payable(0x370482EA907f056f978Dd1453eB30D52aF05af0C).transfer(withdrawAmount_600);
        payable(0xfC6406D5CE87035D55EBa4eBa2d1f62699FFB7CA).transfer(withdrawAmount_225);
        payable(0x7FC9B8B2c24262C49B7D6ED2b126bA62dD02e538).transfer(withdrawAmount_50);
        payable(0x841ca19a454B327c5a0624871d7f9F1bAb2Fa849).transfer(withdrawAmount_25);
        payable(0x43bDB395E6d8015640f7BFe677a252B340B7237f).transfer(withdrawAmount_10);
    }

    function getMintPrice() external view returns (uint256) {
        return sale_price_current;
    }

    function getCurrentMaxSupply() external view returns (uint256) {
        return max_supply_current;
    }

    function activatePhase1() external onlyOwner {
        sale_price_current = PHASE_1_PRICE;
        max_supply_current = PHASE_1_SUPPLY;
    }

    function activatePhase2() external onlyOwner {
        sale_price_current = PHASE_2_PRICE;
        max_supply_current = PHASE_2_SUPPLY;
    }

    function activatePhase3() external onlyOwner {
        sale_price_current = PHASE_3_PRICE;
        max_supply_current = PHASE_3_SUPPLY;
    }

    function activatePhase4() external onlyOwner {
        sale_price_current = PHASE_4_PRICE;
        max_supply_current = PHASE_4_SUPPLY;
    }

    function activatePhase5() external onlyOwner {
        sale_price_current = PHASE_5_PRICE;
        max_supply_current = PHASE_5_SUPPLY;
    }
}