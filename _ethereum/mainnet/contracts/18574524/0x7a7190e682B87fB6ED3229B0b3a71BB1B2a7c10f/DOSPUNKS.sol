// SPDX-License-Identifier: MIT

/* 
██████   ██████  ███████     ██████  ██    ██ ███    ██ ██   ██ ███████ 
██   ██ ██    ██ ██          ██   ██ ██    ██ ████   ██ ██  ██  ██      
██   ██ ██    ██ ███████     ██████  ██    ██ ██ ██  ██ █████   ███████ 
██   ██ ██    ██      ██     ██      ██    ██ ██  ██ ██ ██  ██       ██ 
██████   ██████  ███████     ██       ██████  ██   ████ ██   ██ ███████                                                       															
by 0xd3ad & generationart
*/

pragma solidity ^0.8.0;
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC721Enumerable.sol";
import "./Strings.sol";
import "./Address.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";
import "./Context.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC2981.sol";

contract DosPunks is ERC721Enumerable, ERC2981, Ownable {
	event addApprovedTokenEvent( uint256 _tokenId );
	event mintEvent( address _recipient, uint256 _tokenId );
	event migrateTokenEvent( uint256 _tokenIdERC1155 );
	event setBaseURIEvent( string _newBaseURI );
	event setDosPunksAddressEvent( address _newAddress );
	event setBurnAddressEvent( address _newAddress );
	event setMaxSupplyEvent( uint256 _value );
	event pausedEvent( bool _value );
	event setWithdrawalAddressEvent( address _newAddress );
	event withdrawalEvent( address _withdrawalAddress );

	using Strings for uint256;

	// baseURI
	string public baseURI = "https://zmffcul32kmrmg54x2uflhfqzyn6xa3kukz5wi2etmsazvx2s24q.arweave.net/ywpRUXvSmRYbvL6oVZywzhvrg2qis9sjRJskDNb6lrk/";
	string public baseExtension = ".json";
	uint256 public maxSupply = 500;
	bool public paused = false;
	address public withdrawal_address = 0x6Fd6AfE08202D7aefDF533ee44dc0E62941C4B22;
	address public dospunks_address = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
	address public burn_address = 0x000000000000000000000000000000000000D3ad;
	string public _name = "DOS Punks";
	string public _symbol = "DOS";
	string _not_owner_error = "You are not the owner of this token on OpenSea";
	mapping(uint256 => bool) public _approvedTokens;
	

	constructor() ERC721( _name, _symbol ) {
	}

	// public
	function mint( address _recipient, uint256 _tokenId ) 
	external
	onlyOwner {
		require( ! paused, "Contract paused" );
		require( _tokenId > 0, "Invalid token ID" );
		require( _tokenId < maxSupply, "Invalid token ID" );
		_safeMint( _recipient, _tokenId );
		emit mintEvent( _recipient, _tokenId );
	}

	function addApprovedToken( uint256 _tokenId ) 
	external
	onlyOwner {
		_approvedTokens[ _tokenId ] = true;
		emit addApprovedTokenEvent( _tokenId );
	}

	function isValidToken( uint256 _tokenId ) 
	public 
	view
	returns ( bool ) {
		if ( _approvedTokens[ _tokenId ] ) {
			return true;
		}
		uint256 tokenId = ( _tokenId & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000 ) >> 40;
		address maker = address( uint160( _tokenId >> 96 ) );
		uint256 totalSize = ( _tokenId & 0x000000000000000000000000000000000000000000000000000000ffffffffff );
		bool criteria_maker = ( ( maker == 0xbE8a3d01E747c397fFE92709EC8f782e6602F622 ) || ( maker ==  0x6Fd6AfE08202D7aefDF533ee44dc0E62941C4B22 ) );
		bool criteria_size = ( totalSize == 1 );
		bool criteria_token = ( tokenId <= 500 );
		bool return_value = criteria_maker && criteria_size && criteria_token;
		return return_value;
	}

	function getTokenId( uint256 _tokenId ) 
	public 
	view
	returns ( uint256 ) {
		if ( _tokenId == 86183687183603793108320826266155603664391186218806717785568406115786977968129 ) {
			return 498;
		}

		if ( _tokenId == 86183687183603793108320826266155603664391186218806717785568405651793071046657 ) {
			return 499;
		}

		if ( _tokenId == 86183687183603793108320826266155603664391186218806717785568405659489652441089 ) {
			return 500;
		}
 
		uint256 return_value = 0;
		uint256 tokenId = ( _tokenId & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000 ) >> 40;
		address maker = address( uint160( _tokenId >> 96 ) );

		if ( maker == 0xbE8a3d01E747c397fFE92709EC8f782e6602F622 ) {
			return_value = tokenId;
		} else if ( maker == 0x6Fd6AfE08202D7aefDF533ee44dc0E62941C4B22 ) {
			return_value = tokenId;
			if ( tokenId == 198 ) {
				return_value = 489;
			} else if ( tokenId == 199 ) {
				return_value = 490;
			} else if ( tokenId == 201 ) {
				return_value = 491;
			} else if ( tokenId == 202 ) {
				return_value = 492;
			} else if ( tokenId == 203 ) {
				return_value = 493;
			} else if ( tokenId == 204 ) {
				return_value = 494;
			} else if ( tokenId == 205 ) {
				return_value = 495;
			} else if ( tokenId == 206 ) {
				return_value = 496;
			} else if ( tokenId == 207 ) {
				return_value = 497;
			} else if ( tokenId == 208 ) {
				return_value = 440;
			} else if ( tokenId == 440 ) {
				return_value = 498;
			} else if ( tokenId == 209 ) {
				return_value = 25;
			} else if ( tokenId == 210 ) {
				return_value = 18;
			} else {
				return_value = tokenId;
			}
		} else {
			return_value = maxSupply + 1;
		}
		
		return return_value;
	}

	function migrateToken( uint256 _tokenIdERC1155 )
	public {
		// require unpaused
		require( ! paused, "Contract paused" );

	        // Require that the sender of the transaction is the owner of the token on OpenSea
		require( IERC1155( dospunks_address ).balanceOf( msg.sender, _tokenIdERC1155 ) == 1, _not_owner_error );

	        // Require valid token
		require( isValidToken( _tokenIdERC1155 ), "Invalid token" );

		// get token id
		uint256 tokenId = getTokenId( _tokenIdERC1155 );

		// tansfer to burn address
		IERC1155( dospunks_address ).safeTransferFrom( msg.sender, burn_address, _tokenIdERC1155, 1, "");

		// mint tokenId
		_safeMint( msg.sender, tokenId );

		emit migrateTokenEvent( _tokenIdERC1155 );
	}

	function migrateBatch( uint256[] calldata _tokenIdsERC1155 )
	external {
		uint256 length = _tokenIdsERC1155.length;
		for ( uint256 i = 0; i < length; i++ ) {
			migrateToken( _tokenIdsERC1155[ i ] );
		}
	}

	function setDosPunksAddress( address _newAddress ) 
	public 
	onlyOwner {
		dospunks_address = _newAddress;
		emit setDosPunksAddressEvent( dospunks_address );
	}

	function setBurnAddress( address _newAddress ) 
	public 
	onlyOwner {
		burn_address = _newAddress;
		emit setBurnAddressEvent( burn_address );
	}

	function setMaxSupply( uint256 _maxSupply ) 
	external 
	onlyOwner {
		maxSupply = _maxSupply;
		emit setMaxSupplyEvent( _maxSupply );
	}

	function walletOfOwner( address _owner )
	public
	view
	returns ( uint256[] memory ) {
		uint256 ownerTokenCount = balanceOf(_owner);
		uint256[] memory tokenIds = new uint256[](ownerTokenCount);
		for (uint256 i; i < ownerTokenCount; i++) {
			tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
		}
		return tokenIds;
	}

	function tokenURI(uint256 tokenId)
	public
	view
	virtual
	override
	returns (string memory) {
		require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
		return bytes(baseURI).length > 0
			? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension))
			: "";
	}

	function setBaseURI(string memory _newBaseURI) 
	public 
	onlyOwner {
		baseURI = _newBaseURI;
		emit setBaseURIEvent( _newBaseURI );
	}

	function setBaseExtension(string memory _newBaseExtension) 
	public 
	onlyOwner {
		baseExtension = _newBaseExtension;
	}

	function pause(bool _state) 
	public 
	onlyOwner {
		paused = _state;
		emit pausedEvent( _state );
	}

	function setWithdrawalAddress( address _newAddress ) 
	public 
	onlyOwner {
		withdrawal_address = _newAddress;
		emit setWithdrawalAddressEvent( _newAddress );
	}

	function withdraw() public payable onlyOwner {
		(bool os, ) = payable( withdrawal_address ).call{value: address(this).balance}("");
		require(os);
		emit withdrawalEvent( withdrawal_address );
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override (ERC2981, ERC721Enumerable) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
			interfaceId == type(IERC721Metadata).interfaceId ||	
			interfaceId == type(IERC721Enumerable).interfaceId ||
			interfaceId == type(IERC2981).interfaceId || 
            super.supportsInterface(interfaceId);
    }

	function setCollectionRoyalty(address _receipient, uint96 _fee ) 
		public 
		onlyOwner {
			_setDefaultRoyalty(_receipient,_fee);	
	}

	function resetCollectionRoyalty()
		public 
		onlyOwner{
		_deleteDefaultRoyalty();
    }

	function setIndividualTokenRoyalty(uint256 _token, address _feerecipient, uint96 _feeNumerator)
		public
		onlyOwner{
		_setTokenRoyalty(_token,_feerecipient,_feeNumerator);

	}

	function deleteIndividualTokenRoyalty(uint256 _token)
		public 
		onlyOwner{
		_resetTokenRoyalty(_token);
    }

}