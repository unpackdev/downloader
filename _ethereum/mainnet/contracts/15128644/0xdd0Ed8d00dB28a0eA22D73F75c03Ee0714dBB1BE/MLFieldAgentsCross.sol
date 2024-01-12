// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./MLFieldAgents.sol";

// @author: olive

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
///                                                                                                        ///
///                                                                                                        ///
///    ooo        ooooo ooooo              .o.                                            .                ///
///    `88.       .888' `888'             .888.                                         .o8                ///
///     888b     d'888   888             .8"888.      .oooooooo  .ooooo.  ooo. .oo.   .o888oo  .oooo.o     ///
///     8 Y88. .P  888   888            .8' `888.    888' `88b  d88' `88b `888P"Y88b    888   d88(  "8     ///
///     8  `888'   888   888           .88ooo8888.   888   888  888ooo888  888   888    888   `"Y88b.      ///
///     8    Y     888   888       o  .8'     `888.  `88bod8P'  888    .o  888   888    888 . o.  )88b     ///
///    o8o        o888o o888ooooood8 o88o     o8888o `8oooooo.  `Y8bod8P' o888o o888o   "888" 8""888P'     ///
///                                                  d"     YD                                             ///
///                                                  "Y88888P'                                             ///
///                                                                                                        ///
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract MLFieldAgentsCross is Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public PRICE = 0.275 ether;
    uint256 public LIMIT_PER_MINT = 30;
    uint256 public crossMinted = 0;
    MLFieldAgents public mlFieldAgents;

    bool private PAUSE = true;

    address public constant creatorAddress =
        0xB9a02542e41DBEDaec5cF18030a3519ee0120a51;

    event NewPriceEvent(uint256 price);

    modifier saleIsOpen() {
        require(!PAUSE, "MLFieldAgentsCross: Sales not open");
        _;
    }

    constructor(MLFieldAgents _MLFieldAgent) {
        mlFieldAgents = _MLFieldAgent;
    }

    function price(uint256 _count) public view returns (uint256) {
        return PRICE.mul(_count);
    }

    function mintCross(uint256 amount, address recipient) external payable saleIsOpen {
        require(
            msg.value >= price(amount),
            "MLFieldAgentsCross: Cross Mint Payment amount is not enough."
        );
        require(
            amount <= LIMIT_PER_MINT,
            "MLFieldAgentsCross: Mint amount exceed Max Per Limit."
        );
        address[] memory mintAddress = new address[](1);
        mintAddress[0] = recipient;
        uint256[] memory mintAmounts = new uint256[](1);
        mintAmounts[0] = amount;
        mlFieldAgents.giftMint(mintAddress, mintAmounts);
    }

    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
        emit NewPriceEvent(PRICE);
    }

    function setMLFieldAgents(MLFieldAgents _MLFieldAgent)
        external
        onlyOwner
    {
        mlFieldAgents = _MLFieldAgent;
    }

    function setPause(bool _pause) public onlyOwner {
        PAUSE = _pause;
    }

    function updateLimitPerMint(uint256 _limitpermint) public onlyOwner {
        LIMIT_PER_MINT = _limitpermint;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creatorAddress, balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}