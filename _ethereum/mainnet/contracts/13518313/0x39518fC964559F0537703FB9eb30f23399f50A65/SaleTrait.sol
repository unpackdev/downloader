// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";

contract SaleTrait is Ownable {
    using SafeMath for uint256;

    bool public closeSale = false;

    uint256 public totalPresaleMinted = 0;
    uint256 public totalPublicMinted = 0;
    uint256 public totalReserveMinted = 0;
    uint256 public maxSupply = 6969;
    uint256 public maxReserve = 169;
    uint256 public presaleCapped = 690;
    uint256 public presalePrice;
    uint256 public publicSalePrice;

    struct SaleConfig {
        uint256 beginBlock;
        uint256 endBlock;
    }

    SaleConfig public presale;
    SaleConfig public publicSale;

    function updatePresaleConfig(SaleConfig memory _presale)
        external
        onlyOwner
    {
        presale = _presale;
    }

    function updatePublicSaleConfig(SaleConfig memory _publicSale)
        external
        onlyOwner
    {
        publicSale = _publicSale;
    }

    function updatePublicSalePrice(uint256 _price) external onlyOwner {
        publicSalePrice = _price;
    }

    function updatePresalePrice(uint256 _price) external onlyOwner {
        presalePrice = _price;
    }

    function setCloseSale() external onlyOwner {
        closeSale = true;
    }

    function unsetCloseSale() external onlyOwner {
        closeSale = false;
    }

    function updateReserve(uint256 reserve) external onlyOwner {
        maxReserve = reserve;
    }

    function updatePresaleCap(uint256 newPresaleCap) external onlyOwner {
        presaleCapped = newPresaleCap;
    }

    function presaleSoldOut() external view returns (bool) {
        return totalPresaleMinted == presaleCapped;
    }

    function publicSaleSoldOut() external view returns (bool) {
        uint256 supplyWithoutReserve = maxSupply - maxReserve;
        uint256 mintedWithoutReserve = totalPublicMinted + totalPresaleMinted;
        return supplyWithoutReserve == mintedWithoutReserve;
    }
}
