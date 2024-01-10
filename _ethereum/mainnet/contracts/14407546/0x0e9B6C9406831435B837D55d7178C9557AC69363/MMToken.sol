// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Royalty.sol";

contract MMToken is ERC721, Ownable, Royalty {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    event Minted(uint256 indexed tokenId, address indexed minter);

    constructor() ERC721("MAGARIMONO STUDIOS", "MM") {}

    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => string) private idToURLs;

    function mint(string memory url, uint96 royalty) external onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, tokenId);
        idToURLs[tokenId] = url;
        setRoyalty(tokenId, payable(owner()), royalty);
        _tokenIdCounter.increment();
        emit Minted(tokenId, owner());
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: nonexistent token");
        return idToURLs[tokenId];
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _resetTokenRoyalty(tokenId);
        _burn(tokenId);
    }

    function owns(address owner) external view returns (uint256[] memory) {
        uint256 max = _tokenIdCounter.current();
        uint256[] memory tokenIds = new uint256[](balanceOf(owner));

        uint256 index = 0;
        for (uint256 tokenId = 0; tokenId < max; tokenId++) {
            address tokenOwner = ownerOf(tokenId);
            if (owner == tokenOwner) {
                tokenIds[index] = tokenId;
                index = index.add(1);
            }
        }
        return tokenIds;
    }

    function updateRoyalty(
        uint256 id,
        address addr,
        uint96 feeNumerator
    ) external onlyOwner {
        setRoyalty(id, addr, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, Royalty)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            Royalty.supportsInterface(interfaceId);
    }
}
