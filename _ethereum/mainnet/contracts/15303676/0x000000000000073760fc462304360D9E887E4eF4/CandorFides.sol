/*
                                                                     ███████ ██ ██████  ███████ ███████
                                                                     ██      ██ ██   ██ ██      ██
                                                                     █████   ██ ██   ██ █████   ███████
                                                                     ██      ██ ██   ██ ██           ██
                                                                     ██      ██ ██████  ███████ ███████

                                                                          Utility token for Candor

                                                                             http://candor.io

                                                                            security@candor.io
*/

pragma solidity ^0.8.0;

import "./ERC20.sol";

/**
 * @dev Establishes an initial supply of 100M OBOL to be sent to a gnosis
 * safe for crowdsales IDO distribution.
 */
contract CandorFIDES is ERC20 {
    constructor() ERC20("Fides", "FIDES") {
        /// Total Supply of 100,000,000
        _mint(0x4E6a17905cCa1681251C86Fe3B6A34BA61CB3E4c, 100000000 * 10 ** decimals());
    }
}