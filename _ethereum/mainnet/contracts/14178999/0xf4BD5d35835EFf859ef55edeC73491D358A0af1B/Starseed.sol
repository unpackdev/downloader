// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./IERC721.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

// import "./console.sol";

contract Starseed is ERC721, ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    enum CharacterType { PEITHO, POLYTETE, PETROPE, PLECTRA, PAIA, PLENIA, PAGOS, PALCHI }

    IERC721 public polypixos;

    mapping(uint256 => bool) public usedPolypixos;

    mapping(uint256 => CharacterType) public polypixosCharacterTypes;

    mapping(address => uint256) public whitelist;

    uint256 private nextTokenId;

    string private tokenBaseURI;    

    event WhitelistAdded(address indexed addr, uint256 indexed tokenAmount);

    constructor(IERC721 _polypixos) ERC721("Starseed", "STARSEED")
    {
        polypixos = _polypixos;
        nextTokenId = nextTokenId.add(1);
    }

    function claim(uint256[] calldata tokenIDs) external nonReentrant {
        require(tokenIDs.length == 8, "Only 8 tokens can be used at a time");

        uint256 subSpeciesBitmap = 0xff; // 1 bit for each character type
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            _claim(tokenIDs[i], msg.sender);
            uint8 characterType = uint8(polypixosCharacterTypes[tokenIDs[i]]);
            subSpeciesBitmap = subSpeciesBitmap ^ (1 << characterType);
        }
        require(subSpeciesBitmap == 0, "Must own all 8 sub-species");

        _mint(1);
    }

    function _claim(uint256 tokenId, address tokenOwner) internal {
        require(tokenOwner == polypixos.ownerOf(tokenId), "Must own specified PolyPixos Token ID");
        require(!usedPolypixos[tokenId], "Already used");

        usedPolypixos[tokenId] = true;
    }

    function mintWhitelist(uint256 numberOfNfts) external nonReentrant payable {
        require(numberOfNfts > 0, "Cannot buy 0");
        require(whitelist[msg.sender] >= numberOfNfts, "Not enough allowance");

        whitelist[msg.sender] = whitelist[msg.sender].sub(numberOfNfts);

        _mint(numberOfNfts);
    }

    function _mint(uint256 numberOfNfts) internal {
        for (uint256 i = 0; i < numberOfNfts; i++) {
            _safeMint(msg.sender, nextTokenId); 
            nextTokenId = nextTokenId.add(1);
        }
    }
    
    function addWhitelist(address[] calldata addresses, uint256 numberOfMints) onlyOwner external {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = numberOfMints;
        }
    }

    function setCharacterTypes(uint256[] calldata tokenIDs, CharacterType characterType) onlyOwner external {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            polypixosCharacterTypes[tokenIDs[i]] = characterType;
        }
    }    

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function setTokenBaseURI(string memory _tokenBaseURI) public onlyOwner {
        tokenBaseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenBaseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
