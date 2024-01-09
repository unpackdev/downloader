// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma abicoder v2;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./ownable.sol";
import "./interfaces.sol";


contract Helpers is Ownable {
    using SafeERC20 for IERC20;

    struct ActionVariables {
        bytes32 key;
        AccountInterface dsa;
        string[] connectors;
        bytes[] callData;
        bool success;
    }

    struct Spell {
        string connector;
        bytes data;
    }

    struct TokenInfo {
        address sourceToken;
        address targetToken;
        uint256 amount;
    }
    
    struct Position {
        TokenInfo[] supply;
        TokenInfo[] withdraw;
    }

    address constant internal nativeToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
     
    /**
     * @dev Return chain Id
     */
    function getChainID() internal view returns (uint256) {
        return block.chainid;
    }

    function sendSourceTokens(TokenInfo[] memory tokens, address dsa) internal onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i].sourceToken);
            uint256 amount = tokens[i].amount;
            if (address(token) == nativeToken) {
                Address.sendValue(payable(dsa), amount);
            } else {
                token.safeTransfer(dsa, amount);
            }
        }
    }

    function sendTargetTokens(TokenInfo[] memory tokens, address dsa) internal onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i].targetToken);
            uint256 amount = tokens[i].amount;
            if (address(token) == nativeToken) {
                Address.sendValue(payable(dsa), amount);
            } else {
                token.safeTransfer(dsa, amount);
            }
        }
    }

    function cast(AccountInterface dsa, Spell[] memory spells) internal onlyOwner returns (bool success) {
        string[] memory connectors = new string[](spells.length);
        bytes[] memory callData = new bytes[](spells.length);
        for (uint256 i = 0; i < spells.length; i++) {
            connectors[i] = spells[i].connector;
            callData[i] = spells[i].data;
        }
        (success, ) = address(dsa).call(
            abi.encodeWithSignature(
                "cast(string[],bytes[],address)",
                connectors,
                callData,
                address(this)
            )
        );
    }
}