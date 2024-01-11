// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.15;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeMath.sol";
import "./SafeERC20Upgradeable.sol";

contract Presale is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public usdc;

    uint256 public goalAmount;
    uint256 public soldAmount;

    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public salePrice;

    bool public openIdo;

    mapping(address => uint256) public bought;

    function initialize(address _usdc, uint256 _goalAmount) public initializer {
        __Ownable_init_unchained();
        openIdo = false;
        usdc = _usdc;
        goalAmount = _goalAmount;
    }

    function airdrop(address[] memory addresses, uint256[] memory amounts)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            bought[addresses[i]] = bought[addresses[i]] + amounts[i];
        }
    }

    function unairdrop(address[] memory addresses, uint256[] memory amounts)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            bought[addresses[i]] = bought[addresses[i]] - amounts[i];
        }
    }

    function setPresaleDetails(
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _salePrice
    ) external onlyOwner {
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        salePrice = _salePrice;
    }

    function setOpen(bool _open) external onlyOwner {
        openIdo = _open;
    }

    function getDetails()
        public
        view
        returns (
            uint256 minAllocation,
            uint256 maxAllocation,
            uint256 price
        )
    {
        return (minAmount, maxAmount, salePrice);
    }

    function purchase(uint256 _val) external returns (bool) {
        require(openIdo == true, "IDO is closed");
        soldAmount = soldAmount.add(_val);
        require(
            soldAmount <= goalAmount,
            "The amount entered exceeds IDO Goal"
        );
        uint256 _purchaseAmount = calculateSaleQuote(_val);
        uint256 _newAmount = bought[msg.sender] + _purchaseAmount;
        require(_newAmount <= maxAmount, "Above Presale allocation.");
        require(_newAmount >= minAmount, "Below Presale allocation.");

        IERC20Upgradeable(usdc).safeTransferFrom(
            msg.sender,
            address(this),
            _val
        );
        bought[msg.sender] = _newAmount;
        return true;
    }

    function calculateSaleQuote(uint256 paymentAmount_)
        public
        view
        returns (uint256)
    {
        return paymentAmount_.mul(salePrice).mul(1e8);
    }
}
