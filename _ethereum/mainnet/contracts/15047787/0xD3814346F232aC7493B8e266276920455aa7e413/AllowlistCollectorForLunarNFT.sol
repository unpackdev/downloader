// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract AllowlistCollectorForLunarNFT is Ownable, ERC721A {
    string public baseURI = "https://raw.githubusercontent.com/LunarNFT/LunarNFTContract/main/metadata/json/";
    string public blindURL = "https://raw.githubusercontent.com/LunarNFT/LunarNFTContract/main/metadata/json/nonreveal.json";
    uint256 public constant priceOG = 0.10 ether;
    uint256 public constant priceWL = 0.088 ether;
    uint256 public constant price = 0.30 ether;
    uint8 public maxOGTMint = 1;
    uint8 public maxPresaleMint = 1;
    uint8 public maxPublicMint = 10;
    uint256 public maxPresaleSupply = 3333;
    uint256 public maxTokens = 3333;
    bool public isPresaleActive = false;
    bool public isPublicActive = false;
    bool public isFreeMintActive = true;
    bool public isRevealActive = true;
    bytes32 public presaleMerkleRoot;

    mapping (address => uint256) public mintedForPresale;
    mapping (address => uint256) public mintedForPublic;

    constructor(bytes32 presaleRoot, uint256 numberOfTokens) 
        ERC721A("LunarNFTAllowlist", "collector")  {
        presaleMerkleRoot = presaleRoot;
        if (numberOfTokens > 0) ownerMint(numberOfTokens, true);
    }

    //Presale mint function
    function mintPresale(uint256 numberOfTokens, uint8 tier, bytes32[] calldata proof) external payable {
        require(isPresaleActive, "PRESALE_MINT_IS_NOT_YET_ACTIVE");
        require(MerkleProof.verify(proof, presaleMerkleRoot, keccak256(abi.encodePacked(msg.sender, tier))), "INVALID_WHITELIST_PROOF");
        if(tier == 0) {
            require(mintedForPresale[msg.sender] + numberOfTokens <= maxOGTMint, "EXCEEDS_MAX_OG_MINT" );
            require(msg.value == priceOG * numberOfTokens, "INSUFFICIENT_OG_PAYMENT");
        } else {
            require(mintedForPresale[msg.sender] + numberOfTokens <= maxPresaleMint, "EXCEEDS_MAX_PRESALE_MINT" ); 
            require(msg.value == priceWL * numberOfTokens, "INSUFFICIENT_PRESALE_PAYMENT");
        }
        require(totalSupply() + numberOfTokens <= maxPresaleSupply, "EXCEEDS_MAX_PRESALE_SUPPLY" );
        
        mintedForPresale[msg.sender] += numberOfTokens;
        _safeMint( msg.sender, numberOfTokens);
    }

    //Public mint function
    function mintPublicSale(uint256 numberOfTokens) external payable {
        require(isPublicActive, "PUBLIC_SALE_MINT_IS_NOT_YET_ACTIVE");
        require(msg.value == price * numberOfTokens, "INSUFFICIENT_PUBLIC_PAYMENT");
        require(mintedForPublic[msg.sender] + numberOfTokens <= maxPublicMint, "EXCEEDS_MAX_PUBLIC_MINT" );
        require(totalSupply() + numberOfTokens <= maxTokens, "EXCEEDS_MAX_SUPPLY" );

        mintedForPublic[msg.sender] += numberOfTokens;
        _safeMint( msg.sender, numberOfTokens);
    }

    //Free mint function
    function mintFreeSale(uint256 numberOfTokens) external payable onlyOwner {
        require(isFreeMintActive, "FREE_SALE_MINT_IS_NOT_YET_ACTIVE");
        require(msg.value == 0, "INSUFFICIENT_FREESALE_PAYMENT");
        require(totalSupply() + numberOfTokens <= maxTokens, "EXCEEDS_MAX_SUPPLY" );
        _safeMint( msg.sender, numberOfTokens);
    }

    function ownerMint(uint256 numberOfTokens, bool _isRevealActive) public onlyOwner {
        require(totalSupply() + numberOfTokens <= maxTokens, "EXCEEDS_MAX_SUPPLY" );
        isRevealActive = _isRevealActive;
        _safeMint(owner(), numberOfTokens);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if(!isRevealActive) {return blindURL;}
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId)))
            : "";
    }

    // SETTER FUNCTIONS
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setPresaleMerkleRoot(bytes32 presaleRoot) external onlyOwner {
        presaleMerkleRoot = presaleRoot;
    }

    function setMaxPresaleMint(uint8 _maxPresaleMint) external onlyOwner {
        maxPresaleMint = _maxPresaleMint;
    }

    function setMaxPresaleMintSupply(uint256 _maxPresaleMintSupply) external onlyOwner {
        maxPresaleSupply = _maxPresaleMintSupply;
    }

    // TOGGLES
    function togglePublicSaleActive() external onlyOwner {
        isPublicActive = !isPublicActive;
    }

    function togglePresaleActive() external onlyOwner {
        isPresaleActive = !isPresaleActive;
    }

    function toggleFreeMintActive() external onlyOwner {
        isFreeMintActive = !isFreeMintActive;
    }

    function toggleRevealActive() external onlyOwner {
        isRevealActive = !isRevealActive;
    }

    // Withdraw Ether
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Failed to withdraw payment");
    }
}
