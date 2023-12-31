// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./IERC721.sol";

contract ConcreteJungle is Ownable, Pausable {
    IERC721 public immutable defiApes;

    IERC20 public immutable apeFi;

    uint256 public sellPrice = 100_000e18;

    uint256 public buyPrice = 500_000e18;

    event Buy(address indexed buyer, uint256[] tokenIds);
    event Sell(address indexed seller, uint256[] tokenIds);
    event BuyPriceUpdated(uint256 indexed buyPrice);
    event SellPriceUpdated(uint256 indexed sellprice);

    constructor(address defiApes_, address apeFi_) {
        defiApes = IERC721(defiApes_);
        apeFi = IERC20(apeFi_);
    }

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "EOA only");
        _;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function sellDefiApes(uint256[] memory tokenIds) public whenNotPaused onlyEOA {
        for (uint256 i = 0; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];
            require(defiApes.ownerOf(tokenId) == msg.sender, "not owner");

            defiApes.transferFrom(msg.sender, address(this), tokenId);

            unchecked {
                i++;
            }
        }

        uint256 amount = tokenIds.length * sellPrice;
        require(apeFi.balanceOf(address(this)) >= amount, "insufficient balance");

        apeFi.transfer(msg.sender, amount);

        emit Sell(msg.sender, tokenIds);
    }

    function buyDefiApes(uint256[] memory tokenIds) public whenNotPaused onlyEOA {
        for (uint256 i = 0; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];
            require(defiApes.ownerOf(tokenId) == address(this), "not owner");

            defiApes.transferFrom(address(this), msg.sender, tokenId);

            unchecked {
                i++;
            }
        }

        uint256 amount = tokenIds.length * buyPrice;
        require(apeFi.balanceOf(msg.sender) >= amount, "insufficient balance");

        apeFi.transferFrom(msg.sender, address(this), amount);

        emit Buy(msg.sender, tokenIds);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawDefiApes(uint256[] memory tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length;) {
            uint256 tokenId = tokenIds[i];
            require(defiApes.ownerOf(tokenId) == address(this), "not owner");

            defiApes.transferFrom(address(this), owner(), tokenId);

            unchecked {
                i++;
            }
        }
    }

    function withdrawApeFi(uint256 amount) external onlyOwner {
        require(apeFi.balanceOf(address(this)) >= amount, "insufficient balance");

        apeFi.transfer(owner(), amount);
    }

    function adjustSellPrice(uint256 newSellPrice) external onlyOwner {
        require(newSellPrice > 0, "invalid price");

        sellPrice = newSellPrice;

        emit SellPriceUpdated(newSellPrice);
    }

    function adjustBuyPrice(uint256 newBuyPrice) external onlyOwner {
        require(newBuyPrice > 0, "invalid price");

        buyPrice = newBuyPrice;

        emit BuyPriceUpdated(newBuyPrice);
    }
}
