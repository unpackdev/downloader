/*
                     ..........
                 .(MMMMMMMMMMMMMMa,.
              .(MMMMMMMMMMMMMMMMMMMMN,
            .+MMMMMMMMMMMMMMMMMMMMMMMMN,
           .MMMMMMMMMMMMMMMMMMMMMMMMMMMMb
          .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMh
         .MMMMMMMF TMMMMMMMMMMMMF`   ?MMMMb
         MMMMMMMa, .+MMMMMMMMMM#      ,MMMM,
        .MMMMMMMMMgMMMMMMMMMMMMN,     .MMMM]
        ,MMMMMMMMMMMMMMMMMMMMMB^ .J.JMMMMMMF
       .MMMMMMMMMMMMMMMMMMM#=  .JMMMMMMMMMMF
     .JMMMMMMMMMMMMMMMMMB=   .(MMMMMMMMMMMM>
     MMMMMMMMMMMMMMM#"!    .JMMMMMMMMMMMMMF
    ,MMMMMMMMMMMB"`      .dMMMMMM9`7MMMMM#
     .""""""!         .(MMMMMMMMMMaMMMMM@
                   ..MMMMMMMMMMMMMMMMMM3
                .&MMMMMMMMMMMMMMMMMMM"
                 ?YMMMMMMMMMMMMMM#"`
                     _7"""""""!
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MarketBase.sol";

/**
 * @title A request market for NFTs on Recomet.
 * @notice The Recomet Request Marketplace is a contract for requesters to request and trade NFTs.
 * It supports buying and selling by request.
 */
contract RequestMarketV1 is MarketBase {
    /**
     * @notice Set immutable variables for the implementation contract.
     * @dev Using immutable instead of constants allows us to use different values on testnet.
     * @param name The user readable name of the signing domain.
     * @param version The current major version of the signing domain.
     * @param trustedForwarder The Recomet TrustedForwarder address.
     */
    constructor(
        string memory name,
        string memory version,
        address trustedForwarder
    ) MarketBase(name, version, trustedForwarder) {}
}
