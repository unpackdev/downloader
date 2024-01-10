// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

contract GoldenLootboxNFTETH is Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    mapping(uint256 => address) Purchases;
    mapping(address => uint256) PurchasesByAddress;
    uint256 public purchaseCount;

    mapping(address => bool) proxyToApproved; // proxy allowance for interaction with future contract
    uint8 public MAX_PER_MINT = 5;
    uint16 public MAX_MINT = 20001; // total mint + 1
    uint16 public MAX_MINT_FOR_ONE = 20000; // MAX_MINT - 1; precomputed for gas
    uint16 public MAX_MINT_FOR_THREE = 19998; // MAX_MINT - 2; precomputed for gas
    uint256 public PRICE = 17500000000000000; // BNB
    uint256 public PRICE_FOR_THREE = 52500000000000000; // 3 * PRICE, precomputed for gas
    address private _vaultAddress = 0xc29A9Dd4Bf84dDA6C416Bf1E3B8f936768018A2F;
    address private _dmAddress = 0x75f5B78015D79B2f96BD6f24F77EF22ec829D7D0;
    bool public saleLive;

    uint256 public totalSupply;

    constructor(){}

    // ** - CORE - ** //

    function buyOne() external payable {
        require(saleLive, "SALE_CLOSED");
        require(PRICE == msg.value, "INSUFFICIENT_ETH");
        require(MAX_MINT_FOR_ONE > purchaseCount, "EXCEED_MAX_MINT");
        purchaseCount++;
        Purchases[purchaseCount] = _msgSender();
        PurchasesByAddress[_msgSender()]++;
        totalSupply++;
    }

    function buyThree() external payable {
        require(saleLive, "SALE_CLOSED");
        require(PRICE_FOR_THREE == msg.value, "INSUFFICIENT_ETH");
        require(MAX_MINT_FOR_THREE > purchaseCount, "EXCEED_MAX_MINT");
        purchaseCount++;
        Purchases[purchaseCount] = _msgSender();
        purchaseCount++;
        Purchases[purchaseCount] = _msgSender();
        purchaseCount++;
        Purchases[purchaseCount] = _msgSender();
        PurchasesByAddress[_msgSender()] += 3;
        totalSupply += 3;
    }

    function buy(uint256 tokenQuantity) external payable {
        require(saleLive, "SALE_CLOSED");
        require(tokenQuantity < MAX_PER_MINT + 1, "EXCEED_MAX_PER_MINT");
        require(PRICE * tokenQuantity == msg.value, "WRONG_ETH_AMOUNT");
        require(MAX_MINT > purchaseCount + tokenQuantity, "EXCEED_MAX_MINT");
        for (uint256 i = 0; i < tokenQuantity; i++) {
            purchaseCount++;
            Purchases[purchaseCount] = _msgSender();
            PurchasesByAddress[_msgSender()]++;
        }
        totalSupply += tokenQuantity;
    }

    // ** - ADMIN - ** //

    function withdrawFund() public {
        require(_msgSender() == owner() || _msgSender() == _vaultAddress, "NOT_ALLOWED");
        require(_vaultAddress != address(0), "TREASURY_NOT_SET");
        (bool sent, ) = _vaultAddress.call{value: address(this).balance * 90 / 100}("");
        require(sent, "FAILED_SENDING_FUNDS");
        (sent, ) = _dmAddress.call{value: address(this).balance}("");
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

    function gift(address[] calldata receivers, uint256[] memory amounts)
        external
        onlyOwner
    {
        require(
            MAX_MINT > purchaseCount + receivers.length,
            "EXCEED_MAX_SUPPLY"
        );
        for (uint256 x = 0; x < receivers.length; x++) {
            require(receivers[x] != address(0), "MINT_TO_ZERO");
            require(
                MAX_MINT > purchaseCount + amounts[x],
                "EXCEED_MAX_SUPPLY"
            );
            for (uint256 i = 0; i < amounts[x]; i++) {
                Purchases[purchaseCount++] = _msgSender();
                PurchasesByAddress[receivers[x]]++;
            }
        }
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    // ** - SETTERS - ** //

    function setMaxPerMint(uint8 maxPerMint) external onlyOwner {
        MAX_PER_MINT = maxPerMint;
    }

    function setMaxMint(uint8 maxMint) external onlyOwner {
        MAX_MINT = maxMint + 1;
        MAX_MINT_FOR_ONE = maxMint;
        MAX_MINT_FOR_THREE = maxMint - 2;
    }

    function setVaultAddress(address addr) external onlyOwner {
        _vaultAddress = addr;
    }

    // ** - MISC - ** //

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
        PRICE_FOR_THREE = _price * 3;
    }
}
