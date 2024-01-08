// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.3;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./Ownable.sol";

contract NFT is ERC721, ERC721Enumerable, ERC721Pausable, Ownable {
    string private _baseTokenURI;
    bool private _selling = false;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
    }

    function withdraw() external payable virtual onlyOwner {
        require(payable(msg.sender).send(address(this).balance), ".");
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function toggleSale() external onlyOwner {
        _selling = !_selling;
    }

    function selling() external view returns (bool status) {
        return _selling;
    }

    modifier whenSelling {
        require(_selling, "sale is not active");
        _;
    }

    /**
     * @notice Returns a list of all tokenIds assigned to an address.
     * Taken from https://ethereum.stackexchange.com/questions/54959/list-erc721-tokens-owned-by-a-user-on-a-web-page
     * @param user get tokens of a given user
     */

    function tokensOfOwner(address user)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(user);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory output = new uint256[](tokenCount);
            for (uint256 index = 0; index < tokenCount; index++) {
                output[index] = tokenOfOwnerByIndex(user, index);
            }
            return output;
        }
    }

    /**
     * @dev Compat with ERC721, ERC721Metadata, ERC721Enumerable
     *      See {IERC165-supportsInterface}.
     */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev insept _baseTokenURI into ERC721
     */

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev update token uri on sale end
     */

    function setBaseTokenURI(string memory baseTokenURI)
        public
        virtual
        onlyOwner
    {
        _baseTokenURI = baseTokenURI;
    }

    /**
     * @dev
     */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Pausable, ERC721Enumerable, ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
