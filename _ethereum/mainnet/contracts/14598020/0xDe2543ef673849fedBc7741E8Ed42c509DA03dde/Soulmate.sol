// contracts/Soulmate.sol
// SPDX-License-Identifier: MIT

// 	@lanadenina x @ValentinChmara
//
//
//       ::::::::       ::::::::      :::    :::       :::          :::   :::           :::    :::::::::::       ::::::::::                ::::::::       ::::::::       :::  
//     :+:    :+:     :+:    :+:     :+:    :+:       :+:         :+:+: :+:+:        :+: :+:      :+:           :+:                      :+:    :+:     :+:    :+:      :+:   
//    +:+            +:+    +:+     +:+    +:+       +:+        +:+ +:+:+ +:+      +:+   +:+     +:+           +:+                      +:+            +:+    +:+      +:+    
//   +#++:++#++     +#+    +:+     +#+    +:+       +#+        +#+  +:+  +#+     +#++:++#++:    +#+           +#++:++#                 +#++:++#++     +#+    +:+      +#+     
//         +#+     +#+    +#+     +#+    +#+       +#+        +#+       +#+     +#+     +#+    +#+           +#+                             +#+     +#+    +#+      +#+      
// #+#    #+#     #+#    #+#     #+#    #+#       #+#        #+#       #+#     #+#     #+#    #+#           #+#              #+#     #+#    #+#     #+#    #+#      #+#       
// ########       ########       ########        ########## ###       ###     ###     ###    ###           ##########       ###      ########       ########       ##########                                                                                                                                                  
// 	
//
//
//		Contact me for any solidity development : valentinchmara@gmail.com / https://crocoweb.fr
//		Crocoweb by SmartBusiness https://crocoweb.fr
                                                                       
pragma solidity ^0.8.0;
  
import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
	
contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

contract Soulmate is ERC721, Ownable, Pausable { 
	// Lib
	using Strings for uint256;
	using SafeMath for uint256;
 	
	// Variables initialization
	address proxyRegistryAddress;
	address private _creator; 
	uint256 private _nbTransfers = 0; // Count transfer number to modify the api at each transfer until reach _maxTransfers
	uint256 private _maxTransfers = 10;  // Maximum soulmate apparence 
	string private _base = "https://api.soulmate.earth/soulmate/"; 	

	function creator() public view virtual returns(address) {
		return _creator;
	}

	modifier onlyCreator() {
		require(creator() == _msgSender(), "caller is not the creator");
		_;
	}

	constructor (address _proxyRegistryAddress) ERC721("Soulmate", "SOUL"){
		_creator = _msgSender();
		_nbTransfers = 0;
		proxyRegistryAddress = _proxyRegistryAddress;
	}

	function mint() public onlyCreator {
		if(_exists(0) && ownerOf(0) != address(0)){
			_burn(0);
			if(paused())
				_unpause();
		}
		_safeMint(creator(), 0, "");
	}
	
	function totalTransfers() public view virtual returns(uint256) {
		return _maxTransfers;
	}

	function _incrementTransfer() private {
		_nbTransfers = _nbTransfers < _maxTransfers ? _nbTransfers + 1 : _nbTransfers;
	}
	
	function viewTransfer() public view returns (uint256){
		return _nbTransfers;
	}
	
	function changeURI(string memory newURI) public onlyCreator {
		_base = newURI;
	}	

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_base, (_tokenId.add(_nbTransfers)).toString()));
    }

	function _transfer(address from, address to, uint256 tokenId) internal virtual override{	
		require(!paused(), "Token cannot be trade, you can just mint one Soul");
		super._transfer(from, to, tokenId);
	
		if (viewTransfer() != _maxTransfers.sub(1)){
			_pause();
		}
		_incrementTransfer();
    }

	function setApprovalForAll(address operator, bool approved) public virtual override {
		require(!paused(), "Token cannot be trade, you can just mint one Soul");
        _setApprovalForAll(_msgSender(), operator, approved);
    }
}