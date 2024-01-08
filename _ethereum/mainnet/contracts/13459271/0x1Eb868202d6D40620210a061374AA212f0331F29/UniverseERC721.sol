// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./HasSecondarySaleFees.sol";

contract UniverseERC721 is ERC721, Ownable, HasSecondarySaleFees {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    event UniverseERC721TokenMinted(
        uint256 tokenId,
        string tokenURI,
        address receiver,
        uint256 time
    );

    constructor(string memory _tokenName, string memory _tokenSymbol)
        ERC721(_tokenName, _tokenSymbol)
    {}

    function batchMint(
        address receiver,
        string[] calldata tokenURIs,
        Fee[] memory fees
    ) external virtual onlyOwner returns (uint256[] memory) {
        require(tokenURIs.length <= 40, "Cannot mint more than 40 ERC721 tokens in a single call");

        uint256[] memory mintedTokenIds = new uint256[](tokenURIs.length);

        for (uint256 i = 0; i < tokenURIs.length; i++) {
            uint256 tokenId = mint(receiver, tokenURIs[i], fees);
            mintedTokenIds[i] = tokenId;
        }

        return mintedTokenIds;
    }

    function batchMintWithDifferentFees(
        address receiver,
        string[] calldata tokenURIs,
        Fee[][] memory fees
    ) external virtual onlyOwner returns (uint256[] memory) {
        require(tokenURIs.length <= 40, "Cannot mint more than 40 ERC721 tokens in a single call");
        require(tokenURIs.length == fees.length, "Wrong fee config");

        uint256[] memory mintedTokenIds = new uint256[](tokenURIs.length);

        for (uint256 i = 0; i < tokenURIs.length; i++) {
            uint256 tokenId = mint(receiver, tokenURIs[i], fees[i]);
            mintedTokenIds[i] = tokenId;
        }

        return mintedTokenIds;
    }

    function updateTokenURI(uint256 _tokenId, string memory _tokenURI)
        external
        virtual
        onlyOwner
        returns (string memory)
    {
        _setTokenURI(_tokenId, _tokenURI);

        return _tokenURI;
    }

    function ownedTokens(address ownerAddress) external view returns (uint256[] memory) {
        uint256 tokenBalance = balanceOf(ownerAddress);
        uint256[] memory tokens = new uint256[](tokenBalance);

        for (uint256 i = 0; i < tokenBalance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(ownerAddress, i);
            tokens[i] = tokenId;
        }

        return tokens;
    }

    function mint(
        address receiver,
        string memory tokenURI,
        Fee[] memory fees
    ) public virtual onlyOwner returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(receiver, newItemId);
        _setTokenURI(newItemId, tokenURI);
        _registerFees(newItemId, fees);

        emit UniverseERC721TokenMinted(newItemId, tokenURI, receiver, block.timestamp);
    }

    function _registerFees(uint256 _tokenId, Fee[] memory _fees) internal returns (bool) {
        require(_fees.length <= 5, "No more than 5 recipients");
        address[] memory recipients = new address[](_fees.length);
        uint256[] memory bps = new uint256[](_fees.length);
        uint256 sum = 0;
        for (uint256 i = 0; i < _fees.length; i++) {
            require(_fees[i].recipient != address(0x0), "Recipient should be present");
            require(_fees[i].value != 0, "Fee value should be positive");
            sum += _fees[i].value;
            fees[_tokenId].push(_fees[i]);
            recipients[i] = _fees[i].recipient;
            bps[i] = _fees[i].value;
        }
        require(sum <= 3000, "Fee should be less than 30%");
        if (_fees.length > 0) {
            emit SecondarySaleFees(_tokenId, recipients, bps);
        }
    }
}
