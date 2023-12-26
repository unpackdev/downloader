// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./Ownable.sol";
import "./PBTTwoTiered.sol";

error MaxSupplyReached();
error MintNotOpen();
error CannotMakeChanges();
error CannotUpdateDeadline();

contract MindOfGus is PBTTwoTiered, Ownable {
    uint256 public immutable maxSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 maxRandomTokenId_
    ) PBTTwoTiered(name_, symbol_, maxRandomTokenId_) {
        maxSupply = maxSupply_;
    }

    uint256 public changeDeadline;
    uint256 public totalSupply;
    bool public canMint;

    string private _baseTokenURI;

    function seedChipAddresses(
        address[] calldata chipAddresses
    ) external onlyOwner {
        _seedChipAddresses(chipAddresses);
    }

    function updateChips(
        address[] calldata chipAddressesOld,
        address[] calldata chipAddressesNew
    ) external onlyOwner {
        if (changeDeadline != 0 && block.timestamp > changeDeadline) {
            revert CannotMakeChanges();
        }
        _updateChips(chipAddressesOld, chipAddressesNew);
    }

    function mintMOG(
        bytes calldata signatureFromChip,
        uint256 blockNumberUsedInSig
    ) external {
        if (!canMint) {
            revert MintNotOpen();
        }
        if (totalSupply == maxSupply) {
            revert MaxSupplyReached();
        }
        _mintTokenWithChip(signatureFromChip, blockNumberUsedInSig);
        unchecked {
            ++totalSupply;
        }
    }

    function openMint() external onlyOwner {
        canMint = true;
    }

    function setChangeDeadline(uint256 timestamp) external onlyOwner {
        if (changeDeadline != 0) {
            revert CannotUpdateDeadline();
        }
        changeDeadline = timestamp;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function seedChipToTokenMappingForNonRandomSet(
        address[] calldata chipAddresses,
        uint256[] calldata tokenIds,
        bool throwIfInvalid
    ) external onlyOwner {
        _seedChipToTokenMappingForNonRandomSet(
            chipAddresses,
            tokenIds,
            throwIfInvalid
        );
    }
}
