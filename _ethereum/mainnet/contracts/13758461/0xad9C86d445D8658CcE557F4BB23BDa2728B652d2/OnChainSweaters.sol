// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

import "./OnChainSweatersTypes.sol";
import "./IOnChainSweatersRenderer.sol";

contract OnChainSweaters is ERC721, Ownable, ReentrancyGuard, Pausable {
    mapping(uint256 => OnChainSweatersTypes.OnChainSweater) sweaters;
    event GenerateSweater(uint256 indexed tokenId, uint256 dna);
    event ClaimedSweater(address claimer, uint256 indexed tokenId, address tx);
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _reservedTokenIds;
    Counters.Counter private _hdTokens; // after burn tokens

    uint256 public constant MAX_FREE_MINT_SUPPLY = 333;
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant FOUNDERS_RESERVE_AMOUNT = 0;
    uint256 public constant MAX_PUBLIC_SUPPLY = MAX_SUPPLY - MAX_FREE_MINT_SUPPLY - FOUNDERS_RESERVE_AMOUNT;
    uint256 public constant MINT_PRICE = 0.02 ether;
    uint256 private constant MAX_PER_ADDRESS = 10;
    uint256 private constant FIRST_HD_TOKEN_ID = MAX_SUPPLY + 1; // minted by burning

    uint256 public publicSaleStartTimestamp;
    address public renderingContractAddress;
    bool public claimActive = false;
    bool public mintActive = true;
    bool public burningActive = false;

    mapping(uint256 => address) public claimedTokenTransactions;
    mapping(address => uint256) public mintedCounts;
    mapping(address => uint256) private founderMintCountsRemaining;

    constructor() ERC721("Xmas Sweaters OnChain", "SWEAT") {}

    modifier whenPublicSaleActive() {
        require(isPublicSaleOpen() && mintActive, "Public sale not open");
        _;
    }

    modifier whenClaimActive() {
        require(isClaimOpen(), "Claiming not open");
        _;
    }

    modifier whenBurningActive() {
        require(isBurningOpen(), "Burning not open");
        _;
    }

    function getTotalMinted() external view returns (uint256) {
        return _hdTokens.current() + _tokenIds.current() + _reservedTokenIds.current();
    }
    

    function getRemainingFounderMints(address _addr) public view returns (uint256) {
        return founderMintCountsRemaining[_addr];
    }

    function isPublicSaleOpen() public view returns (bool) {
        return block.timestamp >= publicSaleStartTimestamp && publicSaleStartTimestamp != 0;
    }

    function isClaimOpen() public view returns (bool) {
        return claimActive;
    }

    function isBurningOpen() public view returns (bool) {
        return burningActive;
    }

    function setRenderingContractAddress(address _renderingContractAddress) public onlyOwner {
        renderingContractAddress = _renderingContractAddress;
    }

    function setPublicSaleTimestamp(uint256 timestamp) external onlyOwner {
        publicSaleStartTimestamp = timestamp;
    }

    function setMintStatus(bool value) external onlyOwner {
        mintActive = value;
    }

    function closeMintsOpenBurning() external onlyOwner {
        mintActive = false;
        burningActive = true;
    }

    function setClaimStatus(bool value) external onlyOwner {
        claimActive = value;
    }

    function mintPublicSale(uint256 _count) external payable nonReentrant whenPublicSaleActive returns (uint256, uint256) {
        require(_count > 0 && _count <= MAX_PER_ADDRESS, "Invalid Sweater count"); // To check wallet count
        require(_tokenIds.current() + _count <= MAX_PUBLIC_SUPPLY, "All Sweaters have been minted");
        if(_tokenIds.current()+1 > MAX_FREE_MINT_SUPPLY) {
            require(_count * MINT_PRICE == msg.value, "Incorrect amount of ether sent");
        } else {
            require(msg.value == 0, "Do not send ether for free mint");
        }
        require(mintedCounts[msg.sender] + _count <= MAX_PER_ADDRESS, "You cannot mint so many Sweaters");
        uint256 firstMintedId = _tokenIds.current() + 1;

        for (uint256 i = 0; i < _count; i++) {
            _tokenIds.increment();
            mint(_tokenIds.current(), 128);
        }
        mintedCounts[msg.sender] += _count;

        return (firstMintedId, _count);
    }

    function allocateFounderMint(address _addr, uint256 _count) public onlyOwner nonReentrant {
        founderMintCountsRemaining[_addr] = _count;
    }

    function founderMint(uint256 _count) public nonReentrant returns (uint256, uint256) {
        require(_count > 0 && _count <= MAX_PER_ADDRESS, "Invalid count");
        require(_reservedTokenIds.current() + _count <= FOUNDERS_RESERVE_AMOUNT, "All reserved Sweaters have been minted");
        require(founderMintCountsRemaining[msg.sender] >= _count, "You cannot mint this many reserved Sweaters");

        // FIXME: see why onchainrunner use _tokenIds instead of _reservedTokenIds
        //uint256 firstMintedId = MAX_PUBLIC_SUPPLY + _tokenIds.current() + 1;
        uint256 firstMintedId = MAX_PUBLIC_SUPPLY + _reservedTokenIds.current() + 1;
        for (uint256 i = 0; i < _count; i++) {
            _reservedTokenIds.increment();
            mint(MAX_PUBLIC_SUPPLY + _reservedTokenIds.current(), 128);
        }
        founderMintCountsRemaining[msg.sender] -= _count;
        return (firstMintedId, _count);
    }

    function burnAndMint(uint256[] calldata tokenIds) external nonReentrant whenBurningActive returns(uint256, uint256) {
        require(tokenIds.length > 0 && tokenIds.length < MAX_PUBLIC_SUPPLY, "No token or exceeds existing number of tokens");
        require(tokenIds.length % 2 == 0, "The number of tokens to burn must be even");
        // check the validity of tokens
        for (uint256 i = 0; i < tokenIds.length; i+=2) {
            require(tokenIds[i] <= MAX_PUBLIC_SUPPLY && tokenIds[i+1] <= MAX_PUBLIC_SUPPLY, "Token not burnable");
            require(_exists(tokenIds[i]) && _exists(tokenIds[i+1]), "Trying to burn nonexistent token");
            require(ownerOf(tokenIds[i]) == msg.sender && ownerOf(tokenIds[i+1]) == msg.sender, "Burning not owned token");
        }
        uint256 firstMintedId = FIRST_HD_TOKEN_ID + _hdTokens.current();
        for (uint256 i = 0; i < tokenIds.length; i+=2) {
            burn(tokenIds[i], tokenIds[i+1]);
            _hdTokens.increment();
            mint(FIRST_HD_TOKEN_ID + _hdTokens.current(), 256);
        }

        return (firstMintedId, tokenIds.length/2);
    }

    function burn(uint256 tokenId1, uint256 tokenId2) internal {
      require(_exists(tokenId1) && _exists(tokenId2) && tokenId1 != tokenId2, "Trying to burn nonexistent or already burned token");
      _burn(tokenId1);
      _tokenIds.decrement();
      _burn(tokenId2);
      _tokenIds.decrement();
    }

    function mint(uint256 tokenId, uint256 resolution) internal {
        OnChainSweatersTypes.OnChainSweater memory newSweater;
        newSweater.dna = uint256(keccak256(abi.encodePacked(
                tokenId,
                msg.sender,
                block.difficulty,
                block.timestamp
        )));
        newSweater.resolution = resolution;

        _safeMint(msg.sender, tokenId);
        sweaters[tokenId] = newSweater;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (renderingContractAddress == address(0)) {
            return '{"name": "On Chain Christmas Sweater", "description": "The First, 100% On-Chain Christmas Sweater pattern generator with real world utility!", "image": "https://sweatersonchain.s3.amazonaws.com/pre-reveal/pre-reveal-thumbnail.png"}';
        }

        IOnChainSweatersRenderer renderer = IOnChainSweatersRenderer(renderingContractAddress);
        return renderer.tokenURI(_tokenId, sweaters[_tokenId]);
    }

    function claimSweater(uint256 _tokenId) external nonReentrant whenClaimActive returns(address) {
        require(ownerOf(_tokenId) == msg.sender, "Claiming not owned token");
        require(claimedTokenTransactions[_tokenId] ==  address(0), "Token already claimed");
        claimedTokenTransactions[_tokenId] = tx.origin;
        emit ClaimedSweater(msg.sender, _tokenId, tx.origin);
        return claimedTokenTransactions[_tokenId];
    }

    function getHighQualityClaimedSweater(uint256 _tokenId) external view returns(string memory) {
        require(claimedTokenTransactions[_tokenId] !=  address(0), "Not yet claimed token");

        if (renderingContractAddress == address(0)) {
            return '{"error": "No rendering contract set"}';
        }
        IOnChainSweatersRenderer renderer = IOnChainSweatersRenderer(renderingContractAddress);
        return renderer.getHQClaimedSweater(_tokenId, sweaters[_tokenId], claimedTokenTransactions[_tokenId]);
    }

    function getDna(uint256 _tokenId) public view returns (uint256) {
        return sweaters[_tokenId].dna;
    }


    receive() external payable {}

    function withdraw() public onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}('');
        require(success, "Withdrawal failed");
    }

}