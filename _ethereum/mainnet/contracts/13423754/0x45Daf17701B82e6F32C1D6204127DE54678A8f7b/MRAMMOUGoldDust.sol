// SPDX-License-Identifier: MIT

/*
dev by @bitcoinski
*/

pragma solidity ^0.8.4;

import "./AccessControl.sol";
import "./ERC1155.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Counters.sol";
import "./AbstractMintPassportFactory.sol";

import "./console.sol";


contract MRAMMOUGoldDust is AbstractMintPassportFactory  {
    using SafeMath for uint256; 
    using Counters for Counters.Counter;

    Counters.Counter private mpCounter; 

    mapping(uint256 => MRAMMOU) public MRAMMOUs;
    
    struct MRAMMOU {
        string tokenURI;
        bool exists;
    }

    string private baseTokenURI;
    string private ipfsURI;

    uint256 private ipfsAt;

    string public _contractURI;
   
    constructor(
       
    ) ERC1155("ipfs://ipfs/") {
        name_ = "MRAMMOU UTILITY TOKEN";
        symbol_ = "MRAMMOUUTILITY";
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0x81745b7339D5067E82B93ca6BBAd125F214525d3); 
        _setupRole(DEFAULT_ADMIN_ROLE, 0x57Aa377b489Bd2efd1B84182298D3CE5E2075C49); 
        _contractURI = "ipfs://QmRVpNy7h41asqQ5LngLjfmc7M5LGVmmUWM27kx1V975Cm";
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;    
    }   

    function setIpfsURI(string memory _ipfsURI) external onlyOwner {
        ipfsURI = _ipfsURI;    
    } 

    function endIpfsUriAt(uint256 at) external onlyOwner {
        ipfsAt = at;    
    } 

    function setIndividualTokenURI(uint256 id, string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE){
        require(exists(id), "ERC1155Metadata: Token does not exist");
        MRAMMOUs[id].tokenURI = uri;
        MRAMMOUs[id].exists = true;
    }  

    function _baseURI(uint256 tokenId) internal view returns (string memory) {
       
        if(tokenId > ipfsAt) {
            return baseTokenURI;
        } else {
            return ipfsURI;
        }
    }   

     function uri(uint256 _id) public view override returns (string memory) {
        require(totalSupply(_id) > 0, "URI: nonexistent token");

        if(MRAMMOUs[_id].exists){
            return MRAMMOUs[_id].tokenURI;
        }

        string memory baseURI = _baseURI(_id);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _id)) : "";
    } 

    function mint(address account, uint256 id, uint256 amount)
        public
        onlyOwner
    {
        _mint(account, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, "");
    }

    
    function withdrawEther(address payable _to, uint256 _amount) public onlyOwner
    {
        _to.transfer(_amount);
    }


     function setContractURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE){
        _contractURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}
