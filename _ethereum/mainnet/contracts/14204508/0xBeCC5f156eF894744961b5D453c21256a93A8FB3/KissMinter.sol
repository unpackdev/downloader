// SPDX-License-Identifier: UNLICENSED
// Copyright 2022 Arran Schlosberg
pragma solidity >=0.8.0 <0.9.0;

import "./IPublicMintable.sol";
import "./Ownable.sol";
import "./Address.sol";

/**
@notice Public-minting contract for The Kiss Precise NFT, forwarding payments
and refunds.
@dev This exists as a workaround to limits placed on addresses by the primary
contract because there are separate allocations for collectors/early-access that
shouldn't be counted towards the per-address limit here.
 */
contract KissMinter is Ownable {
    using Address for address payable;

    IPublicMintable immutable kiss;

    constructor(IPublicMintable kiss_) {
        kiss = kiss_;
    }

    event RefundReceived(uint256 value);
    event RefundForwarded(address to, uint256 value);

    receive() external payable {
        emit RefundReceived(msg.value);
    }

    function mint(uint256 n) external payable {
        uint256 max = maxPerAddress;
        checkAndIncrease(msg.sender, n, max);
        if (msg.sender != tx.origin) {
            checkAndIncrease(tx.origin, n, max);
        }

        kiss.mintPublic{value: msg.value}(msg.sender, 1);

        // ethier Seller contract will refund here so we need to propagate it
        // and always have a zero balance at the end. This will only happen if
        // there's a race condition for the final token.
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).sendValue(balance);
            emit RefundForwarded(msg.sender, balance);
        }
        assert(address(this).balance == 0);
    }

    uint256 public maxPerAddress = 1;

    function setMaxPerAddress(uint256 max) external onlyOwner {
        maxPerAddress = max;
    }

    mapping(address => uint256) public minted;

    function checkAndIncrease(
        address addr,
        uint256 n,
        uint256 max
    ) internal {
        uint256 postIncr = minted[addr] + n;
        require(postIncr <= max, "Address limit reached");
        minted[addr] = postIncr;
    }
}
