// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Supply.sol";
import "./IERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./Ownable.sol";

contract VSPxAKU is ERC1155Supply, ReentrancyGuard, AccessControl, Ownable {
    using Strings for uint256;
    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT");

    mapping(uint256 => bool) public claimedTokenIds;
    bool public saleActive;
    string private _baseURIextended;
    string public name = "VSP x AKU";
    string public symbol = "VSPXAKU";

    IERC721Enumerable public immutable baseContractAddress;
    uint256 public immutable maxSupply;
    uint256 private immutable _numberOfTypes;

    constructor(address contractAddress, uint256 types) ERC1155("") {
        require(
            IERC721Enumerable(contractAddress).supportsInterface(0x780e9d63),
            "Contract address does not support ERC721Enumerable"
        );

        // set immutable variables
        baseContractAddress = IERC721Enumerable(contractAddress);
        maxSupply = IERC721Enumerable(contractAddress).totalSupply();
        _numberOfTypes = types;

        // setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPORT_ROLE, msg.sender);
    }

    /**
     * @dev checks to see if amount of tokens to be minted would exceed the maximum supply allowed
     */
    modifier supplyAvailable(uint256[] calldata numberOfTokens) {
        uint256 ts;
        uint256 totalTokens;

        for (uint256 index; index < numberOfTokens.length; index++) {
            ts += totalSupply(index);
            totalTokens += numberOfTokens[index];
        }

        require(ts + totalTokens <= maxSupply, "Purchase would exceed max tokens");
        _;
    }

    /**
     * @dev checks to see whether saleActive is true
     */
    modifier isPublicSaleActive() {
        require(saleActive, "Public sale is not active");
        _;
    }

    ////////////////
    // admin
    ////////////////
    /**
     * @dev allows public sale minting
     */
    function setSaleActive(bool state) external onlyRole(SUPPORT_ROLE) {
        saleActive = state;
    }

    ////////////////
    // tokens
    ////////////////
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev sets the base uri
     */
    function setBaseURI(string memory baseURI_) external onlyRole(SUPPORT_ROLE) {
        _baseURIextended = baseURI_;
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return bytes(_baseURIextended).length > 0 ? string(abi.encodePacked(_baseURIextended, tokenId.toString())) : "";
    }

    ////////////////
    // public
    ////////////////
    /**
     * @dev allow public minting
     */
    function mint(uint256[] calldata numberOfTokens)
        external
        isPublicSaleActive
        supplyAvailable(numberOfTokens)
        nonReentrant
    {
        require(numberOfTokens.length == _numberOfTypes, "Invalid token length");
        uint256 baseBalance = baseContractAddress.balanceOf(msg.sender);
        uint256 tokensToMint;
        uint256 claimable;

        // count number of tokens to mint
        for (uint256 index; index < _numberOfTypes; index++) {
            tokensToMint += numberOfTokens[index];
        }

        // iterate through balance
        for (uint256 index; index < baseBalance && claimable < tokensToMint; index++) {
            uint256 tokenId = baseContractAddress.tokenOfOwnerByIndex(msg.sender, index);

            if (!claimedTokenIds[tokenId]) {
                claimedTokenIds[tokenId] = true;
                claimable++;
            }
        }
        require(tokensToMint <= claimable, "Number of tokens exceeds claimable amount");

        for (uint256 index; index < _numberOfTypes; index++) {
            if (numberOfTokens[index] != 0) {
                _mint(msg.sender, index, numberOfTokens[index], "");
            }
        }
    }

    /**
     * @dev returns the available number of tokens for an address
     */
    function available(address from) external view returns (uint256) {
        uint256 baseBalance = baseContractAddress.balanceOf(from);
        uint256 balance;

        for (uint256 index; index < baseBalance; index++) {
            uint256 tokenId = baseContractAddress.tokenOfOwnerByIndex(from, index);
            if (!claimedTokenIds[tokenId]) {
                balance += 1;
            }
        }

        return balance;
    }
}
