
pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Enumerable.sol";

contract StickerMilady is ERC721Enumerable, Ownable {

	string private __baseURI;
	function _baseURI() internal view virtual override returns (string memory) {
		return __baseURI;
	}
	function _setBaseURI(string memory baseURI_) internal virtual {
		__baseURI = baseURI_;
	}
	function setBaseURI(string memory baseURI) public onlyOwner {
		_setBaseURI(baseURI);
	}

	string private __contractURI;
	function _contractURI() internal view virtual returns (string memory) {
		return __contractURI;
	}
	function _setContractURI(string memory contractURI_) internal virtual {
		__contractURI = contractURI_;
	}
	function setContractURI(string memory contractURI) public onlyOwner {
		_setContractURI(contractURI);
	}

	bool private started = false;

	uint256 private mask = 0x000000000000000000000000000000000000000000000000ffffffffffffffff;

	uint8[] private shift = [
		8 * 0,
		8 * 8,
		8 * 16,
		8 * 24
	];

	// Hardcode into a literal in one tx if possible?
	uint256[] private packed;

	function CheckPacked( uint256 user, uint256 i, uint8 j ) public view returns ( bool ) {
		return ( ( packed[i] >> shift[j] ) & mask ) == ( user & mask );
	}
	function ErasePacked( uint256 i, uint8 j ) private {
		packed[i] = packed[i] & ( ~( mask << shift[j] ) );
	}

	function Withdraw() public onlyOwner {
		payable( msg.sender ).transfer( address( this ).balance );
	}

	function StartMint() public onlyOwner {
		require( !started, "You've already started the minting." );
		started = true;
	}
	
	function AddWhitelist( uint256[] memory wl_add ) public onlyOwner {
		for(uint256 i = 0; i < wl_add.length; i++){
			packed.push(wl_add[i]);
		}
	}
	
	uint256 private price_adj = 100;
	
	function AdjustPrices(uint256 percent) public onlyOwner {
		price_adj = percent;
	}
	
	mapping( address => uint256 ) public mintCounter;

	uint256 constant price = 49 ether / 1000;
	uint256 constant bulk_10_price = 46 ether / 1000;
	uint256 constant bulk_30_price = 41 ether / 1000;
	uint256 constant bulk_50_price = 39 ether / 1000;
	
	uint256 constant supply = 8888;
	uint256 constant reserve = 500;
	
	uint256 constant max_whitelist_mints = 1;
	
	uint256 ct_supply = supply - reserve;
	uint256 ct_reserve = reserve;

	mapping( address => uint256 ) public mintCounterAuxWhitelist;

	function AddAuxWhitelist( address[] memory wl_add ) public onlyOwner {
		for(uint256 i = 0; i < wl_add.length; i++){
			mintCounterAuxWhitelist[ wl_add[i] ] = 1;
		}
	}

	function CheckAuxWhitelist() public view returns (bool) {
		return mintCounterAuxWhitelist[ msg.sender ] != 0;
	}

	function MintAuxWhitelist() public {
	
		uint256 n = totalSupply();
	
		require( started, "Minting has not started yet." );	
	
		require( mintCounterAuxWhitelist[ msg.sender ] == 1, "Not on whitelist.");
		require( n < supply, "No more supply!" );
		require( ct_supply != 0, "No more supply!" );
		
		_safeMint( msg.sender, n + 1 );
		
		
		ct_supply = ct_supply - 1;
		
		mintCounterAuxWhitelist[ msg.sender ] = 0;
	}
	
	function MintWhitelist( uint256 i, uint8 j ) public payable {
	
		uint256 n = totalSupply();
	
		require( started, "Minting has not started yet." );	
	
		require( mintCounter[ msg.sender ] < max_whitelist_mints, "Maximum whitelist discount mints reached." );
		
		require( n < supply, "No more supply!" );
		
		require( ct_supply != 0, "No more supply!" );
		
		require( CheckPacked( uint256( uint160( msg.sender ) ), i, j ), "Not found on whitelist." );
		
		_safeMint( msg.sender, n + 1 );
		
		ct_supply = ct_supply - 1;
		
		mintCounter[ msg.sender ] = mintCounter[ msg.sender ] + 1;
	}

	function MintMain() public payable {
	
		uint256 pay = (price * price_adj) / 100;
	
		uint256 n = totalSupply();
	
		require( started, "Minting has not started yet." );	
		
		require( n < supply, "No more supply!" );
		
		require( ct_supply != 0, "No more supply!" );
		
		require( msg.value == pay, "Incorrect amount of wei sent." );
				
		_safeMint( msg.sender, n + 1 );
		
		ct_supply = ct_supply - 1;
	}

	function MintBulk(uint256 num_mint, uint256 discount_price) private {
		
		uint256 pay = (discount_price * num_mint * price_adj) / 100;
		
		uint256 n = totalSupply();

		require( started, "Minting has not started yet." );	
		
		require( (n + num_mint) < supply, "No more supply!" );
		
		require( ct_supply >= num_mint, "No more supply!" );
		
		require( msg.value == pay, "Incorrect amount of wei sent." );

		for(uint256 i = 0; i < num_mint; i++){
			_safeMint( msg.sender, n + i + 1);	
		}

		ct_supply = ct_supply - num_mint;
	}

	function Mint10() public payable {
		MintBulk(10, bulk_10_price);
	}
	
	function Mint30() public payable {
		MintBulk(30, bulk_30_price);
	}
	
	function Mint50() public payable {
		MintBulk(50, bulk_50_price);
	}

	function MintReserve() public onlyOwner {
	
		uint256 n = totalSupply();
		uint256 reserve_mint_inc = 10;
	
		require( started, "Minting has not started yet." );	
	
		require( (n + reserve_mint_inc) < supply, "No more supply!" );
		
		require( ct_reserve >= reserve_mint_inc, "No more supply!" );
		
		//mint 10 at once 
		for(uint256 i = 0; i < reserve_mint_inc; i++){
			_safeMint( msg.sender, n + i + 1);	
		}

		ct_reserve = ct_reserve - reserve_mint_inc;
	
	}

	constructor() ERC721("Sticker Milady","STCKR") Ownable(msg.sender) { }
}
