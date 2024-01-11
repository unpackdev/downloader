// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract UkraineChildren is ERC721, Pausable, Ownable {
    using Strings for uint256;

    string private baseUri =
        "https://ukraine.mypinata.cloud/ipfs/QmRNrfm5Z7DPN2JwHvgbGVFDrQMtVMn3zV3Bc6eS6BmpqD/";

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string public _baseTokenSuffix = ".json";

    constructor() ERC721("UkraineChildren", "UKC") {}

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function updateBaseUri(string memory uri) external onlyOwner {
        baseUri = uri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) public whenNotPaused onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function safeMintBulk(address to, uint256 count)
        public
        whenNotPaused
        onlyOwner
    {
        for (uint256 i = 0; i < count; ++i) {
            safeMint(to);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = baseUri;

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        tokenId.toString(),
                        _baseTokenSuffix
                    )
                )
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
