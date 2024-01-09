// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

/**
 * @title ERC721EfficientEnumerable
 * ERC721EfficientEnumerable - ERC721 contract that uses counters for more gas-efficient tokenID enumeration.
 * For more details: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
 */
abstract contract ERC721EfficientEnumerable is ERC721, Ownable {
    using Counters for Counters.Counter;

    /**
     * We rely on the OZ Counter util to keep track of the next available ID.
     * We track the nextTokenId instead of the currentTokenId to save users on gas costs. 
     */ 
    Counters.Counter private _nextTokenId;

    /*
    * @dev The maximum ammount of tokens offered by this contract
    */
    uint256 private constant _maxTokenSupply = 10000;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _nextTokenId.increment();
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function _mintTo(address _to) internal virtual {
        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(_to, currentTokenId);
    }

    /**
        @dev Returns the total tokens minted so far.
        1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function maxSupply() public pure returns (uint256) {
        return _maxTokenSupply;
    }

    function availableTokens() public view returns (uint256) {
        return maxSupply() - totalSupply();
    }

    /// @dev Check whether another token is still available
    modifier ensureAvailability(uint256 amount) {
        require(availableTokens() >= amount, "409"); // Insufficient tokens available
        _;
    }

    /// @dev Check whether tokenId exists
    modifier ensureExistance(uint256 tokenId) {
        require(_exists(tokenId), "404"); // Token not found
        _;
    }
}
