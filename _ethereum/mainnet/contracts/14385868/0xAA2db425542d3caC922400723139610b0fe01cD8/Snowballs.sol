// SPDX-License-Identifier: MIT

/// @title Snowballs
/// @notice Initial states of small significance that build upon themselves, becoming larger.
/// @author @waynos_eth

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./DSMath.sol";

contract Snowballs is ERC721, Ownable, ReentrancyGuard, DSMath {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _tokensListed;

    uint256 public maxSupply = 5337;
    
    uint256 public minMintPrice = 0.1 ether;
    uint256 public listingPrice = 0.025 ether;
    uint256 public commissionPercent = 10;

    address public intermediary = 0xB4AE9006603A3EcE1CDf6762e5A80BfC941610b9;
    bool public mintOpen = false;
    bool public listingsOpen = false;

    string public externalUrl = 'https://thesnowball.xyz/token/';

    struct Snowball {
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        uint256 principal;
        uint256 effectiveFrom;
        uint16 rate;
    }

    mapping( uint256 => Snowball ) private idToSnowball;

    constructor() ERC721( "Snowballs", "SNWBLS" ) {}

    modifier exists( uint256 tokenId ) {
        require( _exists( tokenId ), "Snowball does not exist" );
        _;
    }

    modifier tokenOwner( uint256 tokenId ) {
        require( idToSnowball[tokenId].owner == _msgSender(), "Not the token owner" );
        _;
    }

    modifier listed( uint256 tokenId ) {
        require( idToSnowball[tokenId].price > 0, "Snowball not listed" );
        _;
    }

    modifier notListed( uint256 tokenId ) {
        require( idToSnowball[tokenId].price == 0, "Snowball is listed" );
        _;
    }

    function mint( address[] memory _address, uint256[] memory _principal ) public payable nonReentrant {
        require( mintOpen, "Mint is not open" );
        require( _address.length == _principal.length, "Argument lengths must be the same" );
        require( _address.length > 0, "Qty must be greater than zero" );
        require( add( getSupply(), _address.length ) <= maxSupply, "Qty exceeds supply" );

        address sender = _msgSender();
        address owner = owner();

        if( sender != owner ) {
            uint256 sum;
            for( uint256 i = 0; i < _principal.length; i++ ) {
                sum += _principal[i];
            }
            require( msg.value == sum, "Payment is incorrect" );
        }

        for( uint256 i = 0; i < _principal.length; i++ ) {
            if( sender != owner ) {
                require( _principal[i] >= minMintPrice, "Payment is incorrect");
            }

            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();

            _safeMint( _address[i], tokenId );

            idToSnowball[tokenId] = Snowball(
                tokenId,
                payable( address( _address[i] ) ),
                payable( address( 0 ) ),
                0,
                _principal[i],
                block.timestamp,
                uint16( add( ( uint256( keccak256( abi.encodePacked( block.timestamp, block.difficulty, tokenId, _address[i] ) ) ) ) % 251, 500 ) )
            );
        }
    }

    /*
     * Marketplace
     */
    function list( uint256 tokenId, uint256 price ) public payable nonReentrant exists( tokenId ) tokenOwner( tokenId ) notListed( tokenId ) {
        require( listingsOpen, "Listings are not open" );
        require( msg.value == listingPrice, "Payment is incorrect" );

        idToSnowball[tokenId].seller = payable( _msgSender() );
        idToSnowball[tokenId].price = max( getCompoundValue( tokenId ), price );

        _tokensListed.increment();

        _safeTransfer( _msgSender(), intermediary, tokenId, "" );
    }

    function delist( uint256 tokenId ) public listed( tokenId ) {
        require( idToSnowball[tokenId].seller == _msgSender(), "Only the seller can delist" );

        idToSnowball[tokenId].seller = payable( address( 0 ) );
        idToSnowball[tokenId].price = 0;

        _tokensListed.decrement();

        _safeTransfer( intermediary, _msgSender(), tokenId, "" );
    }

    function recordSale( uint256 tokenId ) internal listed( tokenId ) {
        uint256 commission = mul( msg.value / 100, commissionPercent );
        payable( idToSnowball[tokenId].seller ).transfer( msg.value - commission );

        idToSnowball[tokenId].seller = payable( address( 0 ) );
        idToSnowball[tokenId].principal = msg.value;
        idToSnowball[tokenId].price = 0;
        idToSnowball[tokenId].effectiveFrom = block.timestamp;

        _tokensListed.decrement();
    }

    function sale( uint256 tokenId ) external payable nonReentrant {
        require( intermediary == _msgSender(), "Only the intermediary can record a sale" );

        recordSale( tokenId );
    }

    function buy( uint256 tokenId ) public payable nonReentrant {
        require( _msgSender() != idToSnowball[tokenId].owner, "Cannot sell to self" );
        require( msg.value == idToSnowball[tokenId].price, "Payment is incorrect" );

        recordSale( tokenId );

        _safeTransfer( intermediary, _msgSender(), tokenId, "" );
    }

    function decelerate( uint256 tokenId ) public tokenOwner( tokenId ) notListed( tokenId ) {
        idToSnowball[tokenId].principal = getCompoundValue( tokenId );
        idToSnowball[tokenId].rate = uint16( 15 );
        idToSnowball[tokenId].effectiveFrom = block.timestamp;
    }

    function supplement( uint256 tokenId ) public payable nonReentrant tokenOwner( tokenId ) notListed( tokenId ) {
        require( msg.value > 0, "Value must be greater than zero" );
        idToSnowball[tokenId].principal = add( getCompoundValue( tokenId ), msg.value );
        idToSnowball[tokenId].effectiveFrom = block.timestamp;
    }

    /*
     * Getters
     */
    function get( uint256 tokenId ) public view exists( tokenId ) returns ( Snowball memory ) {
        return idToSnowball[tokenId];
    }

    function getSupply() public view returns ( uint256 ) {
        return _tokenIds.current();
    }

    function getSvg( uint256 tokenId ) public view exists( tokenId ) returns ( string memory ) {
        uint256 ethVal = idToSnowball[tokenId].price;
        if( ethVal == 0 ) {
            ethVal = getCompoundValue( tokenId );
        }
        uint256 svgVal = ( ( ( ethVal - minMintPrice ) * ( 500 - 4 ) ) / ( 50 ether - minMintPrice ) ) + 4;

        return string( abi.encodePacked(
            '<svg viewBox="0 0 1000 1000" xmlns="http://www.w3.org/2000/svg">',
            '<rect x="0" y="0" width="1000" height="1000" fill="#000"/>',
            '<circle fill="#FFF" cx="500" cy="500" r="', Strings.toString( min( svgVal, 500 ) ), '"/>',
            '</svg>'
        ) );
    }

    function getCompoundValue( uint256 tokenId ) public view exists( tokenId ) returns ( uint256 ) {
        uint256 rate = mul( 0.01 ether, idToSnowball[tokenId].rate );
        uint256 yearlyRate = add( mul( 1 ether, 10 ** 9 ), rdiv( 
            mul( rate, 10 ** 9 ), 
            mul( mul( 365, 86400 ), 10 ** 27 ) 
        ) );

        return rmul( 
            idToSnowball[tokenId].principal, 
            rpow( yearlyRate, sub( block.timestamp, idToSnowball[tokenId].effectiveFrom ) )
        );
    }

    function getListed() public view returns ( Snowball[] memory ) {
        uint256 listedCount = _tokensListed.current();
        uint256 currentIndex = 0;

        Snowball[] memory snowballs = new Snowball[]( listedCount );
        for( uint256 i = 0; i < listedCount; i++ ) {
            if( idToSnowball[i + 1].price > 0 ) {
                Snowball storage snowball = idToSnowball[i + 1];
                snowballs[currentIndex] = snowball;
                currentIndex += 1;
            }
        }
        return snowballs;
    }

    function getNotListed() public view returns ( Snowball[] memory ) {
        uint256 supply = getSupply();
        uint256 notListedCount = supply - _tokensListed.current();
        uint256 currentIndex = 0;

        Snowball[] memory snowballs = new Snowball[]( notListedCount );
        for( uint256 i = 0; i < notListedCount; i++ ) {
            if( idToSnowball[i + 1].price == 0 ) {
                Snowball storage snowball = idToSnowball[i + 1];
                snowballs[currentIndex] = snowball;
                currentIndex += 1;
            }
        }
        return snowballs;
    }

    function getMine() public view returns ( Snowball[] memory ) {
        uint256 supply = getSupply();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for( uint256 i = 0; i < supply; i++ ) {
            if( idToSnowball[i + 1].owner == _msgSender() || idToSnowball[i + 1].seller == _msgSender() ) {
                itemCount += 1;
            }
        }

        Snowball[] memory snowballs = new Snowball[]( itemCount );
        for( uint256 i = 0; i < supply; i++ ) {
            if( idToSnowball[i + 1].owner == _msgSender() || idToSnowball[i + 1].seller == _msgSender() ) {
                Snowball storage snowball = idToSnowball[i + 1];
                snowballs[currentIndex] = snowball;
                currentIndex += 1;
            }
        }
        return snowballs;
    }

    /*
     * Setters
     */
    function setMintOpen( bool state ) external onlyOwner {
        mintOpen = state;
    }

    function setListingsOpen( bool state ) external onlyOwner {
        listingsOpen = state;
    }

    function setMinMintPrice( uint256 price ) external onlyOwner {
        minMintPrice = price;
    }

    function setListingPrice( uint256 price ) external onlyOwner {
        listingPrice = price;
    }

    function setCommissionPercent( uint256 percent ) external onlyOwner {
        require( percent < 11, "Commission cannot be more than 10%" );
        commissionPercent = percent;
    }

    function setIntermediary( address _address ) external onlyOwner {
        intermediary = _address;
    }

    function setMaxSupply( uint256 supply ) external onlyOwner {
        maxSupply = supply;
    }

    function setExternalUrl( string memory url ) external onlyOwner {
        externalUrl = url;
    }

    /*
     * Overrides
     */
    function tokenURI( uint256 tokenId ) public view override exists( tokenId ) returns ( string memory ) {
        return string( abi.encodePacked( 'data:application/json;base64,', Base64.encode( bytes( string( abi.encodePacked(
            '{"name":"Snowball #', Strings.toString( tokenId ), '","description":"An initial state of small significance that builds upon itself, becoming larger.","image":"data:image/svg+xml;base64,', Base64.encode( bytes( getSvg( tokenId ) ) ), '","external_url":"', externalUrl, Strings.toString( tokenId ), '","value":"', Strings.toString( getCompoundValue( tokenId ) ), '","attributes":', string( abi.encodePacked( '[{"trait_type":"Principal","value":"', Strings.toString( idToSnowball[tokenId].principal ), '"},{"trait_type":"Rate","value":"', Strings.toString( idToSnowball[tokenId].rate ), '"},{"trait_type":"Effective From","display_type":"date","value":"', Strings.toString( idToSnowball[tokenId].effectiveFrom ), '"}]' ) ), '}'
        ) ) ) ) ) );
    }

    function _transfer( address from, address to, uint256 tokenId ) internal virtual override {
        idToSnowball[tokenId].owner = payable( address( to ) );
        super._transfer( from, to, tokenId );
    }

    function approve( address to, uint256 tokenId ) public virtual override {
        require( _msgSender() == intermediary, "Permission denied" );
        super.approve( to, tokenId );
    }

    function setApprovalForAll( address operator, bool approved ) public virtual override {
        require( _msgSender() == intermediary, "Permission denied" );
        super.setApprovalForAll( operator, approved );
    }

    /*
     * Misc
     */
    function withdraw() external onlyOwner {
        uint256 amount = address( this ).balance;
        require( amount > 0, "Nothing to withdraw" );
        payable( address( owner() ) ).transfer( amount );
    }
}
