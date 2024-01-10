// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

/*            _       _           _              
 *  _ __ ___ (_)_ __ (_)_ __ ___ (_)_______ _ __ 
 * | '_ ` _ \| | '_ \| | '_ ` _ \| |_  / _ \ '__|
 * | | | | | | | | | | | | | | | | |/ /  __/ |   
 * |_| |_| |_|_|_| |_|_|_| |_| |_|_/___\___|_|   
 * 
 * @title IERC721WithTotalSupply
 * @author minimizer <me@minimizer.art>; https://minimizer.art/
 * 
 * Simple interface which extends IERC721, adds totalSupply()
 * as a subset of IERC721Enumerable.
 */
interface IERC721WithTotalSupply is IERC721 {
    function totalSupply() external view returns (uint256);
}
