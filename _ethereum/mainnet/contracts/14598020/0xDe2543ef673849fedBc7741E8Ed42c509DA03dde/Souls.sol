// contracts/Souls.sol
// SPDX-License-Identifier: MIT

// 	@lanadenina x @ValentinChmara
//
//
//       ::::::::       ::::::::      :::    :::       :::        ::::::::                ::::::::       ::::::::       :::  
//     :+:    :+:     :+:    :+:     :+:    :+:       :+:       :+:    :+:              :+:    :+:     :+:    :+:      :+:   
//    +:+            +:+    +:+     +:+    +:+       +:+       +:+                     +:+            +:+    +:+      +:+    
//   +#++:++#++     +#+    +:+     +#+    +:+       +#+       +#++:++#++              +#++:++#++     +#+    +:+      +#+     
//         +#+     +#+    +#+     +#+    +#+       +#+              +#+                     +#+     +#+    +#+      +#+      
// #+#    #+#     #+#    #+#     #+#    #+#       #+#       #+#    #+#      #+#     #+#    #+#     #+#    #+#      #+#       
// ########       ########       ########        ########## ########       ###      ########       ########       ##########
//
//
// 	
//		Contact me for any solidity development : valentinchmara@gmail.com 
// 		Crocoweb by SmartBusiness https://crocoweb.fr

pragma solidity >=0.8.0; 

import "./ERC1155.sol"; 
import "./Strings.sol"; 
import "./Ownable.sol";
import "./Soulmate.sol";

contract Souls is ERC1155, Ownable {
	// lib 
	using Strings for uint256;	
	
    // Variable initialization
    string private _name;
    string private _symbol;
	string private _baseURI = "https://api.soulmate.earth/souls/";
	uint256 private _maxSupply;
	uint256 public tokenId = 0;
	Soulmate public s; 
	address[10] public firstOwners;
	address proxyRegistryAddress;	

	modifier onlySoulmateCreator(){
		require(_msgSender() == s.creator());
		_;
	}

	constructor(Soulmate addr, address _proxyRegistryAddress) ERC1155(_baseURI){
		
		_name = "Souls";
		_symbol = "SOULS";
		s = addr;
		_maxSupply = s.totalTransfers();
		proxyRegistryAddress = _proxyRegistryAddress;	
	}
	
	function uri(uint _tokenId) override view public returns (string memory){
		require(_tokenId >= 0 && _tokenId < _maxSupply, "Token Id doesn't exist.");
		return string(abi.encodePacked(super.uri(_tokenId), _tokenId.toString()));
	}
	
	function setURI(string memory newURI) external virtual {
		require(s.creator() == _msgSender(), "You need to be the soulmate creator");
		_setURI(newURI);
	}

	function totalSupply() external view virtual returns(uint256) {
		return _maxSupply; 
	}

	function name() external view virtual returns(string memory) {
        	return _name;
    	}

	function symbol() external view virtual returns (string memory) {
        	return _symbol;
    	}
	
	function mint() external {
		require(tokenId < _maxSupply, "Max supply reached");
        require(_msgSender() == address(s.ownerOf(0)), "You need to be owner of the Soulmate (SOUL) to be able to mint");
		for(uint256 i=0; i < _maxSupply; i++){
			require(firstOwners[i] != _msgSender(), string(abi.encodePacked("You already minted the token ",(i).toString())));
		}
		_mint(_msgSender(), tokenId, 1, "");
		firstOwners[tokenId] = _msgSender(); 
		tokenId++;
	}

	function superMint(address _to) external onlySoulmateCreator{
		require(tokenId < _maxSupply, "Max supply reached");
		for(uint256 i=0; i < _maxSupply; i++){
			require(firstOwners[i] != _to, string(abi.encodePacked("You already minted the token ",(i).toString())));
		}
		_mint(_to, tokenId, 1, "");
		firstOwners[tokenId] = _to; 
		tokenId++;
	}
	
}
