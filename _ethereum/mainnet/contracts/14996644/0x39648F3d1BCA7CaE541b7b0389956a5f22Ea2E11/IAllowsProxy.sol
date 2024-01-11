// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

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

interface IAllowsProxy {
    function isProxyActive() external view returns (bool);

    function proxyAddress() external view returns (address);

    function isApprovedForProxy(address owner_, address operator_)
        external
        view
        returns (bool);
}
