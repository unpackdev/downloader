//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./EnumerableMap.sol";
import "./ERC721Enumerable.sol";
import "./ERC1155.sol";

contract LukaScience is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    // Token detail
    struct LukaScienceDetail {
        uint256 first_encounter;
    }

    // Events
    event TokenMinted(uint256 tokenId, address owner, uint256 first_encounter);

    // Token Detail
    mapping(uint256 => LukaScienceDetail) private _lukaScience;

    // Provenance number
    string public PROVENANCE = "";

    // Maximum amount of tokens to supply.
    uint256 public MAX_TOKENS = 550;

    // Base URI
    string private baseURI;

    /**
     * Contract constructor
     */
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    /**
     * With
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /*
     * Set provenance once it's calculated
     */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        PROVENANCE = provenanceHash;
    }

    function reserveTokens() public onlyOwner {
        uint256 i;
        uint256 tokenId;
        uint256 first_encounter = block.timestamp;

        for (i = 1; i <= 50; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }
    }

    function reserveTwentyTokens() public onlyOwner {
        uint256 i;
        uint256 tokenId;
        uint256 first_encounter = block.timestamp;

        for (i = 1; i <= 20; i++) {
            tokenId = totalSupply().add(1);
            if (tokenId <= MAX_TOKENS) {
                _safeMint(msg.sender, tokenId);
                emit TokenMinted(tokenId, msg.sender, first_encounter);
            }
        }
    }

    /**
     * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
     */
    function setBaseURI(string memory BaseURI) public onlyOwner {
        baseURI = BaseURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Get the token detail
     */
    function getLukaScienceDetail(uint256 tokenId)
        public
        view
        returns (LukaScienceDetail memory detail)
    {
        require(_exists(tokenId), "Token was not minted");

        return _lukaScience[tokenId];
    }
}
