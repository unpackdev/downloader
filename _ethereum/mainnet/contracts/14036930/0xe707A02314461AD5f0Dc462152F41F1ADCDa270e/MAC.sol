// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Ownable.sol";

/**
 * @title Mythology Apes Club V2(Flash Sale) contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */


contract MAC is Ownable {
    using SafeMath for uint256;

    uint256 public mintPrice;

    bool public isSale;

    address private communityFundWallet = 0x255dA57482B3Aa500F77280B0dfC43D1C3383f40;

    event BuyTicket(address indexed account, uint256 count);

    constructor() {
        mintPrice = 0.07777 ether;
    }

    /**
     * Set mint price for a Mythology Apes Club V2.
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /*
    * Set sale status
    */
    function setSaleStatus(bool _isSale) external onlyOwner {
        isSale = _isSale;
    }

    /**
    * Buy Mythology Apes Club V2 Tickets
    */
    function buyTicket(uint256 count)
        external
        payable
    {
        require(isSale, "Sale must be active to buy ticket");
        require(mintPrice.mul(count) <= msg.value, "Ether value sent is not correct");

        emit BuyTicket(_msgSender(), count);
    }

    function withdraw() external onlyOwner {
        payable(communityFundWallet).transfer(address(this).balance);
    }
}