//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract Trophy is Ownable, ERC721, ERC721Enumerable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;
    uint256 public constant MAX_SUPPLY = 476;
    string public uri;
    string public provenance;

    event SetBaseURI(string baseUri);
    event SetProvenance(string provenance);
    event Minted(address indexed user, uint256 entries);

    constructor(string memory _nftName, string memory _nftSymbol)
        ERC721(_nftName, _nftSymbol)
    {}

    function setBaseURI(string calldata _uri) public onlyOwner {
        uri = _uri;
        emit SetBaseURI(_uri);
    }

    function setProvenance(string calldata _provenance) public onlyOwner {
        provenance = _provenance;
        emit SetProvenance(_provenance);
    }

    function mint(uint256 numOfTokens) external nonReentrant onlyOwner {
        require(
            _tokenIds.current() + numOfTokens <= MAX_SUPPLY,
            "Max mints reached"
        );

        for (uint256 i = 0; i < numOfTokens; i++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current());
        }

        emit Minted(msg.sender, numOfTokens);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(tokenId < _tokenIds.current(), "Token id exceeds max limit");

        return string(abi.encodePacked(uri, tokenId.toString(), ".json"));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        return super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
