// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IERC1155Mintable.sol";
import "./AccessProtected.sol";
import "./LimitPerWallet.sol";
import "./RandomGenerator.sol";
import "./SignatureProtected.sol";
import "./TimeProtected.sol";
import "./console.sol";

contract AllowlistMint is AccessProtected, LimitPerWallet, RandomGenerator, SignatureProtected, TimeProtected {
    IERC1155Mintable public erc1155Contract;

    uint256 constant availableColors = 4;

    constructor(address _signerAddress, address _erc1155Address) SignatureProtected(_signerAddress) {
        erc1155Contract = IERC1155Mintable(_erc1155Address);
    }

    function mint(
        uint256 _maxPerWallet,
        uint256 _fromTimestamp,
        uint256 _toTimestamp,
        bytes calldata _signature
    ) external onlyUser {
        validateSignature(abi.encodePacked(_maxPerWallet, _fromTimestamp, _toTimestamp), _signature);

        isMintOpen(_fromTimestamp, _toTimestamp);

        require(getAvailableForWallet(1, _maxPerWallet) > 0, "No tokens left to be minted");

        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        uint256 color = uint8(getRandomNumber(availableColors, 0));

        ids[0] = (color << 6) | (color << 4) | (color << 2) | color;
        amounts[0] = 1;

        console.log("id to mint", color, ids[0]);
        erc1155Contract.mint(msg.sender, ids, amounts);
    }
}
