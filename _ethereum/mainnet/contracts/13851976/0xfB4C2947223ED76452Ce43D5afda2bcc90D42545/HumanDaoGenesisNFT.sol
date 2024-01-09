// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract HumanDaoGenesisNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address private _owner;

    using Address for address;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    string public metaURI; 


    constructor() ERC721("Human DAO Genesis", "HDAOGEN") {
        _owner = msg.sender;
        metaURI = "ipfs://QmSg4aZRUwCVNRk59Jj9cFsfUThyiCArjszjeaCj4SSfiK";
    }

    function mint(address to_) external onlyOwner {
        _mintNFT(to_);
    }

    /* function to call when minting _mintNFT
    *  automatically increments NFT token ID upon minting, first ID will be 1
    *  @param address to - address receiving the NFT
    */
    function _mintNFT(address to) internal {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(to, newTokenId);
    }
    
    // override so all tokens have same URI since all will have same artwork
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return metaURI;
    }

    function updateMetaURI(string memory _metaURI) public onlyOwner {
        metaURI = _metaURI;
    }
}



