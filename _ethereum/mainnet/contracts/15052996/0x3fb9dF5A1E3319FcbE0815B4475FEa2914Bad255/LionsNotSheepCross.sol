// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ILionsNotSheep.sol";

// @author: olive

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///                                                                                                                 ///
///                                                                                                                 ///
///    ██╗     ██╗ ██████╗ ███╗   ██╗███████╗███╗   ██╗ ██████╗ ████████╗███████╗██╗  ██╗███████╗███████╗██████╗    ///
///    ██║     ██║██╔═══██╗████╗  ██║██╔════╝████╗  ██║██╔═══██╗╚══██╔══╝██╔════╝██║  ██║██╔════╝██╔════╝██╔══██╗   ///
///    ██║     ██║██║   ██║██╔██╗ ██║███████╗██╔██╗ ██║██║   ██║   ██║   ███████╗███████║█████╗  █████╗  ██████╔╝   ///
///    ██║     ██║██║   ██║██║╚██╗██║╚════██║██║╚██╗██║██║   ██║   ██║   ╚════██║██╔══██║██╔══╝  ██╔══╝  ██╔═══╝    ///
///    ███████╗██║╚██████╔╝██║ ╚████║███████║██║ ╚████║╚██████╔╝   ██║   ███████║██║  ██║███████╗███████╗██║        ///
///    ╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═══╝ ╚═════╝    ╚═╝   ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝        ///
///                                                                                                                 ///
///                                                                                                                 ///
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract LionsNotSheepCross is Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public PRICE = 0.6 ether;
    uint256 public LIMIT_PER_MINT = 10;
    uint256 public crossMinted = 0;
    ILionsNotSheep public lionsNotSheep;

    bool private PAUSE = true;

    address public constant creator1Address =
        0x1be100a2DC375DcB76782f5f2645d0Eb3A99593b;
    address public constant creator2Address =
        0x8644743D64CAeeC03B5271D59b11BD0C8E957f7E;

    event NewPriceEvent(uint256 price);

    modifier saleIsOpen() {
        require(!PAUSE, "LionsNotSheepCross: Sales not open");
        _;
    }

    constructor(ILionsNotSheep _lionsNotSheep) {
        lionsNotSheep = _lionsNotSheep;
    }

    function price(uint256 _count) public view returns (uint256) {
        return PRICE.mul(_count);
    }

    function mintCross(uint256 amount, address recipient) external payable saleIsOpen {
        require(
            msg.value >= price(amount),
            "LionsNotSheepCross: Cross Mint Payment amount is not enough."
        );
        require(
            amount <= LIMIT_PER_MINT,
            "LionsNotSheepCross: Mint amount exceed Max Per Limit."
        );
        address[] memory mintAddress = new address[](1);
        mintAddress[0] = recipient;
        uint256[] memory mintAmounts = new uint256[](1);
        mintAmounts[0] = amount;
        lionsNotSheep.giftMint(mintAddress, mintAmounts);
    }

    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
        emit NewPriceEvent(PRICE);
    }

    function setLionsNotSheep(ILionsNotSheep _lionsNotSheep)
        external
        onlyOwner
    {
        lionsNotSheep = _lionsNotSheep;
    }

    function setPause(bool _pause) public onlyOwner {
        PAUSE = _pause;
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creator1Address, (balance * 85) / 100);
        _widthdraw(creator2Address, (balance * 15) / 100);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
}
