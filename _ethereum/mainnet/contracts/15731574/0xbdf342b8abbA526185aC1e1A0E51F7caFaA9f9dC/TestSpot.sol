// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./Counters.sol";
import "./Address.sol";

interface ERC721Reserve {
    function mintReservedNFT(address to) external payable;
    function mintPrice() external returns (uint256);
}

contract TestPass {
    function getToken(address) public view returns (uint256) {}
}

contract TestSpot is Ownable {
    using Counters for Counters.Counter;
    ERC721Reserve mintContract;
    TestPass pass;

    bool public paused = true;
    uint256 public endTime;
    address private _couponOwner;
    address private _accountOwner;
    uint256 private _lastAirdropIndex;
    mapping(address => uint256) private _reservers;
    mapping(address => bool) private _airdropped;
    mapping(uint256 => address) private _owners;
    Counters.Counter private _activeReservations;
    Counters.Counter private _tokenId;

    event Airdrop(string message, address to);

    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct CouponData {
        uint256 expire;
    }

    constructor() {
        _couponOwner = owner();
        _accountOwner = owner();
    }

    // only for debug ?????
    function testLog() public view returns (uint256, uint256, uint256) {
        return (_tokenId.current(), _lastAirdropIndex, _tokenId.current());
    }

    function activeReservations() public view returns (uint256) {
        return _activeReservations.current();
    }

    function connectPass(address _pass) public onlyOwner {
        pass = TestPass(_pass);
    }

    function _hasPass(address to) private view returns (bool) {
        return pass.getToken(to) > 0;
    }

    function reserve(CouponData memory meta, Coupon memory coupon)
        public
        payable
    {
        require(paused == false, "Reserve paused");
        require(!_isReserveStopped(), "Reserve stopped");
        require(_hasPass(msg.sender), "No pass found");
        require(!isReserved(), "Already reserved");
        require(_isValidCoupon(msg.sender, meta, coupon), "Non whitelisted user");
        uint256 mintPrice = mintContract.mintPrice();
        require(msg.value >= mintPrice, "Not enough eth sent.");

        _activeReservations.increment();
        _tokenId.increment();
        uint256 newToken = _tokenId.current();
        _reservers[msg.sender] = newToken;
        _owners[newToken] = msg.sender;
    }

    function unReserve() public {
        require(!_isReserveStopped(), "Reserve stopped");
        _unReserve(msg.sender);
    }

    function unReserveUser(address to) public onlyOwner {
        _unReserve(to);
    }

    function _isReserveStopped() private view returns(bool) {
        return block.timestamp > endTime;
    }

    function _unReserve(address to) private {
        require(_isReservedUser(to), "No reservation found");
        require(!_isAirdropped(to), "Already airdropped");

        uint256 token = _reservers[to];
        _owners[token] = address(0);
        _reservers[to] = 0;
        _activeReservations.decrement();
        _refund(to);
    }

    function _refund(address to) private {
        uint256 mintPrice = mintContract.mintPrice();
        (bool success, ) = to.call{value: mintPrice}("");
        require(success, "Refund failed");
    }

    function isReserved() public view returns (bool) {
        return _isReservedUser(msg.sender);
    }

    function _isReservedUser(address to) private view returns (bool) {
        return _reservers[to] != 0;
    }

    function isAirdropped() public view returns (bool) {
        return _isAirdropped(msg.sender);
    }

    function _isAirdropped(address to) private view returns (bool) {
        return _airdropped[to];
    }

    function isValidUser(CouponData memory meta, Coupon memory coupon)
        public
        view
        returns (bool)
    {
        return _isValidCoupon(msg.sender, meta, coupon);
    }

    function _isValidCoupon(
        address to,
        CouponData memory meta,
        Coupon memory coupon
    ) private view returns (bool) {
        require(block.timestamp < meta.expire, "Coupon expired");

        bytes32 digest = keccak256(abi.encode(to, meta.expire));
        address signer = ECDSA.recover(digest, coupon.v, coupon.r, coupon.s);
        return (signer == _couponOwner);
    }

    function toString(bytes memory data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function airdrop(address to) public onlyOwner {
        require(!_isAirdropped(to), "Already public");
        require(_isReservedUser(to), "No reservation found");
        _airdropped[to] = true;
        mintContract.mintReservedNFT{value: 0}(to);
    }

    function _isAirdropActive() private view returns (bool) {
        uint256 buffer = (msg.sender == owner()) ? 0 : 432000; // 5 days
        return (endTime + buffer < block.timestamp);
    }

    function airdropBulk(uint256 limit) public {
        require(_isAirdropActive(), "Airdrop not active");
        uint256 count = limit < _tokenId.current() ? limit : _tokenId.current();
        uint256 i = _lastAirdropIndex + 1;
        _lastAirdropIndex = _lastAirdropIndex + count;
        for (;i <= _lastAirdropIndex; i++) {
            address to = _owners[i];
            if (to == address(0)) continue;
            if(_isAirdropped(to)) continue;
            _airdropped[to] = true;
            try mintContract.mintReservedNFT{value: 0}(to) {
                emit Airdrop("success", to);
            } catch {
                emit Airdrop("failed", to);
                revert(
                    string.concat("Failed at ", toString(abi.encodePacked(to)))
                );
            }
        }
    }

    function setEndTime(uint256 _time) public onlyOwner {
        require(_time > block.timestamp && _time > endTime, "Can't set older time");
        endTime = _time;
    }

    function setPaused(bool status) public onlyOwner {
        paused = status;
    }

    function setCouponOwner(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "CouponOwner: new owner is the zero address"
        );
        _couponOwner = newOwner;
    }

    function setAccountOwner(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "CouponOwner: new owner is the zero address"
        );
        _accountOwner = newOwner;
    }

    function setMintContract(ERC721Reserve mintContract_) external onlyOwner {
        mintContract = mintContract_;
    }

    function withdraw() public onlyOwner {
        require(endTime < block.timestamp, "not ready for withdraw");
        require(address(this).balance > 0, "balance is 0 ");
        Address.sendValue(payable(_accountOwner), address(this).balance);
    }
}