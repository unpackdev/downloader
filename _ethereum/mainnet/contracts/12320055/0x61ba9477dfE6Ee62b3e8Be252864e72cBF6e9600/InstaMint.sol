pragma solidity ^0.8.3;
import "./ERC721Enumerable.sol";
import "./Counters.sol";

contract InstaMint is ERC721Enumerable {
    using Counters for Counters.Counter;

    Counters.Counter private _counter;
    mapping(string => bool) private hashes;
    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    constructor() ERC721("InstaMint", "NSTMNT") {}

    function contractURI() public pure returns (string memory) {
        return "https://instamint.xyz/api/contract-uri";
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function mintNSTMNT(
        address recipient,
        string memory imageIpfsHash,
        string memory metadataTokenURI
    ) public returns (uint256) {
        require(!hashes[imageIpfsHash], "Image has already been minted!");
        hashes[imageIpfsHash] = true;

        _counter.increment();
        uint256 newNSTMNTId = _counter.current();
        _mint(recipient, newNSTMNTId);
        _setTokenURI(newNSTMNTId, metadataTokenURI);

        return newNSTMNTId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    /*
        This function should only be called by frontend applications, not
        contract-to-contract calls. It is expensive to call.
    */
    function getTokensByOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory result = new uint256[](tokenCount);
        uint256 tokenArrayIndex;

        for (
            tokenArrayIndex = 0;
            tokenArrayIndex < tokenCount;
            tokenArrayIndex++
        ) {
            uint256 tokenId = tokenOfOwnerByIndex(_owner, tokenArrayIndex);
            result[tokenArrayIndex] = tokenId;
        }

        return result;
    }
}
