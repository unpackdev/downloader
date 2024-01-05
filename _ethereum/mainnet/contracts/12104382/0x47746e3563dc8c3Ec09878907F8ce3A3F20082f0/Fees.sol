// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC165.sol";

abstract contract IRoyalities {
    function getBeneficiary() internal virtual view returns (address);
    // Value between 0 and 100 (0% to 100%).
    function getFee(uint256 tokenId) virtual internal view returns (uint256);
}

interface IRaribleFees is IERC165 {
    // Rarible emits this when minting, we don't bother.
    //event SecondarySaleFees(uint256 tokenId, address[] recipients, uint[] bps);

    function getFeeRecipients(uint256 id) external view returns (address payable[] memory);
    // 1000 = 10%
    function getFeeBps(uint256 id) external view returns (uint[] memory);
}

/**
 * @dev Implementation of royalties for 721s
 *
 */
interface IERC2981 is IERC165 {
    /*
     * ERC165 bytes to add to interface array - set in parent contract implementing this standard
     *
     * bytes4(keccak256('royaltyInfo()')) == 0x46e80720
     * bytes4 private constant _INTERFACE_ID_ERC721ROYALTIES = 0x46e80720;
     * _registerInterface(_INTERFACE_ID_ERC721ROYALTIES);
     */
    /**

    /**
     * @notice Called to return both the creator's address and the royalty percentage - this would be the main
     *   function called by marketplaces unless they specifically need just the royaltyAmount
     * @notice Percentage is calculated as a fixed point with a scaling factor of 10,000, such that 100% would be
     *   the value (1.000.000) where, 1.000.000/10.000 = 100. 1% would be the value 10.000/10.000 = 1
     */
    function royaltyInfo(uint256 _tokenId) external returns (address receiver, uint256 amount);
}

abstract contract HasFees is ERC165, IRaribleFees, IRoyalities, IERC2981 {
    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_RARIBLE_FEES = 0xb7799584;

    /*
     * ERC165 bytes to add to interface array - set in parent contract implementing this standard
     *
     * bytes4(keccak256('royaltyInfo()')) == 0x46e80720
     */
    bytes4 private constant _INTERFACE_ID_ERC721ROYALTIES = 0x46e80720;

    constructor() {
        _registerInterface(_INTERFACE_ID_RARIBLE_FEES);
        _registerInterface(_INTERFACE_ID_ERC721ROYALTIES);
    }

    function getFeeRecipients(uint256) public override view returns (address payable[] memory) {
        address payable[] memory recipients = new address payable[](1);
        recipients[0] = payable(address(this));
        return recipients;
    }
    function getFeeBps(uint256 id) public override view returns (uint[] memory) {
        uint[] memory fees = new uint[](1);
        fees[0] = getFee(id) * 100;
        return fees;
    }

    // Implements the current version of https://eips.ethereum.org/EIPS/eip-2981
    function royaltyInfo(uint256 _tokenId) external view override returns (address receiver, uint256 amount) {
        return (address(this), getFee(_tokenId) * 10000);
    }
}
