//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721BaseTokenURI.sol";

contract MintWithPresale is ERC721BaseTokenURI {
    enum State {
        Unstarted,
        Presale,
        Minting
    }

    mapping(address => bool) public _hasPresaleAccess;
    uint256 private _maxPerWalletAndMint;
    uint256 private _maxSupply;
    State public state = State.Unstarted;
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

    function bulkAddToPresale(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _hasPresaleAccess[addresses[i]] = true;
        }
    }

    function hasPresaleAccess(address addr) public view returns (bool) {
        return _hasPresaleAccess[addr];
    }

    function setHasPresaleAccess(address addr, bool hasAccess)
        external
        onlyOwner
    {
        _hasPresaleAccess[addr] = hasAccess;
    }

    function setState(State _state) external onlyOwner {
        state = _state;
    }

    function mint(uint256 numberOfTokens) external payable {
        require(state == State.Minting, "The public sale hasn't started.");
        require(
            numberOfTokens > 0 && numberOfTokens <= _maxPerWalletAndMint,
            "Invalid number of tokens."
        );
        _mintPrivate(numberOfTokens);
    }

    function mintPresale() external payable {
        require(state == State.Presale, "The presale hasn't started.");
        require(
            _hasPresaleAccess[_msgSender()],
            "You're not on the presale list."
        );
        delete _hasPresaleAccess[_msgSender()];
        _mintPrivate(1);
    }

    function _mintPrivate(uint256 numberOfTokens) private {
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
}
