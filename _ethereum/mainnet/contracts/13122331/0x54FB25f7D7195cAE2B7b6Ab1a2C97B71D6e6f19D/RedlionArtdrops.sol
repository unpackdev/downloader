pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./BitMaps.sol";
import "./ERC2981.sol";

interface IRedlionGazette {
    function tokenIdToIssue(uint) external view returns (uint);
}

contract RedlionArtdrops is Context, AccessControlEnumerable, Ownable, ERC2981, ERC721, ERC721Enumerable {

    using BitMaps for BitMaps.BitMap;

    IRedlionGazette public gazette;
    uint public royaltyFee = 1000; // 10000 * percentage (ex : 0.5% -> 0.005)
    mapping (uint => string) public artdropToIPFS;
    mapping (address => BitMaps.BitMap) private claimedArtdrops;
    string private _baseTokenURI;


    constructor(
        string memory name,
        string memory symbol, 
        string memory baseTokenURI,
        address deployedGazette
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        gazette = IRedlionGazette(deployedGazette);
    }

    function changeBaseURI(string memory baseTokenURI) onlyOwner public {
        _baseTokenURI = baseTokenURI;
    }

    function launchArtdrop(uint issue, string memory ipfs) onlyOwner public {
        artdropToIPFS[issue] = ipfs;
    }

    function changeDeployedGazette(address deployedGazette) onlyOwner public {
        gazette = IRedlionGazette(deployedGazette);
    }

    function changeIPFS(uint issue, string memory ipfs) onlyOwner public {
        artdropToIPFS[issue] = ipfs;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setRoyaltyFee(uint fee) onlyOwner public {
        royaltyFee = fee;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public override view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        return (owner(), (_salePrice*royaltyFee)/10000);
    }
    
    function claim(uint tokenId) public {
        require(!claimedArtdrops[msg.sender].get(tokenId), "CLAIM:ALREADY CLAIMED ISSUE");
        require(bytes(artdropToIPFS[gazette.tokenIdToIssue(tokenId)]).length > 0, "CLAIM:ISSUE NOT ARTDROPPED YET");
        claimedArtdrops[msg.sender].set(tokenId);
        _safeMint(msg.sender, tokenId);
    }

    function isClaimed(address user, uint issue) public view returns (bool) {
        return claimedArtdrops[user].get(issue);
    }

    function tokenURI(uint tokenId) public override(ERC721) view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), artdropToIPFS[gazette.tokenIdToIssue(tokenId)]));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC2981, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}