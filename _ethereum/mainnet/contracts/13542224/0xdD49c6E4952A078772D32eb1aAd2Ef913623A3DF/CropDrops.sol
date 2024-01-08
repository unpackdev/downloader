//contracts/Tomaximus.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";


contract CropDrops is ERC1155, Ownable {
		// Contract name
  	string public name;
  	// Contract symbol
  	string public symbol;
    uint256 public constant EVILTOMATOES = 0;
    string public _baseTokenURI = "https://cropclash.mypinata.cloud/ipfs/QmeVk2VCa8KyBs2q9WX4k8WZgnGVWEw2LxzYtrWZiqYoy1/";
    address[] public owners;

    // function createToken(string tokenName, uint256 tokenId, )
	function addNewToken(uint DropID, uint ntokens, bytes memory IPFS_hash) public onlyOwner {
	    _mint(msg.sender, DropID, ntokens, IPFS_hash);
	}

	function addToAllowList(address[] calldata addresses) external onlyOwner {
      for (uint256 i = 0; i < addresses.length; i++) {
        require(addresses[i] != address(0), "Can't add a null address");
        owners.push(addresses[i]);
      }
    }

	function remove(uint index)  public {
        // Move the last element into the place to delete
        owners[index] = owners[owners.length - 1];
        // Remove the last element
        owners.pop();
    }

	function clearAllowList() external onlyOwner {
      delete owners;
    }

	constructor() onlyOwner ERC1155(_baseTokenURI){
        _mint(msg.sender, EVILTOMATOES, 120, "");
				name = "Crop Clash Halloween";
    }

	function sendAirDrop(uint256 tokenid) external onlyOwner{
	    for (uint i=0; i< owners.length; i++) {
            safeTransferFrom(0x4c5e309abc3A752afD2Baab6b302a90fA2a63dF2, owners[i], tokenid, 1, '0x00' );
        }
	}

    function getOwners() public onlyOwner view returns( address  [] memory){
        return owners;
    }

    function getOwnersLength() public onlyOwner view returns( uint256){
        return owners.length;
    }

    function setTokenURI(string memory id) public onlyOwner{
        _baseTokenURI = id;
    }

    function setBaseURI(string memory base) public onlyOwner{
        _setURI(base);
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        return string(
            abi.encodePacked(
                _baseTokenURI,
                Strings.toString(_tokenId),
                ".json"
            )
        );
    }

	function contractURI() public view returns (string memory) {
        return _baseTokenURI;
    }

}

