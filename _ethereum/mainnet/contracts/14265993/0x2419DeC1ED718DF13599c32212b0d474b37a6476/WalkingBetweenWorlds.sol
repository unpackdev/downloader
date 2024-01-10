// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ContextMixin.sol";

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract WalkingBetweenWorlds is ERC721, ContextMixin, ERC721Enumerable, ReentrancyGuard, ERC721URIStorage, ERC721Burnable, Pausable, Ownable {

    using Strings for uint256;
    using Counters for Counters.Counter;

    ///////////////////////////////////////////////////////////////////////
    // MODIFIERS
    ///////////////////////////////////////////////////////////////////////

    modifier notContract() {
        require( msg.sender == tx.origin, "Transactions from smart contracts not allowed" );
        _;
    }

    ///////////////////////////////////////////////////////////////////////
    // EVENTS
    ///////////////////////////////////////////////////////////////////////

    event Mint( address to, uint256 qty, uint256[] tokenIds );

    ///////////////////////////////////////////////////////////////////////
    // VARS
    ///////////////////////////////////////////////////////////////////////

    // Sale phases
    enum Phases { VIP, Presale, Public }
    Phases private _currentPhase = Phases.VIP;

    // Collection size
    uint256 public constant SUPPLY_LIMIT = 2222;

    // VIP quantity of 1 = x tokens
    uint256 public tokensPerVipMint = 16;
    uint256 public maxVipListSize = 25;
    uint256 public vipListSize = 0;

    // Reserved for giveaway
    uint256 public totalReserved = 222;

    // Mint limit
    uint256 public mintLimit = 16;

    // Price
    uint256 public mintPrice = 0.0625 * 10 ** 18 wei;

    // A limit per wallet address for actual minting (not giveaways etc)
    mapping( address => uint256 ) private _vipMintCount;
    mapping( address => uint256 ) private _presaleMintCount;
    mapping( address => uint256 ) private _publicMintCount;

    // Token IDs
    Counters.Counter private _tokenIdCounter;

    // Withdraw addresses
    address public withdrawAddress;

    // Access lists
    mapping( address => bool ) private _vipList;
    mapping( address => bool ) private _presaleList;

    string private _metadataBase = "https://metadata.walkingbetweenworlds.net/?token_id=";

    ///////////////////////////////////////////////////////////////////////
    // CONSTRUCTOR
    ///////////////////////////////////////////////////////////////////////

    constructor() ERC721( "Walking Between Worlds", "WBW" ) {
        _tokenIdCounter.increment();// start token ID at 1
        _pause();// start paused
    }


    ///////////////////////////////////////////////////////////////////////
    // SETTINGS / MISC
    ///////////////////////////////////////////////////////////////////////

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // change with each phase, or in case ETH does something crazy
    function setMintPrice( uint256 newPrice ) external onlyOwner {
        mintPrice = newPrice;
    }

    // will change with each phase
    function setMintLimit( uint256 newLimit ) external onlyOwner {
        mintLimit = newLimit;
    }

    // for reveal
    function setMetadataBase( string memory newBase ) external onlyOwner {
        _metadataBase = newBase;
    }


    ///////////////////////////////////////////////////////////////////////
    // VIP
    ///////////////////////////////////////////////////////////////////////

    function addToVipList( address[] calldata accounts ) external onlyOwner {
        require( vipListSize + accounts.length - 1 < maxVipListSize, "This number of accounts will exceed maxVipListSize" );
        for (uint256 i = 0; i < accounts.length; ++i) {
            _vipList[ accounts[i] ] = true;
            vipListSize++;
        }
    }

    function removeFromVipList( address[] calldata accounts ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; ++i) {
            _vipList[ accounts[i] ] = false;
            vipListSize--;
        }
    }

    function isOnVipList( address account ) public view returns (bool) {
        return _vipList[ account ];
    }

    function totalMintedVip( address account ) public view returns (uint256) {
        return _vipMintCount[ account ];
    }

    function setMaxVipListSize( uint256 newMax ) external onlyOwner {
        maxVipListSize = newMax;
    }

    function setVipPhase() external onlyOwner {
        _currentPhase = Phases.VIP;
    }

    function setVipPhaseWithOptions( uint256 newMintLimit, uint256 newMintPrice ) external onlyOwner {
        _currentPhase = Phases.VIP;
        mintLimit = newMintLimit;
        mintPrice = newMintPrice;
    }

    function isVipPhase() public view returns (bool) {
        return _currentPhase == Phases.VIP;
    }

    function setTokensPerVipMint( uint256 newAmount ) external onlyOwner {
        tokensPerVipMint = newAmount;
    }

    function vipMint( uint256 numberOfTokens ) nonReentrant notContract whenNotPaused external payable {
        require( _currentPhase == Phases.VIP, "vipMint can only be called during VIP phase" );
        require( isOnVipList( msg.sender ), "Account not on VIP list" );
        require( numberOfTokens == tokensPerVipMint , "Invalid number of tokens for vipMint" );

        uint256 totalMinted = totalMintedVip( msg.sender );
        require( totalMinted < mintLimit, "VIP mint limit reached for this account" );
        // using the -1 to avoid a <= check
        require( totalMinted + numberOfTokens - 1 < mintLimit, "Quantity puts this account over VIP mint limit" );
        require( totalSupply() + totalReserved + numberOfTokens - 1 < SUPPLY_LIMIT, "Not enough VIP tokens left" );

        uint256 cost = mintPrice * numberOfTokens;
        require( msg.value == cost, "Payment amount is incorrect" );

        uint256[] memory tokenIds = new uint256[](numberOfTokens);
        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            tokenIds[i] = tokenId;
            _tokenIdCounter.increment();

            _vipMintCount[ msg.sender ] += 1;
            _safeMint( msg.sender, tokenId );

            _setTokenURI( tokenId, tokenId.toString() );
        }

        emit Mint( msg.sender, numberOfTokens, tokenIds );
    }

    ///////////////////////////////////////////////////////////////////////
    // PRE-SALE
    ///////////////////////////////////////////////////////////////////////

    function addToPresaleList( address[] calldata accounts ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; ++i) {
            _presaleList[ accounts[i] ] = true;
        }
    }

    function removeFromPresaleList( address[] calldata accounts ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; ++i) {
            _presaleList[ accounts[i] ] = false;
        }
    }

    function isOnPresaleList( address account ) public view returns (bool) {
        return _presaleList[ account ];
    }

    function totalMintedPresale( address account ) public view returns (uint256) {
        return _presaleMintCount[ account ];
    }

    function setPresalePhase() external onlyOwner {
        _currentPhase = Phases.Presale;
    }

    function setPresalePhaseWithOptions( uint256 newMintLimit, uint256 newMintPrice ) external onlyOwner {
        _currentPhase = Phases.Presale;
        mintLimit = newMintLimit;
        mintPrice = newMintPrice;
    }

    function isPresalePhase() public view returns (bool) {
        return _currentPhase == Phases.Presale;
    }

    function presaleMint( uint256 numberOfTokens ) nonReentrant notContract whenNotPaused external payable {
        require( _currentPhase == Phases.Presale, "presaleMint can only be called during pre-sale phase" );
        require( isOnPresaleList( msg.sender ), "Account not on pre-sale list" );

        uint256 totalMinted = totalMintedPresale( msg.sender );
        require( totalMinted < mintLimit, "Pre-sale mint limit reached for this account" );
        // using the -1 to avoid a <= check
        require( totalMinted + numberOfTokens - 1 < mintLimit, "Quantity puts this account over pre-sale mint limit" );
        require( totalSupply() + totalReserved + numberOfTokens - 1 < SUPPLY_LIMIT, "Not enough tokens left" );

        uint256 cost = mintPrice * numberOfTokens;
        require( msg.value == cost, "Payment amount is incorrect" );

        uint256[] memory tokenIds = new uint256[](numberOfTokens);
        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            tokenIds[i] = tokenId;
            _tokenIdCounter.increment();

            _presaleMintCount[ msg.sender ] += 1;
            _safeMint( msg.sender, tokenId );

            _setTokenURI( tokenId, tokenId.toString() );
        }

        emit Mint( msg.sender, numberOfTokens, tokenIds );
    }

    ///////////////////////////////////////////////////////////////////////
    // PUBLIC
    ///////////////////////////////////////////////////////////////////////

    function totalMintedPublic( address account ) public view returns (uint256) {
        return _publicMintCount[ account ];
    }

    function setPublicPhase() external onlyOwner {
        _currentPhase = Phases.Public;
    }

    function setPublicPhaseWithOptions( uint256 newMintLimit, uint256 newMintPrice ) external onlyOwner {
        _currentPhase = Phases.Public;
        mintLimit = newMintLimit;
        mintPrice = newMintPrice;
    }

    function isPublicPhase() public view returns (bool) {
        return _currentPhase == Phases.Public;
    }

    function mint( uint256 numberOfTokens ) nonReentrant notContract whenNotPaused external payable {
        require( _currentPhase == Phases.Public, "mint can only be called during public phase" );

        uint256 totalMinted = totalMintedPublic( msg.sender );
        require( totalMinted < mintLimit, "Mint limit reached for this account" );
        // using the -1 to avoid a <= check
        require( totalMinted + numberOfTokens -1 < mintLimit, "Quantity puts this account over mint limit" );
        require( totalSupply() + totalReserved + numberOfTokens - 1 < SUPPLY_LIMIT, "Not enough tokens left" );

        uint256 cost = mintPrice * numberOfTokens;
        require( msg.value == cost, "Payment amount is incorrect" );

        uint256[] memory tokenIds = new uint256[](numberOfTokens);
        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            tokenIds[i] = tokenId;
            _tokenIdCounter.increment();

            _publicMintCount[ msg.sender ] += 1;
            _safeMint( msg.sender, tokenId );

            _setTokenURI( tokenId, tokenId.toString() );
        }

        emit Mint( msg.sender, numberOfTokens, tokenIds );
    }

    ///////////////////////////////////////////////////////////////////////
    // GIVEAWAY / FREE MINT
    ///////////////////////////////////////////////////////////////////////

    function setTotalReserved( uint256 newAmount ) external onlyOwner {
        totalReserved = newAmount;
    }

    function freeMint( address to, uint256 numberOfTokens ) nonReentrant notContract external onlyOwner {
        require( totalReserved > 0, "No tokens left in reserve" );
        // using the -1 to avoid a <= check
        require( numberOfTokens - 1 < totalReserved, "Exceeds reserved supply" );
        require( totalSupply() + numberOfTokens - 1 < SUPPLY_LIMIT, "Not enough tokens left" );

        uint256[] memory tokenIds = new uint256[](numberOfTokens);
        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            tokenIds[i] = tokenId;
            _tokenIdCounter.increment();
            _safeMint( to, tokenId );

            _setTokenURI( tokenId, tokenId.toString() );
        }

        totalReserved -= numberOfTokens;
        emit Mint( to, numberOfTokens, tokenIds );
    }

    ///////////////////////////////////////////////////////////////////////
    // ADMIN
    ///////////////////////////////////////////////////////////////////////

    function setWithdrawAddress( address newAddress ) external onlyOwner {
        withdrawAddress = newAddress;
    }

    function withdrawAmount( uint256 amount ) external onlyOwner {
        require( address(withdrawAddress) != address(0), "withdrawAddress not set" );
        uint256 balance = address(this).balance;
        require( balance > amount - 1, "Insufficent balance" );
        payable( withdrawAddress ).transfer( amount );
    }

    function withdrawAll() external onlyOwner {
        require( address(withdrawAddress) != address(0), "withdrawAddress not set" );
        uint256 balance = address(this).balance;
        require( balance > 0, "Insufficent balance" );
        payable( withdrawAddress ).transfer( balance );
    }

    function updateTokenURI( uint256 _tokenId, string memory _tokenURI ) public onlyOwner {
        _setTokenURI( _tokenId, _tokenURI );
    }

    function batchUpdateTokenURI( uint256[] calldata tokenIds, string[] calldata tokenURIs ) external onlyOwner {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            _setTokenURI( tokenIds[i], tokenURIs[i] );
        }
    }

    ///////////////////////////////////////////////////////////////////////
    // OVERRIDES
    ///////////////////////////////////////////////////////////////////////

    function _baseURI() internal view override returns (string memory) {
        return _metadataBase;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal override(ERC721URIStorage) {
        super._setTokenURI(tokenId, _tokenURI);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return super.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return super.ownerOf(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    ///////////////////////////////////////////////////////////////////////
    // BASIC OPENSEA INTEGRATION
    // https://docs.opensea.io/docs/polygon-basic-integration
    ///////////////////////////////////////////////////////////////////////

    /**
    * Override isApprovedForAll to auto-approve OS's proxy contract and reduce trading friction
    */
    function isApprovedForAll( address _owner, address _operator ) public override view returns (bool isOperator) {
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }

}
