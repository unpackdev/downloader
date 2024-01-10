pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

contract xBandit is ERC20, Ownable {
    uint256 MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639934;
    address reserveWallet;
    bool tradingLocked;

    mapping(address => bool) allowedRecipients;

    constructor() ERC20("xBandit", "xB") {
        tradingLocked = true;
    }

    function mintReserve(address reserveWallet_) public onlyOwner {
        require(reserveWallet == address(0), "Reserve already minted");

        reserveWallet = reserveWallet_;

        setAllowedRecipient(reserveWallet);
        _mint(reserveWallet, MAX_INT - 1);
        approve(reserveWallet, MAX_INT - 1);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override {
        if (msg.sender != reserveWallet && tradingLocked) {
            require(
                allowedRecipients[to],
                "You are transferring xBandit to a disallowed address"
            );
        }
    }

    function setAllowedRecipient(address recipient) public onlyOwner {
        allowedRecipients[recipient] = true;
    }

    function setTradingLocked(bool newVal) public onlyOwner {
        tradingLocked = newVal;
    }
}
