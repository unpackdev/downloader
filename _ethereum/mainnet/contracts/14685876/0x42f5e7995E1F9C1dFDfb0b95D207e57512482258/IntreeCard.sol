pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ERC2981.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

struct PresaleConfig {
  uint32 startTime;
  uint32 endTime;
  uint256 whitelistMintPerWalletMax;
  uint256 whitelistPrice;
  uint256 maxSupply;
}

// Bureaucrat (LKL) & Stonk
contract IntreeCards is ERC721A, ERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot;

    string public baseURI;
    
    uint32 public publicSaleStartTime;
    uint32 MINT_PER_TX = 10;

    uint256 public CURRENT_PHASE = 0; // 0 -> Alpha, 1 -> Beta, 2 -> Charlie.
    uint256 public PRICE = 0.12 ether;
    uint256 public whitelistTotalSupply = 0;


    // UPDATE SUPPLY AFTER EACH PHASE.
    uint256 public CURRENT_MAX_SUPPLY = 1000;
    uint256[] public SUPPLY_MAX = [1000, 1000, 2580];
    uint256[] public WL_SUPPLY_MAX = [1000, 1000, 2580];

    PresaleConfig public presaleConfig;

    bool public presalePaused = false;
    bool public publicSalePaused = true;
    bool public revealed;

    mapping(address => mapping(uint256 => uint256)) public walletMints;

    constructor(
        string memory _name,
        string memory _symbol,
        address royaltiesReceiver,
        uint96 royaltyInBips  // "basis points" (points per 10_000, e.g., 10% = 1000 bps)
    ) ERC721A(_name, _symbol) payable {
        presaleConfig = PresaleConfig({
            startTime: 1651413600, // Sun May 01 2022 14:00:00 GMT+0000
            endTime: 1651435200, //	Sun May 01 2022 20:00:00 GMT+0000
            whitelistMintPerWalletMax: 2,
            whitelistPrice: 0.12 ether,
            maxSupply: 1000
        });
        publicSaleStartTime = 1651437000; // Sun May 01 2022 20:30:00 GMT+0000
        setRoyaltyInfo(royaltiesReceiver, royaltyInBips);
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(msg.sender == tx.origin, "Nope. Can't mint through another contract.");
        require(_mintAmount <= MINT_PER_TX, "You can mint only 10 per TX!");
        // Total Phase-limiting supply:
        require(_mintAmount + totalSupply() <= CURRENT_MAX_SUPPLY, "You can't mint more than the max supply!");
        _;
    }

    function presaleMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
        mintCompliance(_mintAmount) 
    {
        PresaleConfig memory config_ = presaleConfig;
        
        require(!presalePaused, "Presale has been paused.");
        require(block.timestamp >= config_.startTime && block.timestamp < config_.endTime, "Presale is not active yet!");
        require((walletMints[msg.sender][CURRENT_PHASE] + _mintAmount) <= config_.whitelistMintPerWalletMax, "Exceeds whitelist max mint per wallet!");
        require(_mintAmount + whitelistTotalSupply <= currentMaxSupply(WL_SUPPLY_MAX), "Exceeds allowed max supply for this phase!"); 
        require(msg.value >= (config_.whitelistPrice * _mintAmount), "Insufficient funds!");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Merkle Proof.");

        unchecked {
            walletMints[msg.sender][CURRENT_PHASE] += _mintAmount;
            whitelistTotalSupply += _mintAmount;
        }
        _safeMint(msg.sender, _mintAmount);
    }

    function publicMint(uint256 _mintAmount)
        external
        payable
        nonReentrant
        mintCompliance(_mintAmount)
    {
        require(!publicSalePaused, "Public minting is paused.");
        require(publicSaleStartTime <= block.timestamp, "Public sale is not active yet!");
        require(msg.value >= (PRICE * _mintAmount), "Insufficient funds!");
        require(_mintAmount + totalSupply() <= currentMaxSupply(SUPPLY_MAX), "Exceeds allowed max supply for this phase!"); 

        unchecked { walletMints[msg.sender][CURRENT_PHASE] += _mintAmount; }
        _safeMint(msg.sender, _mintAmount);
    }
    
     // Reserves for the team, promos, and VIP sale.
    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId()
        internal
        view
        virtual
        override returns (uint256) 
    {
        return 1;
    }

    function currentMaxSupply(uint256[] memory _mintTypeMaxSupply) internal view returns (uint256) {
        uint256 _supply;
        uint i;
        // Sums over total supply for WL OR Public sale.
        for (i=0; i <= CURRENT_PHASE; i++) {
            _supply += _mintTypeMaxSupply[i];
        }
        // Returns the total minted across all phases
        // for either WL OR Public sale.
        return _supply;
    }

    function walletStatus(address _address) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_address);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= currentMaxSupply(SUPPLY_MAX)) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _address) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function setRevealed() external onlyOwner {
        revealed = true;
    }

    function setCurrentPhase(uint256 _phase) external onlyOwner { 
        CURRENT_PHASE = _phase;
    }

    function pausePublic(bool _state) external onlyOwner {
        publicSalePaused = _state;
    }

    function pausePresale(bool _state) external onlyOwner {
        presalePaused = _state;
    }

    function setPublicSaleStartTime(uint32 startTime_) external onlyOwner {
        publicSaleStartTime = startTime_;
    }

    function configurePresale(uint32 _startTime, uint32 _endTime, uint256 _price, uint32 _walletLimitPerUser) external onlyOwner {
        presaleConfig.startTime = _startTime;
        presaleConfig.endTime = _endTime;
        presaleConfig.whitelistPrice = _price;
        presaleConfig.whitelistMintPerWalletMax = _walletLimitPerUser;
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function setPublicPrice(uint256 _price) external onlyOwner {
        // Price in uint256
        PRICE = _price;
    }

    function setCurrentMaxSupply(uint256 _supply) external onlyOwner {
        CURRENT_MAX_SUPPLY = _supply;
    }

    function setMaxSupplyPublic(uint256 _supply, uint16 _phase) external onlyOwner {
        SUPPLY_MAX[_phase] = _supply;
    }

    function setMaxSupplyPresale(uint256 _supply, uint16 _phase) external onlyOwner {
        WL_SUPPLY_MAX[_phase] = _supply;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*
    * ROYALTIES
    */
    function setRoyaltyInfo(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) external onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    /*
    * METADATA URI
    */
    function _baseURI()
        internal 
        view 
        virtual
        override returns (string memory)
    {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
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

        if (!revealed) return _baseURI();
        return string(abi.encodePacked(_baseURI(), _tokenId.toString(), ".json"));
    }
    
}