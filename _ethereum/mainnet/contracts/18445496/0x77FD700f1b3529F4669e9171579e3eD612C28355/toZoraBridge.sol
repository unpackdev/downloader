// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20.sol";
import "./IZoraBridge.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo. 
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/

contract toZoraBridge is OwnableUpgradeable {
    address public constant ZORA_BRIDGE =
        0x1a0ad011913A150f69f6A19DF447A0CfD9551054;

    uint256[50] private _gap;

    function initialize() public initializer {
        __Ownable_init();
    }

    function withdrawTokens(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (token == address(0)) {
            payable(to).transfer(amount);
        } else {
            IERC20(token).transfer(to, amount);
        }
    }

    receive() external payable {
        IZoraBridge(ZORA_BRIDGE).depositTransaction{value: msg.value}(
            msg.sender,
            msg.value,
            100000,
            false,
            "0x"
        );
    }
}
