//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.15;

import "./ENS.sol";
import "./Resolver.sol";
import "./IBaseRegistrarImplement.sol";

contract ENSController {
    ENS public ens;
    IBaseRegistrarImplement internal registrar;
    Resolver internal resolver;

    /**
     * Constructor.
     * @param ensAddr The address of the ENS registry.
     */
    constructor(
        address ensAddr,
        address baseRegistrarAddr,
        address resolverAddr
    ) {
        require(address(ensAddr) != address(0), "Invalid address");
        require(address(baseRegistrarAddr) != address(0), "Invalid address");
        require(address(resolverAddr) != address(0), "Invalid address");

        ens = ENS(ensAddr);
        registrar = IBaseRegistrarImplement(baseRegistrarAddr);
        resolver = Resolver(resolverAddr);
    }
}
