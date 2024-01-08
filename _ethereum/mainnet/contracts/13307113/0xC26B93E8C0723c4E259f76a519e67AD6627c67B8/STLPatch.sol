// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";

contract STLPatch is ERC721, Ownable {
    uint256 private supply;

    bool private isFinished;

    bool private isTransferable;

    string private baseURI =
        "ipfs://QmRiyf4xisceAZGmFUjRWyG3FeBmSEMXfeLiuiLCFynRqJ";

    constructor() ERC721("STLPatch", "STLP") {}

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /**
     * @dev Sets the isFinished flag to true.
     */
    function setFinished() external onlyOwner {
        isFinished = true;
    }

    function setIsTransferable(bool _isTransferable) external onlyOwner {
        isTransferable = _isTransferable;
    }

    /**
     * @dev mints nfts and transfers them to the given addresses
     */
    function mint(address[] memory addresses) external onlyOwner {
        require(isFinished == false, "Can not mint tokens anymore");

        uint256 _supply = supply;

        for (uint256 i; i < addresses.length; i++) {
            _mint(addresses[i], _supply);
            _supply++;
        }

        supply = _supply;
    }

    /**
     * @dev Returns the base URI for the tokens API.
     */
    function baseTokenURI() external view returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns the total supply
     */
    function totalSupply() external view virtual returns (uint256) {
        return supply;
    }

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
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

        return baseURI;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(isTransferable == true, "This token is non-transferable");

        ERC721._transfer(from, to, tokenId);
    }
}
