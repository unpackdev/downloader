// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// ERC721 from Sol-DAO/solbase, Packaged within NFTC Open Source Libraries.
// See: https://github.com/NFTCulture/nftc-contracts/blob/main/contracts/token/solbase/ERC721/ERC721.sol
import "./ERC721SolBaseBurnable.sol";
import "./ERC721SolBaseSupply.sol";

// ClosedSea by Vectorized
import "./OperatorFilterer.sol";

// OZ Libraries
import "./Ownable.sol";
import "./Strings.sol";

// NFTC Prerelease Contracts
import "./OwnableDeferral.sol";
import "./INFTCAdvanceMint.sol";

/**
 * @title  ERC721SolBase_NFTC
 * @author @NFTCulture
 * @dev SolBase/ERC721 plus NFTC-preferred extensions and add-ons.
 *  - ERC721SolBaseBurnable
 *  - Ownable
 *  - OperatorFilterer
 *  - INFTCAdvanceMint: The NFTC Advance Mint API, which includes Base URI Management
 *    and Query Helpers
 *
 * Using implementation and approach created by Vectorized for OperatorFilterer.
 * See: https://github.com/Vectorized/closedsea/blob/main/src/example/ExampleERC721A.sol
 *
 * @notice Be sure to add the following to your impl constructor:
 * >>  _registerForOperatorFiltering();
 * >>  operatorFilteringEnabled = true;
 */
abstract contract ERC721SolBase_NFTC is ERC721SolBaseBurnable, OperatorFilterer, OwnableDeferral, INFTCAdvanceMint {
    using Strings for uint256;

    uint64 public immutable MAX_SUPPLY;

    string public baseURI;

    bool public operatorFilteringEnabled;

    constructor(uint64 __maxSupply, string memory __baseURI) {
        MAX_SUPPLY = __maxSupply;
        baseURI = __baseURI;
    }

    function setContractURI(string memory __baseURI) external isOwner {
        baseURI = __baseURI;
    }

    function getContractURI() external view override returns (string memory) {
        return _getContractURI();
    }

    function _getContractURI() internal view returns (string memory) {
        return baseURI;
    }

    function maxSupply() external view override returns (uint256) {
        return _maxSupply();
    }

    function _maxSupply() internal view returns (uint256) {
        return MAX_SUPPLY;
    }

    function balanceOwnedBy(address tokenOwner) external view override returns (uint256) {
        return super.balanceOf(tokenOwner);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        ERC721SolBaseSupply.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public override(ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * Failsafe in case we need to turn operator filtering off.
     */
    function setOperatorFilteringEnabled(bool value) external isOwner {
        operatorFilteringEnabled = value;
    }

    /**
     * Failsafe in case we need to change what subscription we are using, for whatever reason.
     */
    function registerForOperatorFiltering(address subscription, bool subscribe) external isOwner {
        _registerForOperatorFiltering(subscription, subscribe);
    }

    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

    function _tokenFilename(uint256 tokenId) internal pure virtual returns (string memory) {
        return tokenId.toString();
    }
}
