// SPDX-License-Identifier: AGPL-3.0-or-later










pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155.sol";
import "./ECDSA.sol";

contract Light is Ownable, ERC1155, ReentrancyGuard {
	
	using ECDSA for bytes32;
	using Strings for uint256;

	address constant DEAD = address(0x000000000000000000000000000000000000dEaD);
	
	address public root;
	bool initialized;
	uint256 maxSupply = 10000;
	uint256 public minted = 0;
	
	mapping(address=>bool) claimedWL;
	mapping(address=>bool) claimedDC;

	string public name = "Light";
    string public symbol = "Light";
    string internal baseTokenURI;
	
	constructor() ERC1155("") {}

	function initialize(address root_) external onlyOwner{
		require(!initialized, "only initialized once");
		initialized = true;
		root = root_;
	}
	
	function claimWL(bytes memory _signature) external nonReentrant{
		bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, "LightWL"));
		require(isValidSignature(msgHash, _signature), "Not authorized to mint");
		require(!claimedWL[msg.sender], "Already claimed.");
		claimedWL[msg.sender] = true;
		_mintTo(msg.sender);
	}
	
	function claimDC(bytes memory _signature) external nonReentrant{
		bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, "LightDC"));
		require(isValidSignature(msgHash, _signature), "Not authorized to mint");
		require(!claimedDC[msg.sender], "Already claimed.");
		claimedDC[msg.sender] = true;
		_mintTo(msg.sender);
	}

	function _mintTo(address account) internal{
		require(minted < maxSupply, "exceed supply");
		minted++;
		_mint(account, 0, 1, "");
	}
	
	function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bool isValid) {
        //bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
		//bytes32 signedHash = ECDSA.toEthSignedMessageHash(hash);
        return hash.recover(signature) == root;
    }
	
	function burn(address addressToBurn) external{
		safeTransferFrom(addressToBurn, DEAD,  0, 1, "");
	}
	
	function devMint(address[] calldata _addr, uint256[] calldata amount) external onlyOwner{
		uint256 i;
		uint256 addrLen = _addr.length;
		uint256 batchTotal = 0;
        for (i = 0; i < addrLen;){
            batchTotal += amount[i];
			unchecked{ ++i;}
		}
		minted+= batchTotal;
		require(minted <= maxSupply, "exceed max supply.");
		for (i = 0; i < addrLen;){
			if(amount[i] >0) _mint(_addr[i], 0, amount[i], "");
			unchecked{ ++i;}
		}
	}
	
	function withdraw() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
    }

	function setURI(string memory _newBaseMetadataURI) public onlyOwner {
        baseTokenURI = _newBaseMetadataURI;
        _setURI(_newBaseMetadataURI);
    }

    function uri(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, _tokenId.toString()));
    }
	
	fallback() external payable {}
    receive() external payable {}
	

}