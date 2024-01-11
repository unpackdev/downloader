// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Ownable.sol";

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

abstract contract TwoStepOwnable is Ownable {
    address internal _potentialOwner;

    error NewOwnerIsZeroAddress();
    error NotNextOwner();

    function transferOwnership(address newOwner_)
        public
        virtual
        override
        onlyOwner
    {
        if (newOwner_ == address(0)) {
            revert NewOwnerIsZeroAddress();
        }
        _potentialOwner = newOwner_;
    }

    function claimOwnership() public virtual {
        if (msg.sender != _potentialOwner) {
            revert NotNextOwner();
        }
        _transferOwnership(_potentialOwner);
        delete _potentialOwner;
    }

    function cancelOwnershipTransfer() public virtual onlyOwner {
        delete _potentialOwner;
    }
}
