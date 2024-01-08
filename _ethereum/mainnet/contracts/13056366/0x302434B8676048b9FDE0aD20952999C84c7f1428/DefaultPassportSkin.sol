pragma solidity 0.5.16;

import "./ERC721Full.sol";
import "./Counters.sol";

import "./Ownable.sol";

contract DefaultPassportSkin is ERC721Full, Ownable {

    /* ========== Libraries ========== */

    using Counters for Counters.Counter;

    /* ========== Private variables ========== */

    Counters.Counter internal _tokenIds;

    /* ========== Events ========== */

    event BaseURISet(string _baseURI);

    /* ========== Constructor ========== */

    constructor(
        string memory _name,
        string memory _symbol
    )
        ERC721Full(_name, _symbol)
        public
    {}

    /* ========== Restricted Functions ========== */

    /**
     * @dev Mints a new default skin with an optional _tokenURI
     *
     * @param _to The receiver of the skin
     */
    function mint(
        address _to,
        string calldata _tokenURI
    )
        external
        onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();
        _mint(_to, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);

        return newTokenId;
    }

    /**
     * @dev Sets the base URI that is appended as a prefix to the
     *      token URI.
     */
    function setBaseURI(
        string calldata _baseURI
    )
        external
        onlyOwner
    {
        _setBaseURI(_baseURI);
        emit BaseURISet(_baseURI);
    }

}
