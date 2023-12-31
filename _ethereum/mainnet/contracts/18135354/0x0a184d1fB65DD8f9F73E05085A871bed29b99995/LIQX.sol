/*
LIQUIDITY MIXER

Blockchains are by default transparent – it’s part of the whole deal. Nodes need to be able to validate transactions and the system can only be “trustless” insofar as everyone can independently verify the same data. 
This is a revolutionary idea in terms of establishing relationships between counterparties and settling transactions, but presents an obvious problem if the blockchain’s built-in pseudo-anonymity is ever cracked.

The Liquidity Mixer project is dedicated to reshaping the landscape of privacy and liquidity within the blockchain and cryptocurrency space. 

Website:            https://liquiditymixer.com
Telegram:           https://t.me/LiquidityMixer
Twitter:            https://twitter.com/LiquidityMixer
Whitepaper:         https://liquiditymixer.com/wp-content/uploads/2023/09/Whitepaper.pdf

Further readings and technicalis:
Vitalik's Brain:    https://www.coindesk.com/consensus-magazine/2023/09/12/vitalik-buterin-wants-a-better-crypto-mixer/
Technicalities:     https://deliverypdf.ssrn.com/delivery.php?ID=264110083004126097003109125018108126046015033002001029031097074103031029090092012091027055001103025062017092108016098073119106044000006035020006115001028003028116070001018095067087113080022098089004125014027108005082076070066108100101126093125074074004&EXT=pdf&INDEX=TRUE
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract LiquidityMixer is ERC20 {
    constructor() ERC20("Liquidity Mixer", "LIQX") {
        _mint(msg.sender, 1_000_000_000 * 10**18);
    }
}