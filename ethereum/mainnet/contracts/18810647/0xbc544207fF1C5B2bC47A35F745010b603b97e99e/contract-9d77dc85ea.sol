// SPDX-License-Identifier: MIT
/**
 *             _____ 
 *      /\    |_   _|
 *     /  \     | |  
 *    / /\ \    | |  
 *   / ____\ \ _| |_ 
 *  |_/     \_\__ __|
 *                   
 *                                    
 * 
 * AI PIN : Your Gateway to Endless Creativity and Simplified Solutions in Generative AI
 *
 * Homepage: https://ai-pin.io 
 * Twitter: https://twitter.com/aipin_io
 * Telegram: https://t.me/aipinio 
 * 
 * Total Supply: 100 Million Tokens
*/
/**
   * @title ContractName
   * @dev ContractDescription
   * @custom:dev-run-script file_path
   */
pragma solidity ^0.8.23;

import "./ERC20.sol";
import "./ERC20Permit.sol";
import "./ERC20FlashMint.sol";
import "./Ownable.sol";

/// @custom:security-contact hello@ai-pin.io
contract AIPIN is ERC20, ERC20Permit, ERC20FlashMint, Ownable {
    constructor(address initialOwner)
        ERC20("AI PIN", "AI")
        ERC20Permit("AI PIN")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}
