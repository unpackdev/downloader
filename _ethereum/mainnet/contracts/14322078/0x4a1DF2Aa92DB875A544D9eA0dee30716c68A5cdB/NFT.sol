// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract NFT is ERC721A, Ownable, Pausable {
    using Counters for Counters.Counter;

    Counters.Counter private _freeTokensCounter;
    uint256 public immutable totalNFTSupply;
    uint256 public immutable mintPrice;
    uint256 public immutable freeTokensAmount;
    uint256 private immutable _limitPerTransaction;
    string private _baseURIAddress;
    address private immutable _wallet;

    mapping(address => bool) private _freeNFTClaimed;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _mintPrice,
        uint256 _freeTokensAmount,
        uint256 limitPerTransaction_,
        address wallet_,
        string memory baseURIAddress_
    ) ERC721A(_name, _symbol) {
        totalNFTSupply = _totalSupply;
        mintPrice = _mintPrice;
        freeTokensAmount = _freeTokensAmount;
        _limitPerTransaction = limitPerTransaction_;
        _wallet = wallet_;
        _baseURIAddress = baseURIAddress_;
    }

    function changeBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIAddress = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIAddress;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getPrice(uint256 _count) public view returns (uint256) {
        if (canMintFreeToken()) {
            _count = _count - 1;
        }
        return _count * mintPrice;
    }

    function canMintFreeToken() public view returns (bool) {
        return !_freeNFTClaimed[_msgSender()] && _freeTokensCounter.current() < freeTokensAmount;
    }

    function getFreeTokensAmount() public view returns (uint256) {
        return _freeTokensCounter.current();
    }

    function buy(uint256 _count) public whenNotPaused payable {
        require(_count <= _limitPerTransaction, "You can`t buy more NFT");
        require((totalSupply() + _count) <= totalNFTSupply, "Total supply exceeded. Use less amount.");
        uint costWei = getPrice(_count);
        require(msg.value >= costWei, "Not enough ethers to buy");
        (bool sent, ) = payable(_wallet).call{value: address(this).balance}("");
        require(sent, 'Cant send money to owners wallet.');
        if (canMintFreeToken()) {
            _freeNFTClaimed[_msgSender()] = true;
            _freeTokensCounter.increment();
        }

        _safeMint(_msgSender(), _count);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}