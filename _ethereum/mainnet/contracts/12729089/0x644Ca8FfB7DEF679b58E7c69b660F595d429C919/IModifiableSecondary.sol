// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/**
@dev add burn funtionality to ERC20
 */
interface IModifiableSecondary {
     function burnCMDFT(uint256, address) external returns (bool);
}
