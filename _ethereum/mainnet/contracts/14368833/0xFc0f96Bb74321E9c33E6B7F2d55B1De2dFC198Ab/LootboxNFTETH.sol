// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

contract LootboxNFTETH is Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    uint8 public MAX_PER_MINT = 5;
    address private _vaultAddress = 0xc29A9Dd4Bf84dDA6C416Bf1E3B8f936768018A2F;
    address private _devAddress = 0x75f5B78015D79B2f96BD6f24F77EF22ec829D7D0;
    bool public saleLive;

    struct Purchase {
        address user;
        uint256 tier;
    }

    mapping(uint256 => Purchase) public NftIdToTier;
    uint256 public purchaseCount;
    // settings for tier 1
    uint256 public currentTier = 1;
    uint256 public purchaseCountForTier;
    uint256 public maxMint = 50001;
    uint256 public maxMintForOne = 50000;
    uint256 public maxMintForThree = 49998;
    uint256 public price = 13700000000000000;
    uint256 public priceForThree = 41100000000000000;  

    uint256 public totalSupply;

    constructor() {}

    // ** - CORE - ** //

    function buyOne() external payable {
        require(saleLive, "SALE_CLOSED");
        require(price == msg.value, "INSUFFICIENT_ETH");
        require(maxMintForOne > purchaseCountForTier, "EXCEED_MAX_TIER_SUPPLY");
        purchaseCount++;
        NftIdToTier[purchaseCount] = Purchase({ user: _msgSender(), tier: currentTier});
        purchaseCountForTier++;
        totalSupply++;
    }

    function buyThree() external payable {
        require(saleLive, "SALE_CLOSED");
        require(priceForThree == msg.value, "INSUFFICIENT_ETH");
        require(maxMintForThree > purchaseCountForTier, "EXCEED_MAX_TIER_SUPPLY");
        // it's ugly, but gas efficient
        purchaseCount++;
        NftIdToTier[purchaseCount] = Purchase({ user: _msgSender(), tier: currentTier});
        purchaseCount++;
        NftIdToTier[purchaseCount] = Purchase({ user: _msgSender(), tier: currentTier});
        purchaseCount++;
        NftIdToTier[purchaseCount] = Purchase({ user: _msgSender(), tier: currentTier});
        purchaseCountForTier += 3;
        totalSupply += 3;
    }

    function buy(uint256 tokenQuantity) external payable {
        require(saleLive, "SALE_CLOSED");
        require(tokenQuantity < MAX_PER_MINT + 1, "EXCEED_MAX_PER_MINT");
        require(price * tokenQuantity == msg.value, "WRONG_ETH_AMOUNT");
        require(maxMint > purchaseCountForTier + tokenQuantity, "EXCEED_MAX_TIER_SUPPLY");
        for (uint256 i = 0; i < tokenQuantity; i++) {
            purchaseCount++;
            NftIdToTier[purchaseCount] = Purchase({ user: _msgSender(), tier: currentTier});
        }
        purchaseCountForTier += tokenQuantity;
        totalSupply += tokenQuantity;
    }

    // ** - ADMIN - ** //

    function withdrawFund() public {
        require(_msgSender() == owner() || _msgSender() == _vaultAddress, "NOT_ALLOWED");
        require(_vaultAddress != address(0), "TREASURY_NOT_SET");
        (bool sent, ) = _devAddress.call{value: address(this).balance * 10 / 100}("");
        require(sent, "FAILED_SENDING_FUNDS");
        (sent, ) = _vaultAddress.call{value: address(this).balance}("");
        require(sent, "FAILED_SENDING_FUNDS");
    }

    function withdraw(address _token) external nonReentrant {
        require(_msgSender() == owner() || _msgSender() == _vaultAddress, "NOT_ALLOWED");
        require(_vaultAddress != address(0), "TREASURY_NOT_SET");
        IERC20(_token).safeTransfer(
            _vaultAddress,
            IERC20(_token).balanceOf(address(this))
        );
    }

    function startNewTier(uint256 tier, uint256 maxMintForTier, uint256 priceForTier) external onlyOwner {
        currentTier = tier;
        maxMint = maxMintForTier + 1;
        maxMintForOne = maxMintForTier;
        maxMintForThree = maxMintForThree - 2;
        price = priceForTier;
        priceForThree = priceForTier * 3;
        purchaseCountForTier = 0;
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    // ** - SETTERS - ** //

    function setMaxPerMint(uint8 maxPerMint) external onlyOwner {
        MAX_PER_MINT = maxPerMint;
    }

    function setMaxMint(uint8 maxMint_) external onlyOwner {
        maxMint = maxMint_ + 1;
        maxMintForOne = maxMint_;
        maxMintForThree = maxMint_ - 2;
    }

    function setVaultAddress(address addr) external onlyOwner {
        _vaultAddress = addr;
    }

    function setDevAddress(address addr) external onlyOwner {
        _devAddress = addr;
    }

    // ** - MISC - ** //

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
        priceForThree = _price * 3;
    }
}
