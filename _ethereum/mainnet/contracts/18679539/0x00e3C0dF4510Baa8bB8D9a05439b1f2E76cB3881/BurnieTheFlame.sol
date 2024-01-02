// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721ShipyardRedeemableMintable.sol";

contract BurnieTheFlame is ERC721ShipyardRedeemableMintable {
    /// @dev Store the token URI number for each token id.
    mapping(uint256 => uint256) internal tokenURINumbers;

    constructor() ERC721ShipyardRedeemableMintable("Burnie The Flame: OpenSea Redeemable Example", "BRNIE") {}

    /**
     * @notice Hook to set tokenURINumber on mint.
     */
    function _beforeTokenTransfers(address from, address, /* to */ uint256 startTokenId, uint256 quantity)
        internal
        virtual
    {
        // Set tokenURINumbers on mint.
        if (from == address(0)) {
            for (uint256 i = 0; i < quantity; i++) {
                // 60% chance of tokenURI 1
                // 30% chance of tokenURI 2
                // 10% chance of tokenURI 3
                uint256 randomness = (uint256(keccak256(abi.encode(block.prevrandao))) % 100) + 1;

                uint256 tokenURINumber = 1;
                if (randomness >= 60 && randomness < 90) {
                    tokenURINumber = 2;
                } else if (randomness >= 90) {
                    tokenURINumber = 3;
                }

                tokenURINumbers[startTokenId + i] = tokenURINumber;
            }
        }
    }

    /*
     * @notice Overrides the `tokenURI()` function to return baseURI + 1, 2, or 3
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        uint256 tokenURINumber = tokenURINumbers[tokenId];
        return string(abi.encodePacked(baseURI, _toString(tokenURINumber)));
    }
}
