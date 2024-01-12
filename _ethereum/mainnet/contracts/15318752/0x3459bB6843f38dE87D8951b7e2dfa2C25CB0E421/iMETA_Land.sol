// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Open Zeppelin libraries for controlling upgradability and access.
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./Strings.sol";

contract iMETA_Land is Initializable, UUPSUpgradeable, OwnableUpgradeable, ERC721URIStorageUpgradeable {

    event event_mint(uint256 indexed quadId,address indexed sender);
    event event_delete(uint256 indexed quadId,address indexed sender);
    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    

    uint256[] public NFTList;
    address marketcontractAddress;
    uint256 internal constant GRID_SIZE = 249;

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner{}
    
    ///@dev initialize
    function initialize(address marketplaceAddress) public initializer {
        _transferOwnership(_msgSender());
         __ERC721_init("iMETA_Land", "iMETAverse");
         marketcontractAddress = marketplaceAddress;
         setApprovalForAll(marketcontractAddress, true); //grant transaction permission to marketplace
    }

    ///@dev Update MarketContract Address
    function updatamarketplace(address marketplaceAddress) public onlyOwner{
         marketcontractAddress = marketplaceAddress;
         setApprovalForAll(marketcontractAddress, true); //grant transaction permission to marketplace
    }
    
    ///@dev check MarketContract Address
    function view_marketplace() public view returns (address) {
        return marketcontractAddress; // cast to zero
    }

    ///@dev Contract has Ether
    function ContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    ///@dev NFT mint
    function mintQuad(uint256 x, uint256 y) public onlyOwner returns(uint) {
        uint256 quadId;
        uint256 id = x + y * GRID_SIZE;
        quadId = id;
        _mint(msg.sender, quadId);
        _setTokenURI(quadId,  _maketokenURI(quadId));
        NFTList.push(quadId);
        emit event_mint(quadId, msg.sender);
        return quadId;
    }
    ///@dev Create NFT_url
    function _maketokenURI(uint256 quadId) internal returns (string memory) {
        require(_exists(quadId), "ERC721URIStorage: URI query for nonexistent token");
        return
            string(
                abi.encodePacked(
                    "https://www.imetav.io/landDetail/",
                    Strings.toString(quadId),
                    "/land.json"
                )
            );
    }
    ///@dev delete NFT
    function delete_NFT(uint _tokenId) public {
        uint index;
		for (uint i = 0; i < NFTList.length; i++) {
			if(NFTList[i] == _tokenId){
				index = i;
			}
    	}
		NFTList[index] = NFTList[NFTList.length - 1];
        NFTList.pop();
        emit event_delete(_tokenId, msg.sender);
    }

    ///@dev Get the list of NFT tokens that the address has
    function get_Token(address _address) public view returns (uint256[] memory){
        uint currentIndex = 0;
        uint256[] memory _NFTList = NFTList;
        uint256[] memory items = new uint256[](balanceOf(_address));
        for(uint i = 0; i < _NFTList.length; i++){
            if(ownerOf(_NFTList[i]) == _address){
                items[currentIndex] = _NFTList[i];
                currentIndex += 1; //total length
            }
        }
        return items;
    }
    
    function get_TokenList() public view returns (uint256[] memory){
        return NFTList;
    }
    
    function get_TokenListSize() public view returns (uint) {
        return uint(NFTList.length);
    }
    
}