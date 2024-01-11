// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";

contract NFT is ERC721A, Ownable {
    using Strings for uint256;

    uint256 private constant MAX_SUPPLY = 10000;
    uint256 private constant MAX_MINTS_PRE_SALE = 2000;

    string private _baseTokenURI;
    string private _unrevealedURI;
    bool private isRevealed;

    // Public sale
    uint256 private publicSalePrice = 0.055 ether;
    uint256 private publicSaleMaxMintPerTransaction = 3;
    uint256 private publicSaleMaxMints = 10;
    bool private publicSaleStarted;
    mapping( address => uint256 ) public numberOfPublicNFTsMinted;

    // pre sale
    uint256 private preSalePrice = 0.049 ether;
    uint256 private preSaleMaxMintPerTransaction = 5;
    uint256 private preSaleMaxMints = 10;
    uint256 private preSaleNFTsMinted;
    uint256 private preSaleEndDate;
    bool private preSaleStarted;
    mapping( address => bool ) public isWhitelisted;
    mapping( address => uint256 ) public numberOfPreNFTsMinted;

    constructor( string memory baseURI, string memory unrevealedURI ) ERC721A( "Project X", "TPX" ) {
        _baseTokenURI = baseURI;
        _unrevealedURI = unrevealedURI;
    }

    //////////
    // Getters
    function _baseURI() internal view virtual override returns ( string memory ) {
        if ( ! isRevealed ) {
            return _unrevealedURI;
        }

        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns ( string memory ) {
        require( _exists( tokenId ), "ERC721Metadata: URI query for nonexistent token" );

        if ( ! isRevealed ) {
            return _unrevealedURI;
        } else {
            string memory baseURI = _baseURI();

            return bytes( baseURI ).length > 0 ? string( abi.encodePacked( baseURI, tokenId.toString() ) ) : "";
        }
    }

    function isPreSaleActive() external view returns ( bool ) {
        return preSaleStarted;
    }

    function isPublicSaleActive() external view returns ( bool ) {
        return publicSaleStarted;
    }

    function getTotalNFTsMinted() external view returns ( uint256 ) {
        return totalSupply();
    }

    function getPreSaleNFTsMinted() external view returns ( uint256 ) {
        return preSaleNFTsMinted;
    }

    function getPublicSalePrice( uint256 quantity ) external view returns ( uint256 ) {
        return publicSalePrice * quantity;
    }

    function getPreSalePrice( uint256 quantity ) external view returns ( uint256 ) {
        return preSalePrice * quantity;
    }

    function getPublicSaleMaxMintPerTransaction() external view returns ( uint256 ) {
        return publicSaleMaxMintPerTransaction;
    }

    function getPublicSaleMaxMints() external view returns ( uint256 ) {
        return publicSaleMaxMints;
    }

    function getPreSaleMaxMintPerTransaction() external view returns ( uint256 ) {
        return preSaleMaxMintPerTransaction;
    }

    function getPreSaleMaxMints() external view returns ( uint256 ) {
        return preSaleMaxMints;
    }

    //

    function mintNFTs( uint256 quantity ) external payable {
        require( publicSaleStarted, "Public sale not active!" );
        require( ! preSaleStarted, "Pre-sale is active!" );
        require( numberOfPublicNFTsMinted[msg.sender] + quantity <= publicSaleMaxMints, "Quantity exceeds max mints per account!" );
        require( totalSupply() + quantity <= MAX_SUPPLY, "Not enough NFTs left!" );
        require( quantity <= publicSaleMaxMintPerTransaction, "Quantity exceeds max mints per transaction!" );
        require( quantity > 0, "Cannot mint 0 NFTs." );
        require( msg.value >= quantity * publicSalePrice, "Not enough ether to purchase NFTs." );

        numberOfPublicNFTsMinted[msg.sender] += quantity;
        _safeMint( msg.sender, quantity );
    }

    function mintPreSaleNFTs( uint256 quantity ) external payable {
        require( ! publicSaleStarted, "Public sale started!" );
        require( preSaleStarted, "Pre-sale is not started!" );
        require( block.timestamp <= preSaleEndDate, "Pre-sale ended!" );
        require( isWhitelisted[msg.sender], "Account is not whitelisted!" );
        require( numberOfPreNFTsMinted[msg.sender] + quantity <= preSaleMaxMints, "Quantity exceeds max mints per account!" );
        require( quantity <= preSaleMaxMintPerTransaction, "Quantity exceeds max mints per transaction!" );
        require( totalSupply() + quantity <= MAX_SUPPLY, "Not enough NFTs left!" );
        require( preSaleNFTsMinted + quantity <= MAX_MINTS_PRE_SALE, "Not enough pre-sale NFTs left!" );
        require( msg.value >= quantity * preSalePrice, "Not enough ether to purchase NFTs." );
        require( quantity > 0, "Cannot mint 0 NFTs." );

        numberOfPreNFTsMinted[msg.sender] += quantity;
        preSaleNFTsMinted += quantity;
        _safeMint( msg.sender, quantity );
    }

    //////////////////
    // Owner functions
    function setPublicSaleMaxMintPerTransaction( uint256 _publicSaleMaxMintPerTransaction ) external onlyOwner {
        publicSaleMaxMintPerTransaction = _publicSaleMaxMintPerTransaction;
    }

    function setPublicSaleMaxMints( uint256 _publicSaleMaxMints ) external onlyOwner {
        publicSaleMaxMints = _publicSaleMaxMints;
    }

    function setpreSaleMaxMintPerTransaction( uint256 _preSaleMaxMintPerTransaction ) external onlyOwner {
        preSaleMaxMintPerTransaction = _preSaleMaxMintPerTransaction;
    }

    function setpreSaleMaxMints( uint256 _preSaleMaxMints ) external onlyOwner {
        preSaleMaxMints = _preSaleMaxMints;
    }

    function addToWhitelist( address[] memory _addresses ) external onlyOwner {
        for ( uint256 i = 0; i < _addresses.length; i++ ) {
            isWhitelisted[_addresses[i]] = true;
        }
    }

    function removeFromWhitelist( address[] memory _addresses ) external onlyOwner {
        for ( uint256 i = 0; i < _addresses.length; i++ ) {
            isWhitelisted[_addresses[i]] = false;
        }
    }

    function toggleReveal() public onlyOwner {
        if ( isRevealed ) isRevealed = false;
        else isRevealed = true;
    }

    function setBaseURI( string calldata baseURI ) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setUnrevealedURI( string memory unrevealedURI ) public onlyOwner {
        _unrevealedURI = unrevealedURI;
    }

    function togglePublicSale() external onlyOwner {
        if ( publicSaleStarted ) publicSaleStarted = false;
        else if ( ! publicSaleStarted ) {
            require( ! preSaleStarted, "Disable pre-sale first!" );

            publicSaleStarted = true;
        }
    }

    function startPreSale( uint256 _duration ) external onlyOwner {
        require( ! publicSaleStarted, "Disable public sale first!" );

        preSaleStarted = true;

        preSaleEndDate = block.timestamp + _duration;
    }

    function endPreSale() external onlyOwner {
        preSaleStarted = false;
    }

    function setPrice( uint256 price ) external onlyOwner {
        publicSalePrice = price;
    }

    function setPreSalePrice( uint256 price ) external onlyOwner {
        preSalePrice = price;
    }

    function mintNFTsOwner( uint256 quantity ) external onlyOwner {
        require( totalSupply() + quantity <= MAX_SUPPLY, "Not enough NFTs left!" );

        _safeMint( msg.sender, quantity );
    }

    function withdraw() external onlyOwner {
        payable( msg.sender ).transfer( address( this ).balance );
    }
}
