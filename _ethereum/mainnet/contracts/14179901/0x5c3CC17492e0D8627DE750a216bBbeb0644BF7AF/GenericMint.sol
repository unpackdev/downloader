//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721BaseTokenURI.sol";

contract GenericMint is ERC721BaseTokenURI {
    enum State {
        Paused,
        Minting
    }

    uint256 private _maxPerWalletAndMint;
    uint256 private _maxSupply;
    State public state = State.Paused;
    uint256 public tokenCount = 0;
    uint256 private _tokenPrice;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        uint256 maxPerWalletAndMint,
        uint256 maxSupply,
        uint256 tokenPrice
    ) ERC721BaseTokenURI(name, symbol, baseTokenURI) {
        _maxPerWalletAndMint = maxPerWalletAndMint;
        _maxSupply = maxSupply;
        _tokenPrice = tokenPrice;
    }

    function setState(State _state) external onlyOwner {
        state = _state;
    }

    function mint(uint256 numberOfTokens) external payable {
        require(state == State.Minting, "The sale is paused.");
        require(
            numberOfTokens > 0 && numberOfTokens <= _maxPerWalletAndMint,
            "Invalid number of tokens."
        );
        require(
            tokenCount + numberOfTokens <= _maxSupply,
            "Not enough tokens left."
        );
        require(
            balanceOf(_msgSender()) + numberOfTokens <= _maxPerWalletAndMint,
            "Max per wallet exceeded!"
        );
        require(
            msg.value >= numberOfTokens * _tokenPrice,
            "Not enough ETH sent."
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            tokenCount++;
            uint256 tokenId = tokenCount;
            _mint(_msgSender(), tokenId);
        }
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdraw failed.");
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }
}
