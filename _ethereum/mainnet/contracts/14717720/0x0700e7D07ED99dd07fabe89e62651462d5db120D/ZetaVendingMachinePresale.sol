//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./IVendingMachine.sol";

contract ZetaVendingMachinePresale is IVendingMachine {
    // tokenId => price
    mapping(uint256 => uint256) private prices;
    // tokenId => rootHash
    mapping(uint256 => bytes32) private rootHashes;

    bool public mintEnabled;

    constructor(address _zetaERC1155) IVendingMachine(_zetaERC1155) {
        mintEnabled = false;
    }

    function price(uint256 id) external view returns (uint256) {
        return prices[id];
    }

    function setPrice(uint256 id, uint256 _price) external onlyRole(DEPLOYER) {
        prices[id] = _price;
    }

    function setMintEnabled(bool _mintEnabled) external onlyRole(DEPLOYER) {
        mintEnabled = _mintEnabled;
    }

    function rootHash(uint256 id) external view returns (bytes32) {
        return rootHashes[id];
    }

    function setRootHash(uint256 id, bytes32 _rootHash)
        external
        onlyRole(DEPLOYER)
    {
        rootHashes[id] = _rootHash;
    }

    function mint(uint256 id, uint256 amount)
        external
        payable
        virtual
        override
    {
        revert NotOnSale();
    }

    function mint(
        bytes32[] calldata _proof,
        uint256 id,
        uint256 amount
    ) external payable virtual {
        if (!mintEnabled) {
            revert NotOnSale();
        }

        if (prices[id] == 0) {
            revert NotOnSale();
        }

        if (rootHashes[id] == bytes32(0)) {
            revert NotOnSale();
        }

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        if (!MerkleProof.verify(_proof, rootHashes[id], leaf)) {
            revert NotInWhitelist();
        }

        if (amount * prices[id] > msg.value) {
            revert NotEnoughFunds();
        }

        _safeDecreaseAvailableStock(id, amount);
        zetaERC1155.mint(
            msg.sender,
            id,
            amount,
            "Zeta Vending Machine Presale"
        );
    }
}
