pragma solidity ^0.8.6;

import "./Strings.sol";
import "./ERC721Tradable.sol";
import "./IERC721Base.sol";
import "./Withdrawable.sol";

contract ERC721Base is IERC721Base, ERC721Tradable, Withdrawable {
    using Strings for uint256;

    string internal baseURI;
    uint256 internal lastTokenId_;
    uint256 public maxTotalSupply;
    string public contractURI;

    event SetContractURI(string contractURI);
    event SetBaseURI(string baseUri);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        string memory _contractURI,
        address _proxyRegistry
    ) ERC721(_name, _symbol) {
        baseURI = _baseUri;
        contractURI = _contractURI;
        proxyRegistry = _proxyRegistry;
    }

    function setContractURI(string memory _contractURI)
        external
        override
        onlyOwner
    {
        contractURI = _contractURI;

        emit SetContractURI(_contractURI);
    }

    function setBaseURI(string memory _baseUri) external override onlyOwner {
        baseURI = _baseUri;

        emit SetBaseURI(_baseUri);
    }

    /**
     * @dev Get a `tokenURI`
     * @param `_tokenId` an id whose `tokenURI` will be returned
     * @return `tokenURI` string
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Base: URI query for nonexistent token"
        );

        // Concatenate the tokenID to the baseURI, token symbol and token id
        return
            string(
                abi.encodePacked(baseURI, "/", _tokenId.toString(), ".json")
            );
    }

    function totalSupply() external view override returns (uint256) {
        return lastTokenId_;
    }

    function _mintTokens(address _to, uint256 _amount) internal {
        uint256 _newLastTokenId = lastTokenId_ + _amount;

        for (
            uint256 _tokenId = lastTokenId_ + 1;
            _tokenId <= _newLastTokenId;
            _tokenId++
        ) {
            _mint(_to, _tokenId);
        }

        lastTokenId_ += _amount;
    }

    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyOwner {
        maxTotalSupply = _maxTotalSupply;
    }
}
