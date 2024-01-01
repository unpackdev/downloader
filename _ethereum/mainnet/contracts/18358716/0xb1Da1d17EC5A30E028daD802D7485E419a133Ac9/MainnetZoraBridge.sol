// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20.sol";
import "./IWeth.sol";
import "./IERC721.sol";
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

contract MainnetZoraBridge is OwnableUpgradeable {
    address public constant OPTIMISM_PORTAL = 0x1a0ad011913A150f69f6A19DF447A0CfD9551054;
    address public constant ZORA_DESTENATION = 0xB475Cf9D2BBe4EdE2dbA6a4874245A7bfc026deb;

    uint256[50] private _gap;

    function _contractTokenBalance(address token) private returns (uint256) {
        return IWeth(token).balanceOf(address(this));
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function callZoraSc(address maker) public payable {
        bytes memory mintAtZoraData = abi.encodeWithSelector(
            bytes4(keccak256("mintAtZora(address)")),
            maker
        );

        IZoraBridge(OPTIMISM_PORTAL).depositTransaction(
            ZORA_DESTENATION,
            msg.value,
            200000,
            false,
            mintAtZoraData
        );

    }

    receive() external payable {
        callZoraSc(msg.sender);
    }
}
