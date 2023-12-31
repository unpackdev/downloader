// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./Royalty.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./SignatureMintERC721.sol";

contract MintangibleERC721SignatureMint is
    ERC721URIStorage,
    Ownable,
    Royalty,
    SignatureMintERC721
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    /**
     * @dev Mints tokens according to the provided mint request.
     */
    function mintWithSignature(
        MintRequest calldata _req,
        bytes calldata _signature
    ) external payable virtual override returns (address signer) {
        require(_req.quantity == 1, "Quantiy must be 1");

        // Verify and process payload.
        signer = _processRequest(_req, _signature);

        // Extract request data
        address receiver = _req.to;
        uint256 tokenId = _tokenIds.current();
        string memory tokenURI = _req.uri;

        // Mint token
        _safeMint(receiver, tokenId);

        // Set metadata URI
        _setTokenURI(tokenId, tokenURI);

        // Set royalty info
        _setRoyaltyInfoForToken(tokenId, receiver, _req.royaltyBps);

        // Increment token ID
        _tokenIds.increment();

        emit TokensMintedWithSignature(signer, receiver, tokenId, _req);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721URIStorage) returns (bool) {
        return
            super._supportsRoyaltyInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns whether a given address is authorized to sign mint requests.
     */
    function _canSignMintRequest(
        address _signer
    ) internal view virtual override returns (bool) {
        return _signer == owner();
    }
}
