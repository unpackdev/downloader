// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./AccessControlVFExtension.sol";
import "./RoyaltiesVFExtension.sol";
import "./TokenURIGeneratorVFExtension.sol";
import "./WithdrawVFExtension.sol";
import "./Ownable.sol";

abstract contract VFTokenAllExtensions is
    AccessControlVFExtension,
    RoyaltiesVFExtension,
    TokenURIGeneratorVFExtension,
    WithdrawVFExtension,
    Ownable
{
    constructor(
        address controlContractAddress,
        address royaltiesContractAddress,
        address renderingContractAddress
    )
        AccessControlVFExtension(controlContractAddress)
        RoyaltiesVFExtension(royaltiesContractAddress)
        TokenURIGeneratorVFExtension(renderingContractAddress)
    {}

    function setRoyaltiesContract(
        address royaltiesContractAddress
    ) external onlyRole(getAdminRole()) {
        super._setRoyaltiesContract(royaltiesContractAddress);
    }

    function setRenderingContract(
        address renderContractAddress
    ) external onlyRole(getAdminRole()) {
        super._setRenderingContract(renderContractAddress);
    }

    function withdrawMoney() external onlyRole(getAdminRole()) {
        super._withdrawMoney();
    }

    function withdrawToken(
        address contractAddress,
        address to,
        uint256 tokenId
    ) external onlyRole(getAdminRole()) {
        super._withdrawToken(contractAddress, to, tokenId);
    }
}
