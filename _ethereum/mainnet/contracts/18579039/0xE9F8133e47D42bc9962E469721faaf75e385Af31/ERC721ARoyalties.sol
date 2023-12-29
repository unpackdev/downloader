// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721Enumerable.sol";
import "./Context.sol";
import "./Counters.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721A.sol";
import "./ERC2981PerTokenRoyalties.sol";

contract ERC721ARoyalties is
    Context,
    ERC721A,
    Ownable,
    ERC2981PerTokenRoyalties
{
    uint256 public immutable _maxSupply;
    string private _baseUri;

    /**
        @dev
        @param _maxSupply, if maxSupply==0; means unlimited
    */
    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        string memory baseUri,
        uint256 maxBatchSize,
        RoyaltyInfo memory royaltyInfo
    ) ERC721A(name, symbol, maxBatchSize) ERC2981PerTokenRoyalties() {
        //if maxSupply==0; means unlimited
        _maxSupply = maxSupply;
        _baseUri = baseUri;

        _setTokenRoyalty(royaltyInfo);
    }

    function mintTo(address to, uint256 quantity) internal {
        require(
            _maxSupply == 0 || totalSupply() + quantity <= _maxSupply,
            "Mint count exceed MAX_SUPPLY!"
        );
        _safeMint(to, quantity, "");
    }


    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setBaseURI(string memory newBaseUri) public onlyOwner {
        _baseUri = newBaseUri;
    }

    function getBaseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setTokenRoyalty(
        address recipient,
        uint256 royaltyAmount
    ) external onlyOwner {
        RoyaltyInfo memory royaltyInfo_ = RoyaltyInfo(recipient, royaltyAmount);
        _setTokenRoyalty(royaltyInfo_);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
