// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155.sol";
import "./AllowsImmutableProxy.sol";

/**
 *
 * ██████╗░██╗████████╗  ██████╗░██████╗░██╗███████╗███████╗░██████╗
 * ██╔══██╗██║╚══██╔══╝  ██╔══██╗██╔══██╗██║╚════██║██╔════╝██╔════╝
 * ██████╔╝██║░░░██║░░░  ██████╔╝██████╔╝██║░░███╔═╝█████╗░░╚█████╗░
 * ██╔═══╝░██║░░░██║░░░  ██╔═══╝░██╔══██╗██║██╔══╝░░██╔══╝░░░╚═══██╗
 * ██║░░░░░██║░░░██║░░░  ██║░░░░░██║░░██║██║███████╗███████╗██████╔╝
 * ╚═╝░░░░░╚═╝░░░╚═╝░░░  ╚═╝░░░░░╚═╝░░╚═╝╚═╝╚══════╝╚══════╝╚═════╝░
 *
 */

contract ERC1155Extended is
    ERC1155,
    AllowsImmutableProxy,
    Pausable,
    ReentrancyGuard
{
    string public name;
    string public symbol;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        address proxyAddress_
    ) ERC1155(uri_) AllowsImmutableProxy(proxyAddress_, true) {
        name = name_;
        symbol = symbol_;
    }

    function isApprovedForAll(address owner_, address operator_)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            isApprovedForProxy(owner_, operator_) ||
            super.isApprovedForAll(owner_, operator_);
    }
}
