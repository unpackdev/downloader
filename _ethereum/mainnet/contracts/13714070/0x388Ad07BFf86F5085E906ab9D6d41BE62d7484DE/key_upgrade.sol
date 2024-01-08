// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Holder.sol";
import "./Ownable.sol";
import "./Ikaka721.sol";

contract KeyUpgrade is Ownable, ERC721Holder {
    bool public isOpen;
    uint public openTime;
    uint public interval;

    IKTA public krb;
    IKTA public kmk;

    event Upgrade(address indexed user, uint indexed tokenIdOld, uint indexed tokenIdNew);

    constructor(){
         openTime = 1638273600;
         kmk = IKTA(0xf004FFa5753Cc19F58c7483B6B33F1FA508C24f3);
         krb = IKTA(0x03489f499F8015E2a1229e1F32b0Dd8f92eC9b65);
         isOpen = true;
         interval = 2678400;
    }

    function setAddr(address kmk_, address krb_) public onlyOwner {
        kmk = IKTA(kmk_);
        krb = IKTA(krb_);
    }

    function setIsOpen(bool isOpen_) public onlyOwner {
        isOpen = isOpen_;
    }

    function setOpenTime(uint openTime_) public onlyOwner {
        openTime = openTime_;
    }

    function setInterval(uint interval_) public onlyOwner {
        interval = interval_;
    }

    function setApprovalForAll(address account_, bool approval_) public onlyOwner {
        krb.setApprovalForAll(account_, approval_);
        kmk.setApprovalForAll(account_, approval_);
    }
    // ------------- onlyOwner end

    modifier onlyOpen {
        require(isOpen, "Not open");
        _;
    }

    function inventory() public view returns (uint) {
        return krb.balanceOf(address(this));
    }

    function upgradeRabbit() public onlyOpen returns (uint) {
        require(inventory() > 0, "No inventory");
        require(block.timestamp >= openTime, "Not started yet");

        uint kmkId = kmk.tokenOfOwnerByIndex(_msgSender(), 0);
        kmk.safeTransferFrom(_msgSender(), address(this), kmkId);
        uint krbId = krb.tokenOfOwnerByIndex(address(this), 0);
        krb.safeTransferFrom(address(this), _msgSender(), krbId);

        if (inventory() == 0) {
            openTime = openTime + interval;
            while (true) {
                if (openTime > block.timestamp) {
                    break;
                }
                openTime = openTime + interval;
            }
        }

        emit Upgrade(_msgSender(), kmkId, krbId);
        return krbId;
    }
}