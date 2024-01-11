/*                                                                                ..-----..
                                                                           --`                 `--
                                                                       -`                           `-
                                                                    .`                                 `.
                                                                  -                   •                   -
                                                                -                                           -
                                                               ,                     / \                     `
                                                              ,                     /   \                     `
                                                             /                     /     \                     \
                                                            /                     /       \                     \
                                                            /                    /         \                    \
                                                           |                    /           \                    |
                                                           |    _--``````--.   /             \   .--``````--_    │
                                                           |  /               /-             -\               \  |
                                                            \/               /   \         /   \               \/
                                                            ||              /      \     /      \              ||
                                                            ||             /        \   /        \             ||
                                                             \\           /          \ /          \           //
                                                               |\_     _/                          \_      _/|
                                                                \                     •                     /
                                                                  .                                       ,`
                                                                    -                                   -`
                                                                      `-_                           _-`
                                                                          --_                   _--
                                                                               `"-----------"`

                                                                        ██████  ██████   ██████  ██      
                                                                       ██    ██ ██   ██ ██    ██ ██      
                                                                       ██    ██ ██████  ██    ██ ██      
                                                                       ██    ██ ██   ██ ██    ██ ██      
                                                                        ██████  ██████   ██████  ███████ 

                                                                          Utility token for AFTER

                                                                             http://after.fund

                                                                            security@after.fund
*/

pragma solidity ^0.8.0;

import "./ERC20.sol";

/**
 * @dev Establishes an initial supply of 100M OBOL to be sent to a gnosis
 * safe for crowdsales IDO distribution.
 */
contract AfterObol is ERC20 {
    constructor() ERC20("After", "OBOL") {
        /// Total Supply of 100,000,000
        _mint(0x0CA5cD5790695055F0a01F73A47160C35f9d3A46, 100000000 * 10 ** decimals());
    }
}