//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.12;

import "./IAccessControl.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC2981.sol";

interface IPikoZooNFT is IAccessControl, IERC2981, IERC721, IERC721Metadata {
    event Giveaway(address toAddress, uint256 tokenId);

    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
    function totalSupply() external view returns (uint256);
    function giveawayCount() external view returns (uint256);
    function maxGiveaway() external view returns (uint256);
    function isVerifier(address verifier_) external view returns (bool);
    function setVerifier(address verifier_) external;
    function revokeVerifier(address verifier_) external;
    function setTokenURI(string memory tokenURI_) external;
    function setPreSaleRoot(bytes32 root_) external;
    function preSaleRoot() external view returns(bytes32);
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;
    function setFundRecipient(address fundRecipient_) external;
    function fundRecipient() external view returns (address);
    function tokenCount() external view returns (uint256);
    function activate(uint256 totalSupply_, uint8 maxGiveaway_, address fundRecipient_, address royaltyRecipient_) external;
    function mint(uint256 tokenId, uint256 salt, bytes memory sig) external payable;
    function mintBatch(uint256[] memory tokenIds, uint256 salt, bytes memory sig) external payable;
    function giveaway(address toAddress, uint256 tokenId) external;
}