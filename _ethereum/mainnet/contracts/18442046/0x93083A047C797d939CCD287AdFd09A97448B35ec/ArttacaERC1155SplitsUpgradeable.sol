// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (contracts/collections/erc1155/ArttacaERC1155SplitsUpgradeable.sol)

pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "./IERC2981Upgradeable.sol";
import "./Initializable.sol";

import "./ERC1155SupplyUpgradeable.sol";
import "./Ownership.sol";

/**
 * @title Arttaca ERC721 Splits logic
 *
 * @dev Basic splits definition for Arttaca collections.
 */
abstract contract ArttacaERC1155SplitsUpgradeable is IERC2981Upgradeable, ERC1155SupplyUpgradeable, OwnableUpgradeable {

    uint96 internal feeNumerator;
    mapping(uint => Ownership.Royalties) internal tokenRoyalties;

    function __Splits_init(uint96 _royaltyPct) internal onlyInitializing {
        __Splits_init_unchained(_royaltyPct);
    }

    function __Splits_init_unchained(uint96 _royaltyPct) internal onlyInitializing {
        _setDefaultRoyalty(_royaltyPct);
    }

    function royaltyInfo(uint _tokenId, uint _salePrice) external view virtual override returns (address, uint) {
        require(exists(_tokenId), "ArttacaERC1155SplitsUpgradeable::royaltyInfo: token has not been minted.");
        uint royaltyAmount = (_salePrice * feeNumerator * 100) / _feeDenominator();

        return (owner(), royaltyAmount);
    }

    function getRoyalties(uint _tokenId) public view returns (Ownership.Royalties memory) {
        return tokenRoyalties[_tokenId];
    }

    function _setRoyalties(uint _tokenId, Ownership.Royalties memory _royalties) internal {
        require(_checkSplits(_royalties.splits), "ArttacaERC1155SplitsUpgradeable::_setSplits: Total shares should be equal to 100.");

        if (tokenRoyalties[_tokenId].splits.length > 0) delete tokenRoyalties[_tokenId];
        for (uint i; i < _royalties.splits.length; i++) {
            tokenRoyalties[_tokenId].splits.push(_royalties.splits[i]);
        }
        tokenRoyalties[_tokenId].percentage = _royalties.percentage;
    }

    function _checkSplits(Ownership.Split[] memory _splits) internal pure returns (bool) {
        require(_splits.length <= 5, "ArttacaERC1155SplitsUpgradeable::_checkSplits: Can only split up to 5 addresses.");
        uint totalShares;
        for (uint i = 0; i < _splits.length; i++) {
            require(_splits[i].account != address(0x0), "ArttacaERC1155SplitsUpgradeable::_checkSplits: Invalid account.");
            require(_splits[i].shares > 0, "ArttacaERC1155SplitsUpgradeable::_checkSplits: Shares value must be greater than 0.");
            totalShares += _splits[i].shares;
        }
        return totalShares == _maxShares();
    }

    function getBaseRoyalty() external view returns (Ownership.Split memory) {
        return Ownership.Split(payable(owner()), feeNumerator);
    }

    function _setDefaultRoyalty(uint96 _feeNumerator) internal virtual {
        require(_feeNumerator <= _feeDenominator(), "ArttacaERC1155SplitsUpgradeable::_setDefaultRoyalty: Royalty fee must be lower than fee denominator.");
        feeNumerator = _feeNumerator;
    }

    function _maxShares() internal pure virtual returns (uint96) {
        return 100;
    }

    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC1155Upgradeable) returns (bool) {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    uint256[50] private __gap;
}
