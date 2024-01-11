// SPDX-License-Identifier: MIT
/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@%%%%%@@@@@@%%,,,,%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@%,,,,,%@@@@@%,,,,,/%@@%%##%%@@@@@@@@@%%%@@@@@%#,,,,,,,,,*#%@@%%%@@@%#,,,,/%@@@@@@@@@@@@@@%#,,#%@@@@@@@@%%%%%@@@@@@
@%,,,,,%@@@@@%,,,,,/%@%,,,,,,*%@@@@@%,,,,,%@%#,,,,,,,,,,,,,,%,,,,,%@@%,,,,#%%%%%@@@@@@@@@%,,,,,*%@@%#,,,,,,,,,,*%@@
@%,,,,,%@@@@@%,,,,,/%%,,,,,,,,,%@@@%*,,,,,%@%,,,,,*%%##/**#%,,,,,,%@@%/,,/%,,,,,,/%@@@@@@%,,,,,/%%,,,,,,,,,,,,,,%@@
@%,,,,,#@@@@@%,,,,,/%/,,,,,,,,,,%@@%,,,,,#%@%,,,,,*%@@@@@@@%,,,,,%@@%*,,,,*,,,,,,,,,#%@@@%,,,,,#(,,,,,,%%%%%%%%%@@@
@%,,,,,,,,,,,,,,,,,/%,,,,,#,,,,,,%%/,,,,,%@@%,,,,,*####%%@%*,,,,,%@@%,,,,,/*,,,,,,,,,,,%%%,,,,,%,,,,,(%,,,,,,,,(%@@
@%,,,,,,,,,,,,,,,,,//,,,,,/,,,,,,,%,,,,,*%@@%*,,,,,,,,,,,%%,,,,,(%@@%,,,,,//,,,,,#,,,,,,,,,,,,,#,,,,,%%,,,,,,,,,*%@
@%*,,,,,%%%%%%,,,,,/,,,,,,,,,,,,,,,,,,,,/%@@%/,,,,,,,,,,%%%,,,,,%@@@%,,,,,#%,,,,,%@%(,,,,,,,,,,%,,,,,,%@@@%,,,,,,%@
@%#,,,,,%@@@@%,,,,,,,,,,,,,,(%,,,,,,,,,,,,,,/%,,,,,%@@@@@@%,,,,,,,,,(,,,,,#%,,,,,/%@@@%#,,,,,,#%%,,,,,,,,,,,,,,,%@@
@@%,,,,*%@@@@%/,,,,/,,,,(%@@@@%,,,,%,,,,,,,,,(,,,,,#%@@@@@@%,,,,,,,,,%*,*%%%#,,,,#%@@@@@@@%%%@@@@%%,,,,,,,,,,,#%@@@
@@@@@@@@@@@@@@@%%%%@%%%%@@@@@@@@@@@@@%%%%%%%%%%,,,/%@@@@@@@@@%%%%%%%%@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@%%%%##%%%@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%#%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%,,,,,,,,,,,,(%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%/,,,,,,*%@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@%/,,,,,,,,,,,,,,%%@@@@@%%%(/%/%%%@@@%,,,,,,,,,,(%%@@%%,,,,,,,,,,,%@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@%%,,,,,,(%%@@@@@@@@@@@@%*,,,,,,,,,,,%%/,,,,,,,,,,,,,,%#,,,,,,(%%%%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@%@%,,,,,*%%%%%%%%%%%%%@%/,,,,,,,,,,,,,,*%,,,,,%%%/,,,,,,#,,,,,,#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%/,,,,,%(,,,,,,,,,,,,%*,,,,,%%@@@%,,,,,#,,,,,%@@@%,,,,,*%,,,,,,,,/%@%@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%/,,,,,%%(,,,,,,,,,,,*,,,,,%@@@@@%,,,,,#,,,,,%@@%*,,,,,%@@%%,,,,,,,/%@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@%@%,,,,,,%%@@@@%*,,,,,#,,,,,,%%%%/,,,,,,#,,,,,/,,,,,,,,%%%((%%%,,,,,,%@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@%,,,,,,,,,,,,,,,,,%%%,,,,,,,,,,,,,,#%/,,,,,,,,,,,,%%%,,,,,,,,,,,,%@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@%*,,,,,,,,,,,,%%@@@%%#,,,,,,,,(%%@@%*,,,,,,(%%@@@@@%(,,,,,,,#%%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%##%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./MerkleProof.sol";
//import "./Counters.sol";
import "./Ownable.sol";

contract HalflingGods is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string private _baseURIextended;
    string public extension = "";

    uint256 public MAX_SUPPLY = 5556;
    uint256 public constant MAX_FREE_MINT = 21;
    uint256 public constant MAX_UNIQUE_MINT = 56;
    uint256 public constant MIN_UNIQUE_TOKEN = 9;
    uint256 public constant PRICE_PER_TOKEN = 0.0099 ether;

    // notstarted | freemint | publicsale | uniquesale | closed
    string public status = "notstarted";
    bool private is_SaleStart = false;
    bool private is_FreeMintStart = false;
    bool private is_PublicSaleStart = false;
    bool private is_UniqueSaleStart = false;
    bool private is_SaleClosed = false;

    // Free mint white list
    mapping(address => bool) private WL_WalletList;
    // Unique mint white list
    mapping(address => bool) private UM_WalletList;
    // Merkle Root
    bytes32 private _merkleRoot;
    // Unique mint purchase count
    uint256 public uniqueMintCount = 0;

    constructor() ERC721("HalflingGods", "HGODS") {}

    // Set the MerkleRoot
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        _merkleRoot = _root;
    }
    // Get the count from UM address
    function getPreSaleMintApprove() public view returns (bool){
        return WL_WalletList[msg.sender];
    }
    // Get the count from UM address
    function getUniqueSaleMintApprove() public view returns (bool){
        return UM_WalletList[msg.sender];
    }

    // Mint Free
    function mintFree(uint256 numberOfTokens, bytes32[] memory proof) external payable {
        uint256 ts = totalSupply();
        require(is_FreeMintStart, "Free Mint is not active.");
        require(!WL_WalletList[msg.sender], "Address already claimed");
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender))), "Not a part of Allowlist");
        require(numberOfTokens < MAX_FREE_MINT, "Exceeded max available to purchase");
        require(ts + numberOfTokens < MAX_SUPPLY, "Purchase would exceed max tokens");

        WL_WalletList[msg.sender] = true;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }
    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, _merkleRoot, leaf);
    }

    // Mint Public
    function mintPublic(uint numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(is_PublicSaleStart, "Public Sale is not active.");
        require(ts + numberOfTokens < (MAX_SUPPLY - MAX_UNIQUE_MINT + 1), "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "ETH value sent is not correct");

        // Set the Unique Mint WL address
        if (numberOfTokens > MIN_UNIQUE_TOKEN) {
            UM_WalletList[msg.sender] = true;
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }
    // Mint Unique
    function mintUnique(uint256 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(is_UniqueSaleStart, "Unique Mint is not active");
        require(uniqueMintCount < MAX_UNIQUE_MINT, "Unique mint exceed max tokens");
        require(UM_WalletList[msg.sender], "You are not in the unique mint list");
        require(numberOfTokens == 1, "Exceeded max available to purchase");
        require(ts + numberOfTokens <= MAX_SUPPLY, "Purchase exceed max tokens");

        uniqueMintCount++;

        UM_WalletList[msg.sender] = false;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }
    // Reserve
    function reserve(uint256 numberOfTokens) public onlyOwner {
        uint256 ts = totalSupply();
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    // Core
    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setExtension(string memory _extension) external onlyOwner {
        extension = _extension;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), extension)) : "";
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Status Changers
    function Start_Sale() public onlyOwner {
        status = "freemint";
        is_SaleStart = true;
        is_FreeMintStart = true;
        is_PublicSaleStart = false;
        is_UniqueSaleStart = false;
        is_SaleClosed = false;
    }

    function Start_PublicSale() public onlyOwner {
        status = "publicsale";
        is_SaleStart = true;
        is_FreeMintStart = false;
        is_PublicSaleStart = true;
        is_UniqueSaleStart = false;
        is_SaleClosed = false;
    }

    function Start_UniqueSale() public onlyOwner {
        status = "uniquesale";
        is_SaleStart = true;
        is_FreeMintStart = false;
        is_PublicSaleStart = false;
        is_UniqueSaleStart = true;
        is_SaleClosed = false;
    }

    function Close_Sale() public onlyOwner {
        status = "closed";
        is_SaleStart = true;
        is_FreeMintStart = false;
        is_PublicSaleStart = false;
        is_UniqueSaleStart = false;
        is_SaleClosed = true;
    }

    function Reset_Status() public onlyOwner {
        status = "notstarted";
        is_SaleStart = false;
        is_FreeMintStart = false;
        is_PublicSaleStart = false;
        is_UniqueSaleStart = false;
        is_SaleClosed = false;
    }

    // Decrease the supply
    function supplyDecrease(uint256 numberOfTokens) external onlyOwner {
        uint256 ts = totalSupply();
        if (numberOfTokens == 0) {
            numberOfTokens = MAX_SUPPLY - ts;
        }
        require(ts <= MAX_SUPPLY - numberOfTokens, "Can not decrease");
        MAX_SUPPLY -= numberOfTokens;
    }

    // Overrides
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

}
