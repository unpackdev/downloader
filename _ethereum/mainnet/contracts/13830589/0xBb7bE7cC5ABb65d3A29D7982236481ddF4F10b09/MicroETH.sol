// SPDX-License-Identifier: GPL-3.0-only

//                                   _______________   __
//      ____ ___  __ _____________  / ____/__  __/ /  / /
//     / __  __ \/ / ___/ ___/ __ \/ __/    / / / /__/ /
//    / / / / / / / /__/ /  / /_/ / /___   / / / ___  /
//   /_/ /_/ /_/_/\___/_/   \____/_____/  /_/ /_/  /_/
//

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./draft-ERC20Permit.sol";

contract MicroETH is ERC20, ERC20Permit {

    //
    // Definitions
    //

    uint256 public constant ONE_UETH_WEI = 1e12;   // 1 μETH or 0.000001 ETH or 1000 gwei or 1000000000000 wei or 10^12
    uint256 public constant ETH_CONVERSION = 1e6;  // Map Wei to μETH at this rate

    event Deposit(address indexed from, uint256 value);
    event Withdrawal(address indexed to, uint256 value);

    error InvalidAmount();

    //
    // External methods
    //

    constructor() ERC20("microETH", "uETH") ERC20Permit("microETH") {
        // ...
    }

    fallback() external payable {
        _deposit();
    }

    //
    // External ether conversion methods
    //

    function deposit() external payable {
        _deposit();
    }

    function _deposit() private {
        if (msg.value < ONE_UETH_WEI) {
            revert InvalidAmount();
        }

        // Mint tokens
        uint256 ueth = msg.value * ETH_CONVERSION;
        _mint(msg.sender, ueth);
        emit Deposit(msg.sender, ueth);
    }

    function withdraw(uint256 ueth) external {
        if (ueth < ETH_CONVERSION) {
            revert InvalidAmount();
        }

        // Burn tokens
        _burn(msg.sender, ueth);

        // Send ether
        uint256 value = ueth / ETH_CONVERSION;
        payable(msg.sender).transfer(value);
        emit Withdrawal(msg.sender, ueth);
    }

    // ...
}
