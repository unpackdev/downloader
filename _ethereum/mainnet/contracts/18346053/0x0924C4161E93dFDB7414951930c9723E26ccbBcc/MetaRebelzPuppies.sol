pragma solidity ^0.8.17;

import "./ERC721AQueryableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./DefaultOperatorFiltererUpgradeable.sol";


contract MetaRebelzPuppies is ERC721AQueryableUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, DefaultOperatorFiltererUpgradeable {
    uint256 public cost;   
    uint256 public maxSupply;
    address public withdrawWallet;
    bool public claimable;
    string baseURI;
    mapping(address => uint256) public freeClaims;
    mapping(uint256 => bool) tokenProtected;

   /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializerERC721A initializer public {
        __ERC721A_init("MetaRebelzPuppies", "MRP");
        __ERC721AQueryable_init();
        OwnableUpgradeable.__Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        DefaultOperatorFiltererUpgradeable.__DefaultOperatorFilterer_init();
        maxSupply = 2000;
        claimable = true;
        cost = 0;
        baseURI = "";
        withdrawWallet = address(msg.sender);
        _pause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setClaims(address[] memory addresses, uint256[] memory counts) public onlyOwner {
        require(addresses.length == counts.length, "Invalid input lengths");

        for (uint256 i = 0; i < addresses.length; i++) {
            freeClaims[addresses[i]] = counts[i];
        }
    }

    function toggleClaimable() public onlyOwner {
        claimable = !claimable;
    }

    function setWithdrawWallet(address wallet) public onlyOwner {
        withdrawWallet = wallet;
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool os, ) = payable(withdrawWallet).call{value: address(this).balance}("");
        require(os);
    }
    
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function airdrop(address to, uint256 _mintAmount) public onlyOwner {
        require(_totalMinted() + _mintAmount <= maxSupply, "Exceeds maximum supply");
        _mint(to, _mintAmount);
    }

    function lockToken(uint256[] calldata tokenIds) public {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender);
            tokenProtected[tokenId] = true;
        }
    }

     function unlockToken(uint256[] calldata tokenIds) public {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender);
            tokenProtected[tokenId] = false;
        }
    }

    function lockToken(uint256 tokenId, bool isAdmin) public onlyOwner {
        require(isAdmin);
        tokenProtected[tokenId] = true;
    }

    function unlockToken(uint256 tokenId, bool isAdmin) public onlyOwner {
        require(isAdmin);
        tokenProtected[tokenId] = false;
    }

    function isLocked(uint256 tokenId) external view returns (bool) {
        return (true == tokenProtected[tokenId]);
    }

    function isUnlocked(uint256 tokenId) internal view returns (bool) {
        return (false == tokenProtected[tokenId]);
    }

    function claim(uint256 _claimAmount) public {
        require(claimable);
        require(_claimAmount > 0);
        require(_totalMinted() + _claimAmount <= maxSupply, "Exceeds maximum supply");
        require(freeClaims[msg.sender] > 0, "Not eligible for claim");
        require(freeClaims[msg.sender] >= _claimAmount, "No claims left");

        _mint(msg.sender, _claimAmount);
        freeClaims[msg.sender] = freeClaims[msg.sender] - _claimAmount;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721AUpgradeable, IERC721AUpgradeable) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory _URI = _baseURI();
        return bytes(_URI).length != 0 ? string(abi.encodePacked(_URI, _toString(tokenId))) : '';
    }

    function _startTokenId() internal view virtual override(ERC721AUpgradeable) returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal whenNotPaused virtual override(ERC721AUpgradeable) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable virtual override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperatorApproval(operator) {
        require(isUnlocked(tokenId), "TokenID is locked and cannot be transferred.");
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable virtual override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        require(isUnlocked(tokenId), "TokenID is locked and cannot be transferred.");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual override(ERC721AUpgradeable, IERC721AUpgradeable) onlyAllowedOperator(from) {
        require(isUnlocked(tokenId), "TokenID is locked and cannot be transferred.");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable virtual 
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        require(isUnlocked(tokenId), "TokenID is locked and cannot be transferred.");
        super.safeTransferFrom(from, to, tokenId, data);
    } 
}