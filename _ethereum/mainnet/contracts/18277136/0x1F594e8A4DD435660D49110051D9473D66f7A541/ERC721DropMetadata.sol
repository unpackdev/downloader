// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./ERC721AUpgradeable.sol";
import "./MulticallUpgradeable.sol";

import "./AdministratedUpgradeable.sol";

import "./IERC721DropMetadata.sol";

abstract contract ERC721DropMetadata is
    AdministratedUpgradeable,
    ERC721AUpgradeable,
    MulticallUpgradeable,
    IERC721DropMetadata
{
    uint256 public maxSupply;
    string public baseURI;
    bytes32 public provenanceHash;

    mapping(address payer => bool allowed) public allowedPayers;

    function getAmountMinted(address user) external view returns (uint64) {
        return _getAux(user);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    function airdrop(
        address[] calldata to,
        uint64[] calldata quantity
    ) external onlyOwnerOrAdministrator {
        address[] memory recipients = to;

        for (uint64 i = 0; i < recipients.length; ) {
            _mint(recipients[i], quantity[i]);

            unchecked {
                ++i;
            }
        }

        if (_totalMinted() > maxSupply) {
            revert MintQuantityExceedsMaxSupply();
        }
    }

    function updateMaxSupply(
        uint256 newMaxSupply
    ) external onlyOwnerOrAdministrator {
        _updateMaxSupply(newMaxSupply);
    }

    function updateBaseURI(
        string calldata newUri
    ) external onlyOwnerOrAdministrator {
        _updateBaseURI(newUri);
    }

    function updateProvenanceHash(
        bytes32 newProvenanceHash
    ) external onlyOwnerOrAdministrator {
        _updateProvenanceHash(newProvenanceHash);
    }

    function updatePayer(
        address payer,
        bool isAllowed
    ) external onlyOwnerOrAdministrator {
        allowedPayers[payer] = isAllowed;

        emit AllowedPayerUpdated(payer, isAllowed);
    }

    function _updateMaxSupply(
        uint256 newMaxSupply
    ) internal {
        // Ensure the max supply does not exceed the maximum value of uint64.
        if (newMaxSupply > 2 ** 64 - 1) {
            revert CannotExceedMaxSupplyOfUint64();
        }

        maxSupply = newMaxSupply;

        emit MaxSupplyUpdated(newMaxSupply);
    }


    function _updateBaseURI(
        string calldata newUri
    ) internal {
        baseURI = newUri;

        if (totalSupply() != 0) {
            emit BatchMetadataUpdate(1, _nextTokenId() - 1);
        }

        emit BaseURIUpdated(newUri);
    }

    function _updateProvenanceHash(
        bytes32 newProvenanceHash
    ) internal {
        // Ensure mint did not start
        if (_totalMinted() > 0) {
            revert ProvenanceHashCannotBeUpdatedAfterMintStarted();
        }

        provenanceHash = newProvenanceHash;

        emit ProvenanceHashUpdated(newProvenanceHash);
    }

    function _checkPayer(address minter) internal view {
        if (minter != msg.sender) {
            if (!allowedPayers[msg.sender]) {
                revert PayerNotAllowed();
            }
        }
    }

    function _checkFunds(
        uint256 funds,
        uint256 quantity,
        uint256 tokenPrice
    ) internal pure {
        // Ensure enough ETH is sent
        if (funds < tokenPrice * quantity) {
            revert IncorrectFundsProvided();
        }
    }

    function _checkMintQuantity(
        address minter,
        uint256 quantity,
        uint256 walletLimit,
        uint256 maxSupplyForStage
    ) internal view {
        // Ensure max supply is not exceeded
        if (_totalMinted() + quantity > maxSupply) {
            revert MintQuantityExceedsMaxSupply();
        }

        // Ensure wallet limit is not exceeded
        uint256 balanceAfterMint = _getAux(minter) + quantity;
        if (balanceAfterMint > walletLimit) {
            revert MintQuantityExceedsWalletLimit();
        }

        // Ensure max supply for stage is not exceeded
        if (quantity + totalSupply() > maxSupplyForStage) {
            revert MintQuantityExceedsMaxSupplyForStage();
        }
    }

    function _checkStageActive(
        uint256 startTime,
        uint256 endTime
    ) internal view {
        if (block.timestamp < startTime || block.timestamp > endTime) {
            revert StageNotActive(block.timestamp, startTime, endTime);
        }
    }

    function _mintBase(
        address recipient,
        uint256 quantity,
        uint256 mintStageIndex
    ) internal {
        uint256 balanceAfterMint = _getAux(recipient) + quantity;

        _setAux(recipient, uint64(balanceAfterMint));
        _mint(recipient, quantity);

        emit Minted(recipient, quantity, mintStageIndex);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}
