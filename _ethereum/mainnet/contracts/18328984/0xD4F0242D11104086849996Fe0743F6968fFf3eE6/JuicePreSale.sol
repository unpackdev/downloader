// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./TransferHelper.sol";
import "./Ownable.sol";

contract JuicePreSale is Ownable {
    address public immutable USDT_ADDRESS;
    address public immutable USDC_ADDRESS;
    address public treasury;
    bool public onSale;

    mapping(address => uint256) public usdtInvestments;
    mapping(address => uint256) public usdcInvestments;

    event Invest(address indexed investor, address indexed token, uint256 amount);
    event ChangeSaleStatus(bool status);
    event SetTreasury(address treasury);
    event Withdraw(address token, uint256 amount);

    constructor(address _USDT_ADDRESS, address _USDC_ADDRESS) {
        USDT_ADDRESS = _USDT_ADDRESS;
        USDC_ADDRESS = _USDC_ADDRESS;
    }

    modifier onlyWhenOnSale() {
        require(onSale, "Sale is not active now");
        _;
    }

    function changeSaleStatus() external onlyOwner {
        onSale = !onSale;

        emit ChangeSaleStatus(onSale);
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;

        emit SetTreasury(_treasury);
    }

    function investUSDT(uint256 amount) external onlyWhenOnSale {
        address sender = msg.sender;
        if (treasury != address(0)) {
            TransferHelper.safeTransferFrom(USDT_ADDRESS, sender, treasury, amount);
        } else {
            TransferHelper.safeTransferFrom(USDT_ADDRESS, sender, address(this), amount);
        }

        usdtInvestments[sender] += amount;

        emit Invest(sender, USDT_ADDRESS, amount);
    }

    function investUSDC(uint256 amount) external onlyWhenOnSale {
        address sender = msg.sender;
        if (treasury != address(0)) {
            TransferHelper.safeTransferFrom(USDC_ADDRESS, sender, treasury, amount);
        } else {
            TransferHelper.safeTransferFrom(USDC_ADDRESS, sender, address(this), amount);
        }

        usdcInvestments[sender] += amount;

        emit Invest(sender, USDC_ADDRESS, amount);
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        TransferHelper.safeTransfer(token, msg.sender, amount);

        emit Withdraw(token, amount);
    }
}
