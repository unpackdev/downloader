// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./OwnableUpgradeable.sol";
import "./IERC20.sol";

contract BMIBridge is OwnableUpgradeable {
    address public constant BMI_TOKEN = address(0x725C263e32c72dDC3A19bEa12C5a0479a81eE688);

    event StakedBMI(uint256 amountBMI, address indexed sender);
    event BMIWithdrawn(uint256 amountBMI, address indexed recipient);

    function __BMIBridge_init() external initializer {
        __Ownable_init();
    }

    function stake(uint256 _amountBMI) external onlyOwner {
        require(_amountBMI > 0, "BMIBridge: can't stake 0 tokens");

        IERC20(BMI_TOKEN).transferFrom(_msgSender(), address(this), _amountBMI);

        emit StakedBMI(_amountBMI, _msgSender());
    }

    function withdraw(uint256 _amountBMI) external onlyOwner {
        require(
            IERC20(BMI_TOKEN).balanceOf(address(this)) >= _amountBMI,
            "BMIBridge: !enough BMI tokens"
        );

        IERC20(BMI_TOKEN).transfer(_msgSender(), _amountBMI);

        emit BMIWithdrawn(_amountBMI, _msgSender());
    }

    function locked() external view returns (uint256) {
        return IERC20(BMI_TOKEN).balanceOf(address(this));
    }
}