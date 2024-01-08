// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IVNFT.sol";

contract vHighExchanger is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 private vHigh;
    IERC20 private high;
    IVNFT private voucher;
    uint256 public exhangeValue;
    address private voucherCollector;

    event swap(address indexed user, uint256 value);
    event swap(address indexed user, uint256 indexed id, uint256 value);
    event swapAll(address indexed user, uint256[] indexed ids, uint256 value);

    constructor(address vHigh_, address high_, address voucher_) {
        vHigh = IERC20(vHigh_);
        high = IERC20(high_);
        voucher = IVNFT(voucher_);
        voucherCollector = msg.sender;
    }

    function updateCollector(address address_) external onlyOwner {
        voucherCollector = address_;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function claimHighToken() external onlyOwner {
        _pause();
        uint256 balance = high.balanceOf(address(this));
        high.transfer(msg.sender, balance);
    }

    function claimvHighToken() external onlyOwner {
        uint256 balance = vHigh.balanceOf(address(this));
        vHigh.transfer(msg.sender, balance);
    }

    function swapToken(uint256 amount_) external nonReentrant whenNotPaused {
        require(amount_ > 0, 'Invalid amount');
        require(vHigh.balanceOf(msg.sender) >= amount_, 'vHigh not enough');
        require(high.balanceOf(address(this)) >= amount_, 'liquidity not enough');
        vHigh.transferFrom(msg.sender, address(this), amount_);
        high.transfer(msg.sender, amount_);
        exhangeValue = exhangeValue.add(amount_);
        emit swap(msg.sender, amount_);
    }

    function swapVoucher(uint256 tokenId) external nonReentrant whenNotPaused {
        require(tokenId > 0, 'Invalid amount');
        require(high.balanceOf(address(this)) >= voucher.unitsInToken(tokenId), 'liquidity not enough');
        voucher.transferFrom(msg.sender, voucherCollector, tokenId);
        uint256 value = voucher.unitsInToken(tokenId);
        if(value > 0) {
            high.transfer(msg.sender, value);
            exhangeValue = exhangeValue.add(value);
        }
        emit swap(msg.sender, tokenId, value);
    }

    function swapAllVoucher(uint256[] calldata tokenIds_) external nonReentrant whenNotPaused {
        require(tokenIds_.length > 0, "empty tokenIds");
        uint256 balance = high.balanceOf(address(this));
        uint256 value;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 temp = voucher.unitsInToken(tokenIds_[i]);
            if(balance >= value.add(temp)) {
                voucher.transferFrom(msg.sender, voucherCollector, tokenIds_[i]);
                value = value.add(temp);
            }
        }
        if(value > 0) {
            high.transfer(msg.sender, value);
            exhangeValue = exhangeValue.add(value);
        }
        emit swapAll(msg.sender, tokenIds_, value);
    }


}