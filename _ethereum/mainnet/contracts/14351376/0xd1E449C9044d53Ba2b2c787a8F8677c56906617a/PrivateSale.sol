// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

import "./Counters.sol";
import "./Ownable.sol";

contract PrivateSale is Ownable {
    using Counters for Counters.Counter;

    uint256 public privateSaleStartTimestamp;
    uint256 public privateSaleExpiryTimestamp;

    Counters.Counter internal lockedQtyForPrivateSale;

    mapping(address => uint256) public privateSaleMinterToAllowedMintQty;
    mapping(address => bool) public addressToHasMintedOnPrivateSale;

    constructor(uint256 _privSaleStart, uint256 _privSaleExpiry) {
        privateSaleStartTimestamp = _privSaleStart;
        privateSaleExpiryTimestamp = _privSaleExpiry;
    }

    modifier eligibleForWhitelistMint() {
        require(
            _eligibleForWhitelistMint(),
            "PrivateSale: not whitelisted or have minted"
        );
        _;
    }

    modifier privateSaleStart() {
        require(_privateSaleStart(), "PrivateSale has not started");
        _;
    }

    function setPrivateSaleStart(uint256 _privSaleStart) public onlyOwner {
        privateSaleStartTimestamp = _privSaleStart;
    }

    function setPrivateSaleExpiry(uint256 _privateSaleExpiry) public onlyOwner {
        privateSaleExpiryTimestamp = _privateSaleExpiry;
    }

    function whitelistAddressForPrivateSale(address _address, uint256 qtyToMint)
        public
        onlyOwner
    {
        require(!_privateSaleExpire(), "PrivateSale already expired");
        privateSaleMinterToAllowedMintQty[_address] = qtyToMint;
        for (uint256 i = 0; i < qtyToMint; i++) {
            lockedQtyForPrivateSale.increment();
        }
    }

    function unwhitelistAddressForPrivateSale(address _address)
        public
        onlyOwner
    {
        uint256 previousQty = privateSaleMinterToAllowedMintQty[_address];
        for (uint256 i = 0; i < previousQty; i++) {
            lockedQtyForPrivateSale.decrement();
        }
        privateSaleMinterToAllowedMintQty[_address] = 0;
    }

    function _eligibleForWhitelistMint() public view returns (bool) {
        return
            !addressToHasMintedOnPrivateSale[msg.sender] &&
            privateSaleMinterToAllowedMintQty[msg.sender] > 0;
    }

    function _privateSaleStart() public view returns (bool) {
        return
            privateSaleStartTimestamp > 0 &&
            block.timestamp >= privateSaleStartTimestamp;
    }

    function _privateSaleExpire() public view returns (bool) {
        return
            privateSaleExpiryTimestamp > 0 &&
            block.timestamp > privateSaleExpiryTimestamp;
    }
}
