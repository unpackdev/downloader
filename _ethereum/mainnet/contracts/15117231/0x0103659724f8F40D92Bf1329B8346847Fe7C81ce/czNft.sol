// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.15;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";
import "./iczNft.sol";

contract czNft is iczNft, ERC721Enumerable, IERC2981, Ownable, Pausable, ReentrancyGuard {

    constructor() ERC721("CyberZillaz", "CZ") {
        _pause();
    }

    /** EVENTS */
    event TokenMinted(address indexed owner, uint256 indexed tokenId);
    event TokenBurned(address indexed owner, uint256 indexed tokenId);
    event TokenTraitAdded(address indexed owner, uint256 indexed tokenId, uint16 indexed traitId);

    /** PUBLIC VARS */
    // max number of tokens that can be minted
    uint256 public override MAX_TOKENS = 2_222;
    // number of tokens have been minted, locked, staked & bridged so far
    uint16 public override totalMinted;
    uint16 public override totalLocked;
    uint16 public override totalStaked;
    uint16 public override totalBridged;
    // address which receives the royalties
    address public royaltyAddress;
    // store which special traits the token already has fused with - tokenId => traitId
    mapping(uint256 => uint16[]) public tokenSpecialTraits;

    /** PRIVATE VARS */
    mapping(address => bool) private _admins;
    // uri for revealing nfts traits
    string private _tokenRevealedBaseURI;
    // royalty permille (to support 1 decimal place)
    uint256 private _royaltyPermille = 75;
    // tokenId => Locked; map of all staked by tokenId
    mapping(uint256 => Locked) private _lockedByTokenId;

    /** MODIFIERS */
    modifier onlyAdmin() {
        require(_admins[_msgSender()], "NFT: Only admins can call this");
        _;
    }

    /** ADMIN ONLY FUNCTIONS */
    function mint(address recipient) external override whenNotPaused nonReentrant onlyAdmin {
        require(totalMinted + 1 <= MAX_TOKENS, "NFT: All tokens minted");
        
        // increase mint counter
        totalMinted++;

        // mint the NFT
        _safeMint(recipient, totalMinted);

        emit TokenMinted(recipient, totalMinted);
    }

    function burn(uint256 tokenId) external override whenNotPaused nonReentrant onlyAdmin {
        emit TokenBurned(ownerOf(tokenId), tokenId);
        _burn(tokenId);
    }

    function lock(uint256 tokenId, uint8 lockType) external override whenNotPaused nonReentrant onlyAdmin {
        require(!_isLocked(tokenId), "Nft: Token is already locked");

        _lockedByTokenId[tokenId] = Locked({
            tokenId: tokenId,
            lockType: lockType,
            lockTimestamp: block.timestamp
        });
        
        totalLocked++;
        if(lockType == 1) totalStaked++;
        if(lockType == 2) totalBridged++;
    }

    function unlock(uint256 tokenId) external override whenNotPaused nonReentrant onlyAdmin {
        require(_isLocked(tokenId), "Nft: Token is not locked");

        Locked memory myLock = _getLock(tokenId);

        // remove the lock
        delete _lockedByTokenId[tokenId];

        totalLocked--;
        if(myLock.lockType == 1) totalStaked--;
        if(myLock.lockType == 2) totalBridged--;
    }

    // updates only the timestamp and nothing else
    function refreshLock(uint256 tokenId) external override whenNotPaused onlyAdmin {
        require(_isLocked(tokenId), "Nft: Token is not locked");
        
        Locked memory myLock = _getLock(tokenId);
        myLock.lockTimestamp = block.timestamp;

        _lockedByTokenId[tokenId] = myLock;
    }

    function addToSpecialTraits(uint256 tokenId, uint16 traitId) external override whenNotPaused onlyAdmin {
        tokenSpecialTraits[tokenId].push(traitId);
        emit TokenTraitAdded(ownerOf(tokenId), tokenId, traitId);
    }

    /** PUBLIC FUNCTIONS */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (royaltyAddress, salePrice * _royaltyPermille/1000);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'NFT: Token does not exist');
        return string(abi.encodePacked(_tokenRevealedBaseURI, Strings.toString(tokenId)));
    }

    function getLock(uint256 tokenId) external override view onlyAdmin returns (Locked memory) {
        return _getLock(tokenId);
    }
    function _getLock(uint256 tokenId) private view onlyAdmin returns (Locked memory) {
        require(_isLocked(tokenId), "Nft: Token is not locked");
        return _lockedByTokenId[tokenId];
    }

    function isLocked(uint256 tokenId) external override view returns(bool) {
        return _isLocked(tokenId);
    }
    function _isLocked(uint256 tokenId) private view returns(bool) {
        if (_lockedByTokenId[tokenId].tokenId == tokenId) return true;
        return false;
    }

    function isStaked(uint256 tokenId) external override view returns(bool) {
        return _isStaked(tokenId);
    }
    function _isStaked(uint256 tokenId) private view returns(bool) {
        if (_lockedByTokenId[tokenId].tokenId == tokenId && _lockedByTokenId[tokenId].lockType == 1) return true;
        return false;
    }

    function isBridged(uint256 tokenId) external override view returns(bool) {
        return _isBridged(tokenId);
    }
    function _isBridged(uint256 tokenId) private view returns(bool) {
        if (_lockedByTokenId[tokenId].tokenId == tokenId && _lockedByTokenId[tokenId].lockType == 2) return true;
        return false;
    }
    
    // lockType 1 = staked; lockType 2 = bridged;
    function getAllStakedOrLockedTokens(address owner, uint8 lockType) external override view returns (uint256[] memory) {
        uint256 balanceOf = balanceOf(owner);
        uint256[] memory stakedTokenIds = new uint256[](balanceOf);
        uint16 stakedTokenIdsIndex = 0;

        for(uint16 i = 0; i < balanceOf; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);
            if (lockType == 1 && _isStaked(tokenId)) {
                stakedTokenIds[stakedTokenIdsIndex] = tokenId;
                stakedTokenIdsIndex++;
            } else if (lockType == 2 && _isBridged(tokenId)) {
                stakedTokenIds[stakedTokenIdsIndex] = tokenId;
                stakedTokenIdsIndex++;
            }
        }

        return stakedTokenIds;
    }

    function getWalletOfOwner(address owner) external override view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(owner);
        uint256[] memory traitIds = new uint256[](ownerTokenCount);

        for (uint256 i; i < ownerTokenCount; i++) {
            traitIds[i] = tokenOfOwnerByIndex(owner, i);
        }

        return traitIds;
    }

    function getSpecialTraits(uint256 tokenId) external override view returns (uint16[] memory) {
        uint256 traitsCount = tokenSpecialTraits[tokenId].length;
        uint16[] memory traitIds = new uint16[](traitsCount);

        for (uint256 i = 0; i < traitsCount; i++) {
            traitIds[i] = tokenSpecialTraits[tokenId][i];
        }

        return traitIds;
    }

    /** OVERRIDE */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721) nonReentrant {
        require(!_isLocked(tokenId), "Nft: Token is locked");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override(ERC721, IERC721) nonReentrant {
        require(!_isLocked(tokenId), "Nft: Token is locked");
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    /** OWNER ONLY FUNCTIONS */
    function setRevealedBaseURI(string calldata uri) external onlyOwner {
        _tokenRevealedBaseURI = uri;
    }

    function setPaused(bool _paused) external onlyOwner {
        require(royaltyAddress != address(0), "Nft: Royalty address must be set");
        if (_paused) _pause();
        else _unpause();
    }

    function setRoyaltyPermille(uint256 number) external onlyOwner {
        _royaltyPermille = number;
    }

    function setRoyaltyAddress(address addr) external onlyOwner {
        royaltyAddress = addr;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function addAdmin(address addr) external onlyOwner {
        _admins[addr] = true;
    }

    function removeAdmin(address addr) external onlyOwner {
        delete _admins[addr];
    }
}