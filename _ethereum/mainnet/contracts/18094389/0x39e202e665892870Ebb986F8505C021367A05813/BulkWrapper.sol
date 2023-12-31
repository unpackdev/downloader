//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./Controllable.sol";
import "./INameWrapper.sol";
import "./IBaseRegistrar.sol";

struct LabelResolver {
    string label;
    address resolver;
}

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
        LabelResolver[] calldata labelResolvers,
        address wrappedOwner,
        uint16 fuses
    ) external {
        for (uint256 i = 0; i < labelResolvers.length; i++) {
            uint256 tokenId = uint256(
                keccak256(bytes(labelResolvers[i].label))
            );

            // temporarily give ownership to BulkWrapper
            // requires prior approval for BulkWrapper to be set by the owner in the registrar
            registrar.transferFrom(wrappedOwner, address(this), tokenId); //TODO: do safe transfer?

            // wrapping gives ownernship to NameWrapper
            nameWrapper.wrapETH2LD(
                labelResolvers[i].label,
                wrappedOwner,
                fuses,
                labelResolvers[i].resolver
            );
        }
    }

    function setNameWrapper(INameWrapper _nameWrapper) external onlyController {
        nameWrapper = _nameWrapper;
    }

    function setRegistrar(IBaseRegistrar _registrar) external onlyController {
        registrar = _registrar;
    }
}
