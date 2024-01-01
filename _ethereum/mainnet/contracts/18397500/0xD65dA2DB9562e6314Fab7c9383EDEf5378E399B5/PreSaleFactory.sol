// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./PreSale.sol";

contract PreSaleFactory is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => address[]) public userPreSales;

    address[] public preSales;

    address public serviceReceiver;
    uint256 public serviceFee;

    event PreSaleCreated(address preSaleAddress);

    constructor(address _serviceReceiver, uint256 _serviceFee) {
        serviceReceiver = _serviceReceiver;
        serviceFee = _serviceFee;
    }

    function setServiceReceiver(address _serviceReceiver) external onlyOwner {
        serviceReceiver = _serviceReceiver;
    }

    function setServiceFee(uint256 _serviceFee) external onlyOwner {
        serviceFee = _serviceFee;
    }

    function createPreSale(
        uint256 _rate,
        address _saleToken,
        uint256 _totalTokensforSale,
        uint256 _minBuyLimit,
        uint256 _maxBuyLimit,
        uint256 _preSaleStartTime,
        uint256 _preSaleEndTime,
        address[] memory _tokenWL,
        uint256[] memory _tokenPrices
    ) payable external {
        require(msg.value >= serviceFee, "Service fee not met!");
        require(_rate != 0, "Invalid Native Currency rate!");

        PreSale _preSale = new PreSale(
            _rate,
            _saleToken,
            _totalTokensforSale,
            _minBuyLimit,
            _maxBuyLimit,
            _preSaleStartTime,
            _preSaleEndTime,
            _tokenWL,
            _tokenPrices,
            serviceReceiver
        );

        IERC20 _token = IERC20(_saleToken);
        _token.safeTransferFrom(
            msg.sender,
            address(_preSale),
            _totalTokensforSale
        );

        _preSale.transferOwnership(address(msg.sender));

        preSales.push(address(_preSale));
        userPreSales[msg.sender].push(address(_preSale));

        emit PreSaleCreated(address(_preSale));

        payable(serviceReceiver).transfer(msg.value);
    }

    function withdraw(address token, uint256 amt) public onlyOwner {
        IERC20(token).safeTransfer(msg.sender, amt);
    }

    function withdrawAll(address token) public onlyOwner {
        uint256 amt = IERC20(token).balanceOf(address(this));
        withdraw(token, amt);
    }

    function withdrawCurrency(uint256 amt) public onlyOwner {
        payable(msg.sender).transfer(amt);
    }
}