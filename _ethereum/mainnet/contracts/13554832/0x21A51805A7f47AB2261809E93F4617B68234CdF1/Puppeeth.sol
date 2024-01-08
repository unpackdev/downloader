//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

//                                     _   _
//   _ __  _   _ _ __  _ __   ___  ___| |_| |__
//  | '_ \| | | | '_ \| '_ \ / _ \/ _ \ __| '_ \
//  | |_) | |_| | |_) | |_) |  __/  __/ |_| | | |
//  | .__/ \__,_| .__/| .__/ \___|\___|\__|_| |_|
//  |_|         |_|   |_|
//
//  web3 development by Decentralized Software Systems, LLC
//  Original artwork by Olivia Porter
//  https://puppeeth.art

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

/// @title puppeeth
/// @author Decentralized Software Systems, LLC
contract Puppeeth is ERC721, Ownable {
    // Counter.
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Base URI.
    string private _baseTokenURI;

    // Price.
    uint256 constant private TOKEN_PRICE = .015 ether;

    // Invalid token error.
    error InvalidTokenID();

    // Invalid payment error.
    error InvalidPayment();

    /// @notice Reserves some tokens for the authors.
    constructor() ERC721("puppeeth", "PUPPEETH") {
        uint16[11] memory reserved = [
            11111,
            22222,
            33333,
            44444,
            55555,
            11423,
            31314,
            31315,
            42142,
            11521,
            51111
        ];
        for (uint8 i = 0; i < reserved.length; i++) {
            _tokenIds.increment();
            _safeMint(_msgSender(), reserved[i]);
        }
    }

    /// @notice Public mint.
    function mint(uint16 tokenId) external payable {
        if (msg.value != TOKEN_PRICE)
            revert InvalidPayment();

        if (!validId(tokenId))
            revert InvalidTokenID();

        _tokenIds.increment();
        _safeMint(_msgSender(), tokenId);
    }

    /// @notice Returns token URI.
    /// @dev See {IERC721Metadata-tokenURI}.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    /// @notice Check if ID is valid.
    function validId(uint16 tokenId) public pure returns (bool) {
        return tokenId >= 11111 && tokenId <= 55555
            && tokenId % 10 > 0 && tokenId % 10 <= 5
            && tokenId % 100 > 10 && tokenId % 100 <= 55
            && tokenId % 1000 > 100 && tokenId % 1000 <= 555
            && tokenId % 10000 > 1000 && tokenId % 10000 <= 5555;
    }

    /// @notice Withdrawl accrued balance.
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /// @notice Get total number of tokens.
    function totalTokens() external view returns (uint256) {
      return _tokenIds.current();
    }

    /// @notice Indicate if token is minted.
    function tokenMinted(uint16 tokenId) external view returns (bool) {
      return _exists(tokenId);
    }

    /// @notice Set base token URI.
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /// @notice Returns base token URI.
    /// @dev See {ERC721-_baseURI}.
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}
