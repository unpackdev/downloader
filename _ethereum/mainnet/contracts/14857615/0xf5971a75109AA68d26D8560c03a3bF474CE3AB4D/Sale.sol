//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./Counters.sol";

interface INFT {
    function mintSilver(address) external;

    function batchMintSilver(address[] memory) external;
}

contract Sale is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public sold;

    INFT public nft;

    mapping(address => Counters.Counter) private purchaseHistory;
    mapping(address => bool) public whitelist;

    uint256 private prePrice = 0.09 ether;
    uint256 private price = 0.12 ether;
    uint256 private soldLimit = 999;
    uint256 public preOpenTime = 1652443200; // 2022/05/13 21:00:00+09:00
    uint256 public openTime = 1652616000; // 2022/05/15 21:00:00+09:00

    constructor(address _nft) {
        nft = INFT(_nft);
    }

    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    modifier onlyWhitelist() {
        require(whitelist[_msgSender()], "only whitelist.");
        _;
    }

    function setWhitelist(address[] memory _addrs, bool _isWhitelist) external onlyOwner {
        for (uint256 i = 0; i < _addrs.length; i++) {
            whitelist[_addrs[i]] = _isWhitelist;
        }
    }

    modifier walletLimit(uint8 _amount) {
        for (uint8 i = 0; i < _amount; i++) {
            purchaseHistory[_msgSender()].increment();
        }
        require(purchaseHistory[_msgSender()].current() <= 2, "reached limit");
        _;
    }

    function setSetting(
        uint256 _prePrice,
        uint256 _price,
        uint256 _soldLimit,
        uint256 _preOpenTime,
        uint256 _openTime
    ) external onlyOwner {
        prePrice = _prePrice;
        price = _price;
        soldLimit = _soldLimit;
        preOpenTime = _preOpenTime;
        openTime = _openTime;
    }

    function buyPre(uint8 _amount) external payable onlyWhitelist walletLimit(_amount) {
        require(hasPreOpened(), "not opened");
        require(!hasOpened(), "closed");
        require(msg.value == prePrice * _amount, "invalid value");

        _mint(_amount);
    }

    function buy(uint8 _amount) external payable walletLimit(_amount) {
        require(hasOpened(), "not opened");
        require(msg.value == price * _amount, "invalid value");

        _mint(_amount);
    }

    function _mint(uint8 _amount) internal {
        require(_amount == 1 || _amount == 2, "invalid amount");
        require(sold.current() + _amount <= soldLimit, "sold out");

        sold.increment();
        if (_amount == 1) {
            nft.mintSilver(_msgSender());
        } else {
            sold.increment();

            address[] memory receivers = new address[](2);
            receivers[0] = _msgSender();
            receivers[1] = _msgSender();
            nft.batchMintSilver(receivers);
        }
    }

    function hasPreOpened() public view returns (bool) {
        return preOpenTime <= block.timestamp;
    }

    function hasOpened() public view returns (bool) {
        return openTime <= block.timestamp;
    }

    function remain() public view returns (uint256) {
        return soldLimit - sold.current();
    }
}
