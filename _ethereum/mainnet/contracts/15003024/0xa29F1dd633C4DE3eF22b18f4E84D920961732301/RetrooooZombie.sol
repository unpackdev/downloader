// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC721.sol";
import "./ERC721AQueryable.sol";

contract RetrooooZombie is ERC721AQueryable, Ownable {
    using Strings for uint256;

    address public constant BLACKHOLE = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant MAX_SUPPLY = 1200;
    uint256 public constant TEAM_RESERVE_NUM = 30;

    IERC721 public immutable _inhabitant;

    uint256 public _teamMintNum;
    bool public _claimActive;
    string public _matadataURI;
    string public _prerevealURL = "ipfs://QmQHP4oN5PsPBhabdhXNRzx4npL4NErjVmtAGkKpjTQnAe";

    constructor(address inhabitant)
        ERC721A("RetrooooZombie", "RTZ")
    {
        _inhabitant = IERC721(inhabitant);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _matadataURI;
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : _prerevealURL;
    }

    function claim(uint256[] memory tokenIds) external {
        require(_claimActive, "Claiming is not started yet");
        require(
            tokenIds.length > 2 && tokenIds.length % 3 == 0,
            "Wrong inhabitant ids"
        );
        uint256 num = tokenIds.length / 3;
        require(_totalMinted() + num <= MAX_SUPPLY, "Exceed max supply");

        for (uint256 i = 0; i < tokenIds.length; ) {
            _inhabitant.transferFrom(msg.sender, BLACKHOLE, tokenIds[i]);
            unchecked {
                i++;
            }
        }

        _safeMint(msg.sender, num);
    }

    function teamMint(uint256 num, address to) external onlyOwner {
        require(_totalMinted() + num <= MAX_SUPPLY, "Exceed max supply");
        require(_teamMintNum + num <= TEAM_RESERVE_NUM, "Exceed team reserve");
        
        _teamMintNum += num;
        _safeMint(to, num);
    }

    function flipClaimActive() external onlyOwner {
        _claimActive = !_claimActive;
    }

    function setMetadataURI(string calldata metadataURI) external onlyOwner {
        _matadataURI = metadataURI;
    }
}
