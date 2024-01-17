// SPDX-License-Identifier: MIT
// Author: Africarare

pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Ticket is ERC721, Ownable {
    constructor() ERC721("NedBankTicket", "NED") {}

    /**
     * @dev storage
     */
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public numMinted = 0;
    uint256 public maxSupply = 126;
    mapping(uint256 => string) private _tokenURIs;

    string public _baseURIextended =
        "https://ipfs.io/ipfs/bafybeiapj4f5pbsygydhq4ds5qevobdj3wjvdoybpkr6gctynwegqokbzq/";
    string public _headURIextended = ".json";

    /**
     * @dev errors
     */
    error SupplyCapExceeded();

    /**
     * @dev sets supply cap
     */
    function _setSupplyCap(uint256 amount) external onlyOwner {
        maxSupply = amount;
    }

    /**
     * @dev validation logic
     */
    function beforeNonExceededSupplyCap(
        uint256 _numToMint,
        uint256 _numMinted,
        uint256 _maxSupply
    ) internal pure {
        if (_numMinted + _numToMint > _maxSupply) {
            revert SupplyCapExceeded();
        }
    }

    /**
     * @dev validation interface
     */
    modifier nonExceededSupplyCap(uint256 numToMint) {
        beforeNonExceededSupplyCap(numToMint, numMinted, maxSupply);
        _;
    }

    /**
     * @dev returns base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * @dev sets base URI
     */
    function _setBaseURI(string memory baseURI) external onlyOwner {
        _baseURIextended = baseURI;
    }

    /**
     * @dev returns head URI
     */
    function _headURI() internal view virtual returns (string memory) {
        return _headURIextended;
    }

    /**
     * @dev sets head URI
     */
    function _setHeadURI(string memory headURI) external onlyOwner {
        _headURIextended = headURI;
    }

    /**
     * @dev sets token URI
     */
    function _setTokenURI(uint256 tokenId) internal virtual {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = Strings.toString(tokenId);
    }

    /**
     * @dev gets token URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Strings.toString(tokenId),
                    _headURI()
                )
            );
    }

    function mintToken(address receiverAddress, uint256 amount)
        public
        onlyOwner
        nonExceededSupplyCap(amount)
    {
        for (uint256 i = 0; i < amount; i++) {
            _tokenIds.increment();
            numMinted++;
            _safeMint(receiverAddress, _tokenIds.current());
            _setTokenURI(_tokenIds.current());
        }
    }
}
