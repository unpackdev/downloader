// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "./IERC721.sol";
import "./Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => uint) public whitelist;
    uint256 public startAt;
    uint256 public endAt;
    uint256 public price;

    error MintNotStarted();
    error MintEnded();
    error ExceedsAllowedAmount();
    error NotEnoughFund();

    function beforeTransfer(
        address sender,
        uint amount,
        uint value
    ) public onlyOwner {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp < startAt) revert MintNotStarted();
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > endAt) revert MintEnded();
        if (whitelist[sender] < amount) revert ExceedsAllowedAmount();
        if (value < price * amount) revert NotEnoughFund();
        whitelist[sender] -= amount;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setPeriod(uint256 _startAt, uint256 _endAt) public onlyOwner {
        startAt = _startAt;
        endAt = _endAt;
    }

    function addWhiteList(
        address[] memory addresses,
        uint256 maxMint
    ) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = maxMint;
        }
    }
}
