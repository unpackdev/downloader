//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./Controllable.sol";
import "./INameWrapper.sol";
import "./IBaseRegistrar.sol";

contract BulkWrapper is Controllable {
    INameWrapper nameWrapper;
    IBaseRegistrar registrar;

    constructor(
        INameWrapper nameWrapperAddress,
        IBaseRegistrar registrarAddress
    ) {
        nameWrapper = nameWrapperAddress;
        registrar = registrarAddress;

        // give NameWrapper approval over BulkWrapper
        registrar.setApprovalForAll(address(nameWrapper), true);
    }

    function bulkWrapETH2LD(
        string[] calldata labels,
        address wrappedOwner,
        uint16 fuses,
        address resolver
    ) external {
        for (uint256 i = 0; i < labels.length; i++) {
            uint256 tokenId = uint256(keccak256(bytes(labels[i])));

            // temporarily give ownership to BulkWrapper
            // requires prior approval for BulkWrapper to be set by the owner in the registrar
            registrar.transferFrom(wrappedOwner, address(this), tokenId); //TODO: do safe transfer?

            // wrapping gives ownernship to NameWrapper
            nameWrapper.wrapETH2LD(labels[i], wrappedOwner, fuses, resolver);
        }
    }

    function setNameWrapper(INameWrapper _nameWrapper) external onlyController {
        nameWrapper = _nameWrapper;
    }

    function setRegistrar(IBaseRegistrar _registrar) external onlyController {
        registrar = _registrar;
    }
}
