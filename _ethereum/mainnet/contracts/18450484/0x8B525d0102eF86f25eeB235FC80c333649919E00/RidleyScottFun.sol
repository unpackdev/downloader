pragma solidity 0.8.4; 
//Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "./ERC20.sol";
import "./ERC20Burnable.sol";

// @custom:security-contact contact@metalong.io
contract RidleyScottFun is ERC20, ERC20Burnable {
  /**
 * @dev Kriptaz Blockchain
 * RSF Token: Introduction
 *
 * "RSF Token", abbreviated as "Ridley Scott Fun Token", represents a cryptocurrency token. The purpose of
 * issuing this token is to finance the shooting of the commercial of the Metaverse project called "Cosmiclands",
 * which is affiliated with the "Metalong" company of the famous British film and advertising director Ridley Scott.
 * 
 * What is an RSF Token?
 *
 * RSF Token is an abbreviation for "Ridley Scott Fun Token". This cryptocurrency was developed as part of a
 * project by the company "Metalong" on behalf of the world-famous film and advertising director Ridley Scott. It
 * aims to provide financial funding for shooting the "Cosmiclands" Metaverse project commercial, which we want
 * Ridley Scott to direct.
 */
  constructor() ERC20("Ridley Scott Fun", "RSF") {
    _mint(msg.sender, 21000000 * 10 ** 18);
  }
  /**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * Role of RSF Token
 *
 * RSF Token is used as a source of funding for the Cosmiclands Metaverse project. Cryptocurrency is used to
 * finance this project and complete the filming. At the same time, RSF Token brings the chance to bring Ridley
 * Scott fans and the crypto community together, contributing to creating a solid and fun community.
 * 
 * Technical details
 *
 * RSF Token is a blockchain-based cryptocurrency and is often created on popular blockchain networks such as
 * ETH20 and BEP20. Created using smart contracts and other blockchain technologies, RSF Token ensures
 * transaction security and transparency. Token holders can buy, sell and store their tokens.
 */
}

