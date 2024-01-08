// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";

import "./OwnableUpgradeable.sol";

contract PublicSaleUpgradeable is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    uint256 public constant genesisSaleEndTime = 1630393200;
    uint256 public constant publicSupply = 1400000e18; // 5%
    uint256 private _publicEthCapacity;
    uint256 private _publicRate;

    uint256 public publicSaleBoughtEth;
    uint256 public publicSaleSoldToken;

    bool private _publicSaleFinished;

    /// @notice The address of the GridZone token
    IERC20Upgradeable public zoneToken;

    event SoldOnPublicSale(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
    event PublicSaleFinished(uint256 boughtEth, uint256 soldToken);
    event PublicSaleRateChanged(uint256 newRate);
    event PublicSaleEthCapacityChanged(uint256 newRate, uint256 newEthCapacity);

    function initialize(
        address _ownerAddress,
        address _zoneToken
    ) public initializer {
        require(_ownerAddress != address(0), "Owner address is invalid");
        require(_zoneToken != address(0), "Owner address is invalid");

        __Ownable_init(_ownerAddress);
        zoneToken = IERC20Upgradeable(_zoneToken);
        _publicEthCapacity = 300e18; // 300 ETH
        _publicRate = publicSupply.mul(10).div(_publicEthCapacity).div(12); // 2/12 is for bonuses
    }

    modifier onlyEndUser {
        require(msg.sender == tx.origin, "ZONE: Only end-user");
        _;
    }

    function isCrowdsaleFinished() external view returns (bool) {
        if (_publicSaleFinished) return true;
        if (block.timestamp < genesisSaleEndTime) return true;
        return false;
    }

    function rate() public view returns (uint256) {
        return _publicRate;
    }

    function setRate(uint256 newRate) public onlyOwner {
        require(0 < newRate, "ZONE: The rate can't be 0.");
        _publicRate = newRate;
        emit PublicSaleRateChanged(_publicRate);
    }

    function getPublicSaleEthCapacity() external view returns(uint256) {
        return _publicEthCapacity;
    }

    function setPublicSaleEthCapacity(uint256 newEthCapacity) public onlyOwner {
        require(publicSaleBoughtEth < newEthCapacity, "ZONE: The capacity must be greater than the already bought amount in the public sale.");

        _publicRate = publicSupply.sub(publicSaleSoldToken).div(newEthCapacity.sub(publicSaleBoughtEth));
        _publicEthCapacity = newEthCapacity;
        emit PublicSaleEthCapacityChanged(_publicRate, _publicEthCapacity);
    }

    function finishCrowdsale() external onlyOwner {
        require(genesisSaleEndTime <= block.timestamp, "Public sale is not started");
        _finishPublicSale();
    }

    function _finishPublicSale() private {
        if (_publicSaleFinished) return;
        _publicSaleFinished = true;

        uint256 leftOver = zoneToken.balanceOf(address(this));
        if (leftOver > 0) {
            zoneToken.safeTransfer(owner(), leftOver);
        }
        emit PublicSaleFinished(publicSaleBoughtEth, publicSaleSoldToken);
    }

    function _sellOnPublicSale(address payable buyer, uint256 ethAmount) private {
        uint256 capacity = _publicEthCapacity.sub(publicSaleBoughtEth);
        uint256 _ethAmount = (ethAmount < capacity) ? ethAmount : capacity;
        uint256 refund = ethAmount - _ethAmount;
        require(0 < _ethAmount, "ZONE: The amount can't be 0.");

        uint256 amount = _ethAmount.mul(_publicRate);
        uint256 bonus = amount.div(10);   // when buying during Public sale, 10% bonus
        uint256 purchaseBonus = 0;

        if (_ethAmount >= 10e18) {
            // when buying for over 10eth, 10% bonus
            purchaseBonus = amount.div(10);
        }

        // total token amount
        amount = amount.add(bonus).add(purchaseBonus);

        publicSaleBoughtEth = publicSaleBoughtEth.add(_ethAmount);
        publicSaleSoldToken = publicSaleSoldToken.add(amount);
        require(publicSaleSoldToken <= publicSupply, "ZONE: Public supply is insufficient.");

        zoneToken.safeTransfer(buyer, amount);

        address payable ownerAddress = address(uint160(owner()));
        ownerAddress.transfer(_ethAmount);
        emit SoldOnPublicSale(buyer, _ethAmount, amount);

        if (0 < refund) {
            buyer.transfer(refund);
        }
        if (_publicEthCapacity <= publicSaleBoughtEth) {
            _finishPublicSale();
        }
    }

    // low level token purchase function
    function purchase() external payable onlyEndUser {
        require(genesisSaleEndTime <= block.timestamp, "Public sale is not started");
        require(_publicSaleFinished == false, "Public sale is already finished");
        require(msg.value >= 1e16, "The purchase minimum amount is 0.01 ETH");
        _sellOnPublicSale(_msgSender(), msg.value);
    }

    receive() external payable {
        require(false, "Use the purchase function to buy the ZONE token.");
    }

    uint256[44] private __gap;
}
