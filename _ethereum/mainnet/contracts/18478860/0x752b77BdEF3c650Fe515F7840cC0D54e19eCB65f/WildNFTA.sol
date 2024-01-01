// SPDX-License-Identifier: GPL-3.0
// LICENSE
// This is a modified version of the original code from the
// NounsToken.sol— an implementation of OpenZeppelin's ERC-721:
// https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/NounsToken.sol
// The original code is licensed under the GPL-3.0 license
// Thank you to the Nouns team for the inspiration and code!

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./Math.sol";

import "./IERC721A.sol";
import "./ERC721A.sol";

import "./ERC2981.sol";

import "./IERC165.sol";

import "./PaymentSplitter.sol";

import "./WildNFT.sol";

interface IWildNFTA is IERC721A {
    event TokenCreated(uint256 indexed tokenId, address mintedTo);
    event TokenBurned(uint256 indexed tokenId);
    event MetadataUpdate(uint256 indexed tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    function burn(uint256 tokenId) external;

    function setMinter(address minter) external;

    function setBaseURI(string memory _newBaseURI) external;

    function maxSupply() external view returns (uint256);

    error MaxSupplyExceeded();
}

abstract contract WildNFTA is
    IWildNFTA,
    Ownable,
    ERC721A,
    ERC2981,
    PaymentSplitter
{
    // An address who has permissions to mint qf tokens
    address public minter;

    // Mapping of operators to whether they are approved or not
    mapping(address => bool) public authorized;

    // Mapping of addresses flagged for denying token interactions
    mapping(address => bool) public blockList;
    uint256 public maxSupply;
    string public baseURI;

    error TokenDoesNotExist(uint256 tokenId);

    modifier tokenExists(uint256 _tokenId) {
        if (!_exists(_tokenId)) revert TokenDoesNotExist(_tokenId);
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address _minter,
        uint256 _maxSupply,
        string memory _baseURI,
        address[] memory _payees,
        uint256[] memory _shares,
        uint96 _feeNumerator
    ) PaymentSplitter(_payees, _shares) ERC721A(name_, symbol_) {
        minter = _minter;
        maxSupply = _maxSupply;
        baseURI = _baseURI;
        _setDefaultRoyalty(address(this), _feeNumerator);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, "Sender is not the minter");
        _;
    }

    /**
     * @notice updates the deny list
     * @param flaggedOperator the address to be added to the deny list
     * @param status whether the address is to be added or removed from the deny list
     */
    function updateDenyList(
        address flaggedOperator,
        bool status
    ) public onlyOwner {
        _updateDenyList(flaggedOperator, status);
    }

    /*
     * @notice Override isApprovedForAll
     * @param owner The owner of the Nouns
     * @param operator The operator to check if approved
     */
    function isApprovedForAll(
        address _owner,
        address operator
    ) public view override(IERC721A, ERC721A) returns (bool) {
        require(
            blockList[operator] == false,
            "Operator has been denied by contract owner."
        );

        if (authorized[operator] == true) {
            return true;
        }

        return super.isApprovedForAll(_owner, operator);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /* OS */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721A, ERC721A) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner() public view virtual override(Ownable) returns (address) {
        return Ownable.owner();
    }

    /**
     * @notice sets the authorized operators for interacting with the contract
     * @param operator the address to be added to the authorized operators
     * @param approved whether the address is approved or not within authorized operators
     */
    function setAuthorized(address operator, bool approved) public onlyOwner {
        authorized[operator] = approved;
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     * @param _minter The address of the new minter.
     */
    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    /**
     * @notice updates the deny list
     * @param flaggedOperator The address to be approved.
     * @param status True if the operator is approved, false to revoke approval.
     */
    function _updateDenyList(
        address flaggedOperator,
        bool status
    ) internal virtual {
        blockList[flaggedOperator] = status;
    }

    /**
     * @notice Mint a token to the given address.
     * @dev Only callable by the minter.
     * @param _to The address to mint the qf token to.
     */

    function mint(address _to, uint256 _qty) public onlyMinter {
        if (totalSupply() + _qty > maxSupply) revert MaxSupplyExceeded();
        _mint(_to, _qty);
    }

    /**
     * @notice Burn a pass.
     * @dev Only callable by the minter.
     * @param tokenId The ID of the qf token to burn.
     */
    function burn(uint256 tokenId) public override onlyOwner {
        _burn(tokenId);
        emit TokenBurned(tokenId);
    }

    /**
     * @notice Set the base URI.
     * @dev Only callable by the owner.
     * @param _newBaseURI The new base URI.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
        emit BatchMetadataUpdate(0, maxSupply - 1);
    }

    /// @notice Identical to setBaseURI but callable by minter only.
    function setBaseURIMinter(string memory _newBaseURI) public onlyMinter {
        baseURI = _newBaseURI;
        emit BatchMetadataUpdate(0, maxSupply - 1);
    }
}
