//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import "./IDotcManager.sol";

/**
 * @title Interface for DOTC contract (as part of the "SwarmX.eth Protocol")
 * @notice This interface is implemented by the Dotc contract to interact with the DotcManager.
 * ////////////////DISCLAIMER////////////////DISCLAIMER////////////////DISCLAIMER////////////////
 * Please read the Disclaimer featured on the SwarmX.eth website ("Terms") carefully before accessing,
 * interacting with, or using the SwarmX.eth Protocol software, consisting of the SwarmX.eth Protocol
 * technology stack (in particular its smart contracts) as well as any other SwarmX.eth technology such
 * as e.g., the launch kit for frontend operators (together the "SwarmX.eth Protocol Software").
 * By using any part of the SwarmX.eth Protocol you agree (1) to the Terms and acknowledge that you are
 * aware of the existing risk and knowingly accept it, (2) that you have read, understood and accept the
 * legal information and terms of service and privacy note presented in the Terms, and (3) that you are
 * neither a US person nor a person subject to international sanctions (in particular as imposed by the
 * European Union, Switzerland, the United Nations, as well as the USA). If you do not meet these
 * requirements, please refrain from using the SwarmX.eth Protocol.
 * ////////////////DISCLAIMER////////////////DISCLAIMER////////////////DISCLAIMER////////////////
 * @dev Defines the interface for the Dotc contract, outlining key functions and behaviors.
 * @author Swarm
 */
interface IDotc {
    /**
     * @notice Changes the manager of the Dotc contract.
     * @dev Allows updating the DotcManager address linked to the Dotc contract.
     * @param _manager The new manager's address to be set.
     * @return status Boolean indicating whether the manager was successfully changed.
     */
    function changeManager(IDotcManager _manager) external returns (bool status);
}
