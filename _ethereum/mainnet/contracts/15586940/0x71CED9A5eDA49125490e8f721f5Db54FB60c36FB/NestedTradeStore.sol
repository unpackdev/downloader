// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

/**
 _  _  ____  ___  ____  ____  ____     ____  ____    __    ____  ____
( \( )( ___)/ __)(_  _)( ___)(  _ \   (_  _)(  _ \  /__\  (  _ \( ___)
 )  (  )__) \__ \  )(   )__)  )(_) )    )(   )   / /(__)\  )(_) ))__)
(_)\_)(____)(___/ (__) (____)(____/    (__) (_)\_)(__)(__)(____/(____)

**/

import "./IMoonbirds.sol";
import "./INestedTrade.sol";

/// @author Montana Wong, Fabrice Cheng
contract NestedTradeStore {
    IMoonbirds public moonbirds;
    /// @notice The ask for a given NFT, if one exists
    /// @dev Moonbird token ID => Ask
    mapping(uint256 => INestedTrade.Ask) public askForMoonbird;
    /// mapping of moonbird token id to the address that transferred it to the escrow from
    mapping(uint256 => address) public moonbirdTransferredFromOwner;

    bool public enforceDefaultRoyalties;
    uint256 public marketplaceFeeBps;
    address public marketplaceFeePayoutAddress;

    uint256 public totalSwap;
    uint256 public blockNumberSync;
    uint256 public blockNumberSyncCache;
}
