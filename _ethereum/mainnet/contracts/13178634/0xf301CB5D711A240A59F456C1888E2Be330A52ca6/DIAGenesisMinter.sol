// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./Ownable.sol";
import "./DIADataNFT.sol";

library NFTUtil {
	function randomByte(uint256 seed) private view returns (uint8) {
		return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), msg.sender, seed)))%256);
	}

	function randInt(uint256 max, uint256 seed) external view returns (uint256) {
		return randomByte(seed) % max;
	}
}

contract DIAGenesisMinter is Ownable {
	using NFTUtil for *;

	address[] public genesisNFTs;
	address[] public postGenesisNFTs;

	//true = means in genesis
	//false = post genesis
	mapping (address => bool) allNFTs;

	uint256 private seed;

	constructor(uint256 _seed) {
		seed = _seed;
	}

	event MintedDataNFT(address DIADataNFT, address owner, uint256 numMinted, uint256 newRank, bool isGenesis);
	event NewNFT(address NFTAddr);
	event UpdatedNFT(address NFTAddr, bool isGenesis);

	function updateSeed(uint256 newSeed) external onlyOwner {
		seed = newSeed;
	}

	function addNFT(address _addr) public onlyOwner{
		allNFTs[_addr] = true;
		genesisNFTs.push(_addr);
		emit NewNFT(_addr);
	}

	function updateNFT(address _addr, bool _isGenesis) public onlyOwner{
		allNFTs[_addr] = _isGenesis;
		if (_isGenesis){
			//updating to Genesis, remove from post-genesis if its there
			for(uint256 i = 0; i < postGenesisNFTs.length; i++) {
				if(postGenesisNFTs[i] == _addr) {
					postGenesisNFTs[i] = postGenesisNFTs[postGenesisNFTs.length - 1];
					postGenesisNFTs.pop();
				}
			}
		}else{
			//if its not genesis, remove it from the genesisNFT
			for(uint256 i = 0; i < genesisNFTs.length; i++) {
				if(genesisNFTs[i] == _addr) {
					genesisNFTs[i] = genesisNFTs[genesisNFTs.length - 1];
					genesisNFTs.pop();
				}
			}
		}
		emit UpdatedNFT(_addr, _isGenesis);
	}

	function postGenesisMint(uint256 NFTIndex) external{
		DIADataNFT diaDataNFTImpl = DIADataNFT(postGenesisNFTs[NFTIndex]);
		require(!diaDataNFTImpl.genesisPhase());
		require(diaDataNFTImpl.started());
		// Randomize for the case that not all Non-Common NFTs are minted yet
		uint256 newRank = NFTUtil.randInt(diaDataNFTImpl.NUM_PRIVILEGED_RANKS(), seed);		
		uint256 mintedRank = diaDataNFTImpl._mintDataNFT(msg.sender, newRank);

		// Transfer payment token to burn address
		require(ERC20(diaDataNFTImpl.paymentToken()).transferFrom(msg.sender, diaDataNFTImpl.burnAddress(), diaDataNFTImpl.burnAmount()), "Payment token transfer to burn address failed.");
		// Transfer payment token to minting pool
		require(ERC20(diaDataNFTImpl.paymentToken()).transferFrom(msg.sender, address(diaDataNFTImpl), diaDataNFTImpl.mintingPoolAmount()), "Payment token transfer to minting pool failed.");
		// Transfer payment token to source NFT pool
		require(ERC20(diaDataNFTImpl.paymentToken()).transferFrom(msg.sender, address(diaDataNFTImpl.diaSourceNFTImpl()), diaDataNFTImpl.diaSourceNFTImpl().getSourcePoolAmount(diaDataNFTImpl.sourceNFTId())), "Payment token transfer to source pool failed.");

		emit MintedDataNFT(postGenesisNFTs[NFTIndex], msg.sender, diaDataNFTImpl.numMintedNFTs(), mintedRank, false);
	}

	function genesisMint() external {

		uint256 genesisNFTIndex = NFTUtil.randInt(genesisNFTs.length, seed);

		DIADataNFT diaDataNFTImpl = DIADataNFT(genesisNFTs[genesisNFTIndex]);
		
		uint256 newRank = NFTUtil.randInt(diaDataNFTImpl.NUM_PRIVILEGED_RANKS(), seed);
		uint256 triedNFTIds = 0;

		while(!diaDataNFTImpl.started() ||
					!diaDataNFTImpl.genesisPhase() ||
					!diaDataNFTImpl.exists() ||
				  diaDataNFTImpl.numMintedNFTs() >= diaDataNFTImpl.NUM_PRIVILEGED_RANKS()) {
			require(triedNFTIds < genesisNFTs.length, "Couldn't find NFT to mint.");
			genesisNFTIndex = (genesisNFTIndex + 1) % (genesisNFTs.length);
			diaDataNFTImpl = DIADataNFT(genesisNFTs[genesisNFTIndex]);
			triedNFTIds += 1;
		}
		uint256 mintedRank = diaDataNFTImpl._mintDataNFT(msg.sender, newRank);
		// Transfer payment token to burn address
		require(ERC20(diaDataNFTImpl.paymentToken()).transferFrom(msg.sender, diaDataNFTImpl.burnAddress(), diaDataNFTImpl.burnAmount()), "Payment token transfer to burn address failed.");
		// Transfer payment token to minting pool
		require(ERC20(diaDataNFTImpl.paymentToken()).transferFrom(msg.sender, address(diaDataNFTImpl), diaDataNFTImpl.mintingPoolAmount()), "Payment token transfer to minting pool failed.");
		// Transfer payment token to source NFT pool
		require(ERC20(diaDataNFTImpl.paymentToken()).transferFrom(msg.sender, address(diaDataNFTImpl.diaSourceNFTImpl()), diaDataNFTImpl.diaSourceNFTImpl().getSourcePoolAmount(diaDataNFTImpl.sourceNFTId())), "Payment token transfer to source pool failed.");
		
		emit MintedDataNFT(genesisNFTs[genesisNFTIndex], msg.sender, diaDataNFTImpl.numMintedNFTs(), mintedRank, true);
	}
}
