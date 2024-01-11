// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

import "./TokenSale.sol";

contract DGNZ is ERC721A, Ownable, TokenSale {
    uint256 public constant MAX_SUPPLY = 10001;

    uint256 private constant BATCH_SIZE = 20;

    address private immutable _treasuryWallet;

    string private _baseTokenURI;

    constructor(address wallet) ERC721A("DGNZ", "DGNZ") {
        _treasuryWallet = wallet;
        _mintTokens(msg.sender, 1);
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _guardMint(
        uint256,
        address,
        uint256 quantity
    ) internal view virtual override {
        unchecked {
            require(
                _totalMinted() + quantity <= MAX_SUPPLY,
                "Exceeds max supply"
            );
        }
    }

    function _mintTokens(address to, uint256 quantity)
        internal
        virtual
        override
    {
        uint256 startTokenId = _totalMinted();
        uint256 batchCount = quantity / BATCH_SIZE;
        _mint(to, quantity);
        for (uint256 i = 1; i < batchCount; ++i) {
            uint256 index = startTokenId + i * BATCH_SIZE;
            _initializeOwnershipAt(index);
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = _treasuryWallet.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
}
