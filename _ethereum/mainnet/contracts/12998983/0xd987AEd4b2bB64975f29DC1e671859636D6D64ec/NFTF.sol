/**
 * SPDX-License-Identifier: UNLICENSED
 *
 * © 2021 Nonagon Technologies LLC
 * All rights reserved
 */

pragma solidity ^0.8.0;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC1155Upgradeable.sol";

/**
 * @dev NFTF token contract
 *   - managing NFTF tokens (minting, burning, updating)
 *   - managing contract operators
 */
contract NFTF is UUPSUpgradeable, OwnableUpgradeable, ERC1155Upgradeable {
    string private _name;
    string private _symbol;

    //----------------------------------------------------------
    // Infrastructure
    //----------------------------------------------------------

    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        ERC1155Upgradeable.__ERC1155_init(uri);

        _name = tokenName;
        _symbol = tokenSymbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    //----------------------------------------------------------
    // Tokens
    //----------------------------------------------------------

    function mint(
        uint256 tokenId,
        uint256 amount,
        address recipientAddress
    ) external onlyOwner {
        _mint(recipientAddress, tokenId, amount, "");
    }

    function mintBatch(
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        address recipientAddress
    ) external onlyOwner {
        _mintBatch(recipientAddress, tokenIds, amounts, "");
    }

    function burn(uint256 tokenId, uint256 amount) external onlyOwner {
        _burn(msg.sender, tokenId, amount);
    }

    function burnBatch(uint256[] memory tokenIds, uint256[] memory amounts)
        external
        onlyOwner
    {
        _burnBatch(msg.sender, tokenIds, amounts);
    }

    function update(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) external onlyOwner {
        _name = tokenName;
        _symbol = tokenSymbol;

        //base class method
        _setURI(uri);
    }
}
