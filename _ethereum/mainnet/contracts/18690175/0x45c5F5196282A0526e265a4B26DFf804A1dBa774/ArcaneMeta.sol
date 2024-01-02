// SPDX-License-Identifier: MIT
// Creator: lohko.io

pragma solidity >=0.8.19;

import {ERC721A} from "ERC721A.sol";
import {ERC2981} from "ERC2981.sol";
import {Ownable} from "Ownable.sol";
import {Strings} from "Strings.sol";
import {PaymentSplitter} from "PaymentSplitter.sol";
import {MerkleProof} from "MerkleProof.sol";

contract ArcaneMeta is Ownable, ERC721A, ERC2981, PaymentSplitter {
    using Strings for uint256;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant PUBLIC_SUPPLY_CAP = 4555;
    uint256 public constant WHITELIST_SUPPLY_CAP = 1000;

    uint256 public maxMintsPerTx = 20;
    uint256 public price = 0.0029 ether;

    /*//////////////////////////////////////////////////////////////
                                VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint32 public mintStart;

    bytes32 public merkleRoot;

    bool public revealed;

    string private _baseTokenURI;
    string private _notRevealedUri;

    uint256 private _totalWhitelistMinted;
    uint256 private _totalPublicMinted;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error SaleNotStarted();
    error InvalidProof();
    error QuantityOffLimits();
    error MaxSupplyReached();
    error InsufficientFunds();
    error InvalidInput();
    error NonExistentTokenURI();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _initNotRevealedUri,
        address[] memory payees_,
        uint256[] memory shares_
    ) ERC721A("Arcane Meta", "ARCANEMETA") PaymentSplitter(payees_, shares_) {
        _notRevealedUri = _initNotRevealedUri;
        _mint(msg.sender, 1);
        _totalPublicMinted += 1;
    }

    /*//////////////////////////////////////////////////////////////
                            MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function publicMint(uint256 quantity) external payable {
        // If minting has not started by reaching timestamp, revert.
        if (block.timestamp < mintStart) revert SaleNotStarted();

        // If public supply cap is reached, revert.
        uint256 totalPublicMinted = _totalPublicMinted + quantity;
        if (totalPublicMinted > PUBLIC_SUPPLY_CAP) revert MaxSupplyReached();

        // If provided quantity is outside of predefined limits, revert.
        if (quantity == 0 || quantity > maxMintsPerTx)
            revert QuantityOffLimits();

        // If the user has unclaimed free token, mint one free.
        uint256 _paidQuantity = quantity;
        if (_getAux(msg.sender) == 0) {
            // Set free token as claimed.
            _setAux(msg.sender, 1);
            _paidQuantity -= 1;
        }
        // If provided value doesn't match with the price, revert.
        if (msg.value != price * _paidQuantity) revert InsufficientFunds();

        _totalPublicMinted = totalPublicMinted;

        _mint(msg.sender, quantity);
    }

    function whitelistMint(
        uint256 quantity,
        bytes32[] memory proof
    ) external payable {
        // If minting has not started by reaching timestamp, revert.
        if (block.timestamp < mintStart) revert SaleNotStarted();

        // If provided proof is invalid, revert.
        if (
            !(
                MerkleProof.verify(
                    proof,
                    merkleRoot,
                    keccak256(abi.encodePacked(msg.sender))
                )
            )
        ) revert InvalidProof();

        // If the max supply cap is reached, revert.
        uint256 totalWhitelistMinted = _totalWhitelistMinted + quantity;
        if (totalWhitelistMinted > WHITELIST_SUPPLY_CAP)
            revert MaxSupplyReached();

        // If provided quantity is outside of predefined limits, revert.
        if (quantity == 0 || quantity > maxMintsPerTx)
            revert QuantityOffLimits();

        // If the user has unclaimed free token, mint one free.
        uint256 _paidQuantity = quantity;
        if (_getAux(msg.sender) == 0) {
            // Set free token as claimed.
            _setAux(msg.sender, 1);
            _paidQuantity -= 1;
        }
        // If provided value doesn't match with the price, revert.
        if (msg.value != price * _paidQuantity) revert InsufficientFunds();

        _totalWhitelistMinted = totalWhitelistMinted;

        _mint(msg.sender, quantity);
    }

    /*//////////////////////////////////////////////////////////////
                            FRONTEND HELPERS
    //////////////////////////////////////////////////////////////*/

    function isWhitelistOpen() public view returns (bool) {
        return _totalWhitelistMinted < WHITELIST_SUPPLY_CAP ? true : false;
    }

    function isPublicOpen() public view returns (bool) {
        return _totalPublicMinted < PUBLIC_SUPPLY_CAP ? true : false;
    }

    function isMintOpen() public view returns (bool) {
        return block.timestamp < mintStart ? false : true;
    }

    function freeClaimed(address user) public view returns (uint256) {
        return _getAux(user);
    }

    function totalMinted() external view virtual returns (uint256) {
        return _totalMinted();
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////*/

    function rewardCollaborators(
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external onlyOwner {
        // If there is a mismatch between receivers and amounts lengths, revert.
        if (receivers.length != amounts.length || receivers.length == 0)
            revert InvalidInput();

        for (uint256 i; i < receivers.length; ) {
            // If the max supply cap is reached, revert.
            if (
                _totalMinted() + amounts[i] >
                PUBLIC_SUPPLY_CAP + WHITELIST_SUPPLY_CAP
            ) revert MaxSupplyReached();

            _mint(receivers[i], amounts[i]);

            unchecked {
                ++i;
            }
        }
    }

    function setMintStart(uint32 _mintStart) external onlyOwner {
        mintStart = _mintStart;
    }

    function setNotRevealedURI(string memory notRevealedURI) public onlyOwner {
        _notRevealedUri = notRevealedURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    /*//////////////////////////////////////////////////////////////
                                OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert NonExistentTokenURI();
        if (revealed == false) {
            return _notRevealedUri;
        }
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}
