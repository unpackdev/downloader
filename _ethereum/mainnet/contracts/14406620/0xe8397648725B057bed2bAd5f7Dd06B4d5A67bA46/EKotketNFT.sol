// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";

import "./EGovernanceBase.sol";
import "./EKotketNFTBase.sol";

contract EKotketNFT is EGovernanceBase, EKotketNFTBase, ERC721URIStorage, ERC721Enumerable {
    
    string public baseTokenURI;

    struct KotketInfo {
        KOTKET_GENES gene;        
        uint256 birthTime;
        string name;
    }

    mapping(uint=>KotketInfo) public kotketInfoMap;
    mapping (KOTKET_GENES => uint256) public winrateMap;

    event WinRateChanged(uint8 indexed gene, uint256 winrate, address setter);

    constructor(address _governanceAdress, string memory name, string memory symbol, string memory _baseTokenURI) EGovernanceBase(_governanceAdress) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(SC_MINTER_ROLE, _msgSender());
        baseTokenURI = _baseTokenURI;

        winrateMap[KOTKET_GENES.KITI] = 950;
        winrateMap[KOTKET_GENES.RED] = 955;
        winrateMap[KOTKET_GENES.BLUE] = 960;
        winrateMap[KOTKET_GENES.LUCI] = 965;
        winrateMap[KOTKET_GENES.TOM] = 970;
        winrateMap[KOTKET_GENES.KOTKET] = 975;
        winrateMap[KOTKET_GENES.KING] = 980;  
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyAdminPermission{
        baseTokenURI = _baseTokenURI;
    }

     function updateWinRate(uint8 _gene, uint256 _winrate) public onlyAdminPermission{
        require(_gene <= uint8(KOTKET_GENES.KING), "Invalid Gene");
        require(_winrate <= 1000, "Invalid Win Rate");

        KOTKET_GENES gene = KOTKET_GENES(_gene);
        winrateMap[gene] = _winrate;

        emit WinRateChanged(_gene, _winrate, _msgSender());   
    }

    function getGene(uint256 _tokenId) public view returns (uint8){
        return uint8(kotketInfoMap[_tokenId].gene);
    }

    function tokenExisted(uint256 _tokenId) public view returns (bool){
        return _exists(_tokenId);
    }

    function kotketBred(address _beneficiary,
        uint256 _tokenId, 
        uint8 _gene, 
        string memory _name, 
        string memory _metadataURI) public onlyMinterPermission{
        
        require(!tokenExisted(_tokenId), "TokenId Existed");

        require(_gene <= uint8(KOTKET_GENES.KING), "Invalid Gene");

        KOTKET_GENES gene = KOTKET_GENES(_gene);
       
        _safeMint(_beneficiary, _tokenId);

        
        kotketInfoMap[_tokenId].gene = gene;
        kotketInfoMap[_tokenId].birthTime = block.timestamp;
        kotketInfoMap[_tokenId].name = _name;

        _setTokenURI(_tokenId, _metadataURI);
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        
        delete kotketInfoMap[tokenId]; 
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}