// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./IERC1155.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./ERC721Burnable.sol";
import "./Strings.sol";


error blockedAddress();
contract Kollektive is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    ERC2981,
    Pausable,
    Ownable,
    ReentrancyGuard
{
    using Strings for uint256;

    string public constant NAME = "KOLLEKTIVE";
    string public constant SYMBOL = "KOLLEKTIVE";
    string private _baseTokenURI;
    address private _daoContract;
    address private _rkContract;

    uint256 private _currentTokenId = 0;

    // restrictions toggle
    bool private _marketplaceProtection;
    bool private _transferProtection;
    bool public _membersOnly;

    uint256 public constant MAX_SUPPLY = 3120;
    uint256 public constant MINT_PRICE = 0.06 ether;
    uint256 public constant MAX_PER_TXN = 10;

    mapping(address => bool) private _approvedMarketplaces;
    mapping(address => bool) private _blockedTransfers;

    event Mint(address indexed _to, uint256 _tokenId);

    constructor(
        string memory _uri, 
        address _rk, 
        address _kitty, 
        address _royalty
    ) ERC721(NAME, SYMBOL) {

        _setDefaultRoyalty(_royalty, 1000);
        _baseTokenURI = _uri;
        _daoContract = _kitty;
        _rkContract = _rk;

        // satisfy the OS dictatorship
        _marketplaceProtection = false;
        _transferProtection = true;

        // toggle private mint to members
        _membersOnly = true;

        _pause();
    }

    function pause() public payable onlyOwner {
        _pause();
    }

    function unpause() public payable onlyOwner {
        _unpause();
    }
    
    function mint(uint256 quantity) external payable nonReentrant whenNotPaused {

        require(totalSupply() + quantity <= MAX_SUPPLY, "Kollektive: reached max supply!");
        require(quantity <= MAX_PER_TXN, "Kollektive: exceeds max per transaction");
        require(msg.value >= MINT_PRICE * quantity, "Kollektive: insufficient ETH sent");

        if (_membersOnly) {
            require(isMember(), "Kollektive: not a DAO nor RK member");
        }

        for (uint256 i = 0; i < quantity; i++) {
            uint256 newTokenId = _currentTokenId;
            _safeMint(_msgSender(), newTokenId);
            _currentTokenId++;
            emit Mint(_msgSender(), newTokenId);
        }
    }

    function setTokenId(uint256 id)  external payable onlyOwner {
        _currentTokenId = id;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory _baseURIParam) external payable onlyOwner {
        _baseTokenURI = _baseURIParam;
    }

    function setDAOContract(address _kitty) external payable onlyOwner {
        _daoContract = _kitty;
    }
    
    function setRollKallContract(address _rk) external payable onlyOwner {
        _rkContract = _rk;
    }

    function isMember() public view returns (bool) {
        return isDAOMember() || isRollKallOwner();
    }

    function isRollKallOwner() public view returns (bool) {
        // token ID always 0
        uint256 tokenId = 0;
        return IERC1155(_rkContract).balanceOf(_msgSender(), tokenId) > 0;   
    }
    
    function isDAOMember() public view returns (bool) {
        return IERC20(_daoContract).balanceOf(_msgSender()) > 0;
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external payable onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721){
        if(_transferProtection){
            if(_blockedTransfers[from] || _blockedTransfers[to]) revert blockedAddress();
        }
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721) {
        if(_transferProtection){
            if(_blockedTransfers[from] || _blockedTransfers[to]) revert blockedAddress();
        }
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override(ERC721){
        if(_transferProtection){
            if(_blockedTransfers[from] || _blockedTransfers[to]) revert blockedAddress();
        }
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function approve(address to, uint256 tokenId) public virtual override(ERC721) {
        if (_marketplaceProtection) {
            require(_approvedMarketplaces[to], "Kollektive: invalid Marketplace");
        }
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721) {
        if (_marketplaceProtection) {
            require(_approvedMarketplaces[operator], "Kollektive: invalid Marketplace");
        }
        super.setApprovalForAll(operator, approved);
    }

    function setApprovedMarketplace(address market, bool approved) public payable onlyOwner {
        _approvedMarketplaces[market] = approved;
    }


    function setBlockedAddresses(address account, bool blocked) public payable onlyOwner {
        _blockedTransfers[account] = blocked;
    }

    function setMembershipSettings(bool memberProtect) external onlyOwner {
        _membersOnly = memberProtect;
    }

    function setProtectionSettingsTransfer(bool transferProtect) external payable onlyOwner {
        _transferProtection  = transferProtect;
    }

    function setProtectionSettingsMarket(bool marketProtect) external payable onlyOwner {
        _marketplaceProtection = marketProtect;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function vaultMint(address _to, uint256 _qty) external onlyOwner {
        require(totalSupply() + _qty <= MAX_SUPPLY, "Reached max supply!");
        for (uint256 i = 0; i < _qty; i++) {
            uint256 newTokenId = _currentTokenId;
            _safeMint(_to, newTokenId);
            _currentTokenId++;
            emit Mint(_to, newTokenId);
        }
    }

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(owner()).transfer(balance);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}