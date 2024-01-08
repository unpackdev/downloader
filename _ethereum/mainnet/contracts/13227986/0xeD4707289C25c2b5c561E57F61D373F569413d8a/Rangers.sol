//SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
 
interface CamoInterface {
    function tokensOfOwner(address) external view returns(uint256[] memory);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract Rangers is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private tokenIds;

    string public _baseURIextended = "https://gateway.pinata.cloud/ipfs/QmbB7t8x1UZqVH5ThzjRHKDKN9fy12esdVhKxJAzpDfgxq/";
    address public contractAddress = 0x71C20E217E9CcaF2dB10D724390B44B4191Cc5D2;
    CamoInterface camoContract = CamoInterface(contractAddress);

    mapping(uint256=>bool) public nftMinted;
        
    constructor () ERC721("RANGERS", "RNGR") {}

    function mintAllWithCAMO() public nonReentrant {
        uint256[] memory ids = camoContract.tokensOfOwner(msg.sender);
        require(ids.length != 0, "you dont have any CAMO");
        require(ids.length <= 20, "Max 20 Allowed in 1 Transaction");
        for (uint256 i = 0; i < ids.length; i++) {
            require(!_exists(ids[i]), "RANGERS_ALREADY_MINTED_TRY_MINT_BY_ID");
        }
       
        for (uint256 i = 0; i < ids.length; i++) {
            if (!nftMinted[ids[i]]) {
                nftMinted[ids[i]] = true;
                tokenIds.increment();
                _safeMint(msg.sender, ids[i]);    
            }
        }
    }

    function mintById(uint256 tokenId) public nonReentrant {
        require(!_exists(tokenId), "RANGERS_ALREADY_MINTED");
        require(camoContract.ownerOf(tokenId) == msg.sender, "NOT_OWNER_OF_CAMO");
       
        _safeMint(msg.sender, tokenId);     
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }
   
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }
        
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
}
