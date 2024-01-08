pragma solidity ^0.6.12;

/*

Website: AnyFarms.com
Telegram: https://t.me/ANYFARMS

ANYFARMS is the first ever cross-chain farming protocol which enables auto-compound yield farming across the BSC, MATIC, FANTOM and AVAX chains!
We focused on these chains due to their fast conformation speeds and low gas fees that emancipate small players but offer deep liquidity pools needed for the whales.
This allows investors to diversify across chains which are in different stages of growth and adoptions to achieve their perfect risk tolerance in a market that has seen greater appreciations than any other market in centuries.

*/

import "./ERC20.sol";

contract AnyFarms is ERC20 {
    constructor() public ERC20("ANYFARMS.com", "https://t.me/ANYFARMS") {
    }
}




