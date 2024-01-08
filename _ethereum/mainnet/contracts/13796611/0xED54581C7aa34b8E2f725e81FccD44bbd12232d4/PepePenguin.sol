// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LPBasic.sol";

contract PepePenguin is LPBasic {

		constructor(string memory name, string memory symbol, uint256 supply) LPBasic(name, symbol, supply) { }

}

/* Welcome To PepePenguin!
 *
 * -------------------------------------------------------------------------------------------------------------------
 *
 * PepePenguin ($PP)
 * PepePenguin.io
 * twitter.com/PPepe_Penguin
 * t.me/PepePenguinTG
 *
 * -------------------------------------------------------------------------------------------------------------------
 *
 * PepePenguin ($PP) is a fully decentralized fair launch meme token that has been optimized for price appreciation.
 * PP collects a liquidity pool (LP) fee on each transaction that scales based on the LP size. Instead of immediately
 * depositing the LP fee back into the LP, PP optimizes the rate of deposit to increase or decrease the token's
 * volatility (speed at which the price moves) depending on the token's current value. In simple terms, PP increases
 * the speed of price appreciation in price zones of optimal price appreciation and decreases the speed of price
 * deprecation in prices zone prone to consolidation. This is achieved by the contract holding the LP fee as a token
 * reserve and slowly depositing the LP pair fee into the LP in appreciating price zones and rapidly depositing during
 * price deprecation zones. In this way PP LP dynamics help drive the market price to a steady increase followed with
 * consolidation, boosting the next increase and damping any price reductions. Further, PP has re-engineered the fair
 * launch model to allow for an optimal token wallet distribution. PP limits the maximum purchase to 1,000,000 tokens
 * per wallet and the contract will collect any amount over the maximum adding to the token LP reserves. In addition,
 * the LP of the contract has been locked forever.
 *
 * -------------------------------------------------------------------------------------------------------------------
 *
 * Tokenomics breakdown
 *
 * Max Token Supply: 100,000,000
 *
 * IF LP < 5 ETH:
 * 	LP TAX : 15%
 * 	Max LP push is 250k token
 * 	Max Wallet is 1M tokens - amount over max wallet is taxed 100% and sent to LP
 * 	Standard transfers are not limited
 * 	50% of pool size is max purchase size
 * 	1.5% Dev Fee on every Transaction
 *
 * IF 5ETH < LP < 20ETH:
 * 	LP TAX : 5%
 * 	IF contract holds more tokens than LP, push greater of: 500,000 tokens or 5% pool balance
 * 	ELSE push lesser of: 250,000 tokens or 1% pool balance
 * 	Max Wallet is 1M tokens - amount over max wallet is taxed 100% and sent to LP
 * 	Standard transfers are not limited
 * 	50% of pool size is max purchase size
 * 	1.5% Dev Fee on every Transaction
 *
 * IF 20ETH < LP < 100ETH
 * 	LP TAX : 2.5%
 * 	Max LP push size of 1% pool balance
 * 	Max Wallet is permanently disabled
 *  Max purchase size is permanently disabled
 * 	Standard transfers are not limited
 * 	1.5% Dev Fee on every Transaction
 *
 * IF 100ETH < LP
 *	NO LP TAX
 * 	LP tax still held by contract push to LP size of 1% pool balance
 * 	Standard transfers are not limited
 * 	1.5% Dev Fee on every Transaction
 *
 */