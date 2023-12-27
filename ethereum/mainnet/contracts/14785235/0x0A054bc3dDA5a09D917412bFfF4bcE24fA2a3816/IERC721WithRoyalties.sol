// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC2981Royalties.sol";
import "./IRaribleSecondarySales.sol";
import "./IFoundationSecondarySales.sol";

/// @dev This is a contract used for royalties on various platforms
/// @author Simon Fremaux (@dievardump)
interface IERC721WithRoyalties is
    IERC2981Royalties,
    IRaribleSecondarySales,
    IFoundationSecondarySales
{

}
