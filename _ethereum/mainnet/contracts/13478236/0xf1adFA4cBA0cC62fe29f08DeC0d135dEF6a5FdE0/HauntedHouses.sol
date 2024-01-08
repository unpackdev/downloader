pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract HauntedHouses is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIds;

    uint256 public constant MAX_SUPLLY = 3333;
    bool public giveaway = false;
    string public baseURI = "";

    constructor() ERC721("HauntedHouses", "HHouses") {
        _tokenIds.increment();
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

    function mint() public {
        require(giveaway, "Giveaway not yet open");
        require(totalSupply() <= MAX_SUPLLY, "Sold Out");
        require(balanceOf(msg.sender) == 0, 'Each address may only own mint one house.');

        _mintInternal(msg.sender);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            tokenId <= totalSupply(),
            "URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index =0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function setGiveaway(bool shouldGiveaway) external onlyOwner {
        giveaway = shouldGiveaway;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function _mintInternal(address owner) private {
        uint256 newItemId = _tokenIds.current();
        _safeMint(owner, newItemId);
        _tokenIds.increment();
    }
}
