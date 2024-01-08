// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./Context.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./ERC165.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";
import "./Strings.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract TheSecretProject is ERC721Enumerable, Ownable {
	using SafeMath for uint256;

	// Config Constans
	uint256 private constant price = 0.05 ether; // price of 1 secret
	uint256 private constant maxCountForPublicTX = 8; // max mint count per transaction in public sale
	uint256 private constant maxCountForPresaleUser = 1; // max one presale user can mint *total*
	uint256 private constant maxSupply = 8888; // max amount of secrets

	// togglables
	bool public presaleActive = false;
	bool public publicSaleActive = false;
	bool public metadataLocked = false; // is the metadata frozen/locked

	// Addresses
	address public constant signer = 0xBe83B7a2EB9217a571189831a5a832804C1485DE;
	address private constant addr1 = 0xD3D104a6759051e0B0fc3d2d902678a983fB7fB4;
	address private constant addr2 = 0xd66254f9925d0B7BF16583593bAb2002a28D695f;
	address private constant addr3 = 0x021937711a434644CeE08b1db08D313EF6FBd4a3;

	// Metadata
	string private baseURI; // base uri of metadata

	// Keeping things fair!
	mapping(address => uint256) public presaleMintedPerUser; // stores the amount that presale users have minted, e.g. if tom mints 2 squirrels, presaleMintedPerUser[tom] will be 2
	uint256 public presaleMintedTotal = 0; // total amount that all presale users have minted during presale
	uint256 public ownerMintedTotal = 0; // total amount that owner wallet has minted using mintForOwner()

	constructor() public ERC721('The Secret Project', 'SECRET') {} // setup contract, first value is the name, second is the symbol or shorthand

	modifier onlyValidAccess(
		bytes32 hashBytes,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
	) {
		require(hashBytes == calculateSenderHash(), 'Invalid hash');
		bytes memory prefix = '\x19Ethereum Signed Message:\n32';
		bytes32 prefixedProof = keccak256(abi.encodePacked(prefix, hashBytes));
		address recovered = ecrecover(prefixedProof, _v, _r, _s);
		require(recovered == signer, 'Not signed by signer');
		_;
	}

	function calculateSenderHash() internal view returns (bytes32 hash) {
		bytes memory packed = abi.encodePacked(msg.sender);
		bytes32 hashResult = keccak256(packed);
		return hashResult;
	}

	function mintForSale(uint256 amount) public payable {
		require(publicSaleActive, 'Sale is not active');
		require(amount <= maxCountForPublicTX, 'Max secrets is 8');
		require(totalSupply().add(amount) <= maxSupply, 'TX would mint over the total');
		require(price.mul(amount) == msg.value, 'Over or underpaid');

		// loop <amount> times, if the total supply is under the max, mint with id INDEX+1
		for (uint256 i = 0; i < amount; i++) {
			uint256 mintIndex = totalSupply().add(1);
			if (totalSupply() < maxSupply) {
				_safeMint(msg.sender, mintIndex);
			}
		}
	}

	function presaleMint(
		uint256 amount,
		bytes32 hashBytes,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
	) public payable onlyValidAccess(hashBytes, _v, _r, _s) {
		require(presaleActive, 'Presale has not been started or is over');
		require(amount <= maxCountForPresaleUser, 'Amount is too high');
		require(
			presaleMintedPerUser[msg.sender].add(amount) <= maxCountForPresaleUser,
			'Amount is too high (with the amount you have already minted)'
		);
		require(totalSupply().add(amount) <= maxSupply, 'TX would mint over the total');
		require(price.mul(amount) == msg.value, 'Over or underpaid');
		// loop <amount> times, if the total supply is under the max, mint with id INDEX+1
		for (uint256 i = 0; i < amount; i++) {
			uint256 mintIndex = totalSupply().add(1);
			if (totalSupply() < maxSupply) {
				_safeMint(msg.sender, mintIndex);
			}
		}
		presaleMintedPerUser[msg.sender] = presaleMintedPerUser[msg.sender].add(amount);
		presaleMintedTotal = presaleMintedTotal.add(amount);
	}

	// Mint 100 tokens for use in giveaways, team mints, etc. Will not work once 100 squirrels have been minted | This can only be ran by the address that deployed the contract.
	function mintForOwner(uint256 amount) public onlyOwner {
		require(ownerMintedTotal.add(amount) <= 100, 'Would mint too many');
		require(totalSupply().add(amount) <= maxSupply, 'TX would mint over the total');
		// loop <amount> times, if the total supply is under the max, mint with id INDEX+1
		for (uint256 i = 0; i < amount; i++) {
			uint256 mintIndex = totalSupply().add(1);
			if (totalSupply() < maxSupply) {
				_safeMint(msg.sender, mintIndex);
			}
		}
		ownerMintedTotal = ownerMintedTotal.add(amount);
	}

	// turn the public sale on or off | This can only be ran by the address that deployed the contract.
	function togglePublicSale() public onlyOwner {
		// true -> false, false -> true
		publicSaleActive = !publicSaleActive;
	}

	// turn the presale on or off | This can only be ran by the address that deployed the contract.
	function togglePresale() public onlyOwner {
		// true -> false, false -> true
		presaleActive = !presaleActive;
	}

	// withdraw smart contract balance | This can only be ran by the address that deployed the contract.
	function withdraw() public onlyOwner {
		// smart contract balance
		uint256 balance = address(this).balance;

		// 33.34%
		require(payable(addr1).send(balance.mul(3334).div(10000)), 'addr1 failed');
		// 33.33%
		require(payable(addr2).send(balance.mul(3333).div(10000)), 'addr2 failed');
		// 33.33%
		require(payable(addr3).send(balance.mul(3333).div(10000)), 'addr3 failed');
	}

	// This is ONLY IF the above function does not work, and will not be used lightly
	function emergencyWithdraw() public onlyOwner {
		// smart contract balance
		uint256 balance = address(this).balance;

		require(payable(msg.sender).send(balance), 'withdraw failed');
	}

	// This gives the url of where the metadata is stored
	function _baseURI() internal view override returns (string memory) {
		return baseURI;
	}

	// Sets the above value, if the contract is locked we say no! | This can only be ran by the address that deployed the contract.
	function setBaseURI(string memory uri) external onlyOwner {
		require(!metadataLocked, 'Metadata is locked.');
		baseURI = uri;
	}

	// Lock metadata, no rugging allowed! | This can only be ran by the address that deployed the contract.
	function lockMetadata() public onlyOwner {
		metadataLocked = true;
	}
}
