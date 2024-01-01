// contract Grok AI Meme Token
// SPDX-License-Identifier: MIT

/*

Elon Musk's AI Startup XAI is building an awesome new AI ChatGPT called Grok. 
This meme token is to celebrate boundary pushing visionary entrepreneurs, cutting edge tech and the future of AI with internet culture.

Grok AI Meme Token is fully based on the ERC20 standard and is fully compatible with all ERC20 wallets.

Join the Grok AI Meme movement, where AI meets internet culture.

Tax: 1% for development & meme content creators for this community.

Ownership Renouned. Please call the owner() function to verify the owner address is the dead address 0.

Website: www.grokaimemetoken.tech

*/


pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./Ownable.sol";

contract GrokAIMemeToken is ERC20, Ownable {
    // making these public so that its transparent and accessible. Anyone can verify the contract on etherscan
    address public coinGrowthMarketingWallet;
    uint256 public taxRate = 1;  // 1% tax

    constructor(uint256 initialSupply, address _devMarketingWallet)
    ERC20("Grok AI Meme Token", "GROKMEME") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply * 10 ** decimals());
        coinGrowthMarketingWallet = _devMarketingWallet;
    }

    function _update(address sender, address recipient, uint256 amount) internal override {
        uint256 tax = amount * taxRate / 100;
        uint256 amountAfterTax = amount - tax;

        super._update(sender, coinGrowthMarketingWallet, tax);
        super._update(sender, recipient, amountAfterTax);
    }

    function setDevMarketingWallet(address _newWallet) public onlyOwner {
        coinGrowthMarketingWallet = _newWallet;
    }

    // airdrop tokens to initial community members, CEX listings, dev & marketing wallets.
    function airdropTokens(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
    require(recipients.length == amounts.length, "Recipients and amounts length mismatch");

    for (uint256 i = 0; i < recipients.length; i++) {
        super._update(msg.sender, recipients[i], amounts[i]);
    }
}
}

// Thats it!! no honeypot, no dodgy code, no rug pull, no scams, 
// just a meme token for the future of AI and internet culture for the community.