//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./IERC721.sol";
import "./AvidlinesCore.sol";

uint256 constant TOTAL_MAX = 500;
uint256 constant TOTAL_PUBLIC_MAX = 425;
uint256 constant MAX_PRICE = 2*10**18; //init auction price 2 eth
uint256 constant MIN_PRICE = 0;
uint256 constant AUCTION_DURATION = 5*60*1; //~1h in blocks

uint256 constant ADMIN_SHARE = 80; // in percentage
uint256 constant FP_SHARE = 10;
uint256 constant GEN_SHARE = 10;
uint32 constant PRECISION = 10*6;


contract AvidlinesMinter is Pausable {
    using SafeMath for uint256;

    address internal coreAddress;
    address internal adminAddress;
    address internal fpAddress;
    address internal GLYPH_CONTRACT;
     

    uint256 public totalTokenMints;
    mapping(uint256 => bool) public isGlyphAllowed;
    
    uint256[] private _allWhitelisted;
    mapping(uint256 => uint256) private _allWhitelistedIndex;
    uint256 public pendingFpWithdrawals;
    uint256 public pendingAdminWithdrawals;
    mapping(uint256 => uint256) public pendingGlyphTokenWithdrawals;

    uint256 public auctionStart = 0;
    bool public auctionStarted = false;
    
    event MintFromToken(address indexed from, uint256 tokenId);
    
    event WhitelistedGlyph(uint256 tokenId);
    event RemovedWhitelistedGlyph(uint256 tokenId);

    modifier onlyAdmin() {
        require(_msgSender() == adminAddress, "Only the admin can do this");
        _;
    }

    constructor(address core, address admin, address glyphContract)  {
        coreAddress = core;
        adminAddress = admin;
        GLYPH_CONTRACT = glyphContract;

        _pause();
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    function setFpAdress(address _fpAddress) public onlyAdmin {
        fpAddress = _fpAddress;
    }

    function currentPrice() public view returns (uint256) {
        if (!auctionStarted)
            return MAX_PRICE;
        if ((block.number-auctionStart).mul(PRECISION).div(AUCTION_DURATION) > PRECISION)
            return 0;
        return MAX_PRICE.mul(PRECISION-(block.number-auctionStart).mul(PRECISION).div(AUCTION_DURATION)).div(PRECISION);
    }

    function whitelist(uint256 tokenId) public {
        require(!isGlyphAllowed[tokenId], "token already whitelisted");
        address owner = IERC721(GLYPH_CONTRACT).ownerOf(tokenId);
        require(owner == msg.sender, "Caller should own the tokenId");
        
        isGlyphAllowed[tokenId] = true;
        _addTokenToWhitelistEnumeration(tokenId);
        emit WhitelistedGlyph(tokenId);
    }

    function removeWhitelist(uint256 tokenId) public {
        require(isGlyphAllowed[tokenId], "token is not whitelisted");
        address owner = IERC721(GLYPH_CONTRACT).ownerOf(tokenId);
        require(owner == msg.sender, "Caller should own the tokenId");
        isGlyphAllowed[tokenId] = false;
        _removeTokenFromWhitelistEnumeration(tokenId);
        emit RemovedWhitelistedGlyph(tokenId);
    }

    function allowedGlyphsCount() public view returns (uint256) {
        return _allWhitelisted.length;
    }

    function allowedGlyphs(uint256 index) public view returns (uint256) {
        return _allWhitelisted[index];
    }

    function _addTokenToWhitelistEnumeration(uint256 tokenId) private {
        _allWhitelistedIndex[tokenId] = _allWhitelisted.length;
        _allWhitelisted.push(tokenId);
    }
    
    function fpWithdrawal() public {
        require(msg.sender == fpAddress, "Only fp account can withdrawl");
        require(pendingFpWithdrawals > 0, "Account has no funds to claim");
        uint amount = pendingFpWithdrawals;
        pendingFpWithdrawals = 0;
        if (address(this).balance < amount)
            amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }

    function adminWithdrawal() public {
        require(msg.sender == adminAddress, "Only fp account can withdrawl");
        require(pendingAdminWithdrawals > 0, "Account has no funds to claim");
        uint amount = pendingAdminWithdrawals;
        pendingAdminWithdrawals = 0;
        if (address(this).balance < amount)
            amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }

    function generatorWithdrawal(uint256 tokenId) public {
        require(msg.sender == IERC721(GLYPH_CONTRACT).ownerOf(tokenId), "Only the token owner account can withdrawl");
        require(pendingGlyphTokenWithdrawals[tokenId] > 0, "Account has no funds to claim");
        uint amount = pendingGlyphTokenWithdrawals[tokenId];
        pendingGlyphTokenWithdrawals[tokenId] = 0;
        if (address(this).balance < amount)
            amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }


    function _removeTokenFromWhitelistEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allWhitelisted.length - 1;
        uint256 tokenIndex = _allWhitelistedIndex[tokenId];

        uint256 lastTokenId = _allWhitelisted[lastTokenIndex];

        _allWhitelisted[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allWhitelistedIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allWhitelistedIndex[tokenId];
        _allWhitelisted.pop();
    }

    function startAuction() public whenNotPaused onlyAdmin{
        require(!auctionStarted, "Auction already started");
        auctionStart = block.number;
        auctionStarted = true;
    }

    function mintFromGlyph(uint256 tokenId) payable public whenNotPaused {
        require(totalTokenMints < TOTAL_PUBLIC_MAX, "Maximum public mints reached");
        require(isGlyphAllowed[tokenId], "This glyph is not whitelisted to mint");
        require (msg.value >= currentPrice(), "Insuficient ether sent");
        
        pendingAdminWithdrawals = pendingAdminWithdrawals.add(msg.value.mul(ADMIN_SHARE).div(100));
        pendingFpWithdrawals= pendingFpWithdrawals.add(msg.value.mul(FP_SHARE).div(100));
        pendingGlyphTokenWithdrawals[tokenId] = pendingGlyphTokenWithdrawals[tokenId].add(msg.value.mul(GEN_SHARE).div(100));

        totalTokenMints += 1;
        
        AvidlinesCore(coreAddress).mintGenesis(msg.sender, tokenId);
        emit MintFromToken(msg.sender, tokenId);
    }
        
}