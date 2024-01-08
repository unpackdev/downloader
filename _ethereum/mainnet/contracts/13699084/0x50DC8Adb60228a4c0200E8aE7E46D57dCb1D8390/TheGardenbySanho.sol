// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ECDSA.sol";

contract TheGardenbySanho is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    /**
     * @dev Emitted when token and contract owner approves a property change to their token.
     * The old token will be burned, and a new token will be minted with the associated property change.
     */
    event ApprovedAttributeChange(uint256 indexed oldTokenId, uint256 indexed newTokenId, string indexed attrName, string attrValueString);

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("The Garden by Sanho", "GARDEN") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://sanhogarden.xyz/nft/token-meta/the-garden/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://sanhogarden.xyz/nft/contract-meta/the-garden";
    }

    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }


    /**
     * Burn and re-mint a token with owner approval to indicate a change in property on that token.
     * Requires contract owner approval (via them sending the transaction)
     * Requires token owner approval (via them signing the change message)
     **/
    function changeTokenAttribute(
        uint256 tokenId, 
        string memory attrName,
        string memory attrValueStr,
        string memory changeMessage, 
        bytes memory signature
    ) public onlyOwner {
        address tokenOwner = ownerOf(tokenId);
        bytes32 messageHash = toEthSignedMessageHash(bytes(changeMessage));
        address messageSigner = ECDSA.recover(messageHash, signature);
        require(tokenOwner == messageSigner, "Token property change message must be signed by token owner!");

        uint256 newTokenId = _tokenIdCounter.current();
        _burn(tokenId);
        _safeMint(tokenOwner, newTokenId);
        _tokenIdCounter.increment();

        emit ApprovedAttributeChange(tokenId, newTokenId, attrName, attrValueStr);
    }

    /**
     * Note: ECDSA library will contain this in future versions of openzeppelin
     **/
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    // The following functions are overrides required by Solidity.

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
