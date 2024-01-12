// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ECDSA.sol";

contract WildpawsGeneral is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    //sales
    enum SaleStatus {
        PAUSED,
        ALLOWLIST,
        PUBLIC
    }    
    
    SaleStatus public saleStatus = SaleStatus.PAUSED;
    string public PROVENANCE;
    string private _baseURIextended;
    string private initialURI;
    string private phase1URI;
    string public uriSuffix = ".json";

    //Configuration
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant MAX_SUPPLY_COMMON = 4550;
    uint256 public constant MAX_SUPPLY_RARE = 980;
    uint256 public constant MAX_SUPPLY_LEGENDARY = 25;

    //public sales
    uint256 public constant PRICE_COMMON_TOKEN = 0.08 ether;
    uint256 public constant PRICE_RARE_TOKEN = 0.19 ether;
    uint256 public constant PRICE_LEGENDARY_TOKEN = 0.28 ether;    
    mapping(address => uint256) public publicSalesMinterToTokenQty;

    //allowlist sales
    bytes32 public allowlistMerkleRoot;
    mapping(address => uint256) public allowlistSalePurchased;


    mapping(uint256 => uint256) private _mintedDate;

    constructor(
        string memory _initialURI,
        string memory _phase1URI,
        string memory _basesURI
      
    ) ERC721A("WildpawsGeneral", "WPGENERAL") {
        setInitialURI(_initialURI);
        setPhase1URI(_phase1URI);
        setBaseURI(_basesURI);
    }
    event Minted(
        string Type,
        uint256 lastTokenId,
        uint256 quantity,
        address mintedAddress
        );


    modifier mintCompliance(uint256 qtyCommon, uint256 qtyRare, uint256 qtyLegendary) {
        uint256 quantity = qtyCommon + qtyRare + qtyLegendary;
        if (qtyCommon > 0){ 
            require(totalMintedCommon() + qtyCommon <= MAX_SUPPLY_COMMON, 'Max supply for common token exceeded!');
        }
        if (qtyRare > 0){ 
            require(totalMintedRare() + qtyRare <= MAX_SUPPLY_RARE, 'Max supply for rare token exceeded!');
        }
        if (qtyLegendary > 0){ 
            require(totalMintedLegendary() + qtyLegendary <= MAX_SUPPLY_LEGENDARY, 'Max supply for legendary token exceeded!');
        }
        require(totalSupply() + quantity <= MAX_SUPPLY, 'Max supply exceeded!');
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function getRemainingSupply() public view returns (uint256) {
        unchecked { return MAX_SUPPLY - totalSupply(); }
    }
    function getTotalMintedCommon() public view returns (uint256) {
        return totalMintedCommon();
    }
    function getTotalMintedRare() public view returns (uint256) {
        return totalMintedRare();
    }
    function getTotalMintedLegendary() public view returns (uint256) {
        return totalMintedLegendary();
    }
    function processMint(address address_to, uint256 qtyCommon, uint256 qtyRare, uint256 qtyLegendary) internal {
        if (qtyCommon > 0){ 
            _safeMint(address_to, qtyCommon, "common");    
            for (uint256 i = 0; i < qtyCommon;) {
                uint256 _tokenID = _startTokenIdCommon() + totalMintedCommon() - i - 1;
                _mintedDate[_tokenID] = block.timestamp;
                unchecked{i++;}
            }
            emit Minted(
                "general_collection",
                _startTokenIdCommon() + totalMintedCommon() - 1,
                qtyCommon,
                address_to
            );
        } 
        if (qtyRare > 0){
            _safeMint(address_to, qtyRare, "rare");    
            for (uint256 i = 0; i < qtyRare;) {
                uint256 _tokenID = _startTokenIdRare() + totalMintedRare() - i - 1;
                _mintedDate[_tokenID] = block.timestamp;
                unchecked{i++;}
            }
            emit Minted(
                "general_collection",
                _startTokenIdRare() + totalMintedRare() - 1,
                qtyRare,
                address_to
            );
        }
        if (qtyLegendary > 0){ 
            _safeMint(address_to, qtyLegendary, "legendary");    
            for (uint256 i = 0; i < qtyLegendary;) {
                uint256 _tokenID = _startTokenIdLegendary() + totalMintedLegendary() - i - 1;
                _mintedDate[_tokenID] = block.timestamp;
                unchecked{i++;}
            }
            emit Minted(
                "general_collection",
                _startTokenIdLegendary() + totalMintedLegendary() - 1,
                qtyLegendary,
                address_to
            );
        }
    }
    function airdrop(address address_to, uint256 qtyCommon, uint256 qtyRare, uint256 qtyLegendary) 
        external 
        nonReentrant
        onlyOwner
        mintCompliance(qtyCommon, qtyRare, qtyLegendary)
        {
            processMint(address_to, qtyCommon, qtyRare, qtyLegendary);
    }

    function reserve(uint256 qtyCommon, uint256 qtyRare, uint256 qtyLegendary) 
        external 
        nonReentrant
        onlyOwner
        mintCompliance(qtyCommon, qtyRare, qtyLegendary)
        {       
            processMint(_msgSender(), qtyCommon, qtyRare, qtyLegendary);
        
    }
    function mint(
        uint256 qtyCommon,
        uint256 qtyRare,
        uint256 qtyLegendary
        ) 
        public 
        payable 
        nonReentrant
        callerIsUser
        mintCompliance(qtyCommon, qtyRare, qtyLegendary)
    {
        require(saleStatus == SaleStatus.PUBLIC, "Public Sale Not Active");
        require(msg.value >= ((PRICE_COMMON_TOKEN * qtyCommon) + (PRICE_RARE_TOKEN * qtyRare) + (PRICE_LEGENDARY_TOKEN * qtyLegendary)), "Ether value sent is not correct");
        processMint(_msgSender(), qtyCommon, qtyRare, qtyLegendary);
    }
    function allowlistMint(
        bytes32[] memory _proof,
        uint256 qtyCommon,
        uint256 qtyRare,
        uint256 qtyLegendary
        ) 
        public 
        payable 
        nonReentrant
        callerIsUser
        mintCompliance(qtyCommon, qtyRare, qtyLegendary)
    {
        require(allowlistSalePurchased[msg.sender] + qtyCommon + qtyRare + qtyLegendary <= 5 , "Max Allowlist Exceeded");
        require(saleStatus == SaleStatus.ALLOWLIST, "Allowlist Sale Not Active");
        require(
            MerkleProof.verify(_proof, allowlistMerkleRoot, keccak256(abi.encodePacked(msg.sender))),
            "Wallet wildlist not found. Public adoption opens on 14th July, 5:55pm!"
        );
        require(msg.value >= ((PRICE_COMMON_TOKEN * qtyCommon) + (PRICE_RARE_TOKEN * qtyRare) + (PRICE_LEGENDARY_TOKEN * qtyLegendary)), "Ether value sent is not correct");
        processMint(_msgSender(), qtyCommon, qtyRare, qtyLegendary);
        unchecked {
            uint256 quantity = qtyCommon + qtyRare + qtyLegendary;
            allowlistSalePurchased[_msgSender()] += quantity;
        }
    }
    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 mintedDates = _mintedDate[ tokenId ];
        uint256 phase1_evolve_time = mintedDates + 3 days;
        uint256 phase2_evolve_time = mintedDates + 15 days;
        uint256 date = block.timestamp;
        if (date <= phase1_evolve_time) {
            string memory initial = initialURI;
            return bytes(initial).length > 0 ? string(abi.encodePacked(initial, Strings.toString(tokenId), uriSuffix)) : "";
        }else if (date >= phase1_evolve_time && date <= phase2_evolve_time) {
            string memory phase1 = phase1URI;
            return bytes(phase1).length > 0 ? string(abi.encodePacked(phase1, Strings.toString(tokenId), uriSuffix)) : "";
        }
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), uriSuffix)) : "";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    function setSaleStatus(SaleStatus _status) external onlyOwner {
        saleStatus = _status;
    }
    function setMerkleRoots(bytes32 _allowlistMerkleRoot) external onlyOwner {
        allowlistMerkleRoot = _allowlistMerkleRoot;
    }
    function setBaseURI(string memory baseURI_) public onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function setPhase1URI(string memory baseURI_) public onlyOwner() {
        phase1URI = baseURI_;
    }

    function setInitialURI(string memory baseURI_) public onlyOwner() {
        initialURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }
   
    function mintedDate(uint256 tokenID) external view returns (uint256) {
        return _mintedDate[tokenID];
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }   
}
