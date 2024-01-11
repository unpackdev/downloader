// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";

import "./Container.sol";
import "./Withdrawable.sol";

error MintNotActive();
error NotOnTheAllowlist();
error NotEnoughUSDC();

/**
 * @title MRL Container Minter
 * @dev Contract for minting the containers for the https://monsterracingleague.com project
 * @author Phat Loot DeFi Developers
 * @custom:version v1.1
 * @custom:date 24 June 2022
 *
 * @custom:changelog
 *
 * v1.1
 * - Using MerkleTree for whitelisting
 */
contract ContainerMinter is AccessControl, Withdrawable {
    bytes32 public constant STAFF_ROLE = keccak256("STAFF_ROLE");

    Container private immutable _container = Container(address(0xa7eF5544a2ABbF5B9D8A0cb4D8530E9D107072B6)); // Ethereum
    IERC20 private immutable _usdc = IERC20(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)); // Ethereum

    bool public mintActive = false;

    uint256 public mintingFee = 200 * 10**6; // 200 USDC (with 6 decimals)

    bytes32 public merkleRoot = 0x8ee75b1534dd4fa0c9ae0e72b1e13d62f1ab9c87b6b52461d11e66d9d6c04e47;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(STAFF_ROLE, msg.sender);
    }

    function flipMintActive() external onlyRole(STAFF_ROLE) {
        mintActive = !mintActive;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(STAFF_ROLE) {
        merkleRoot = _merkleRoot;
    }

    function isAllowedToMint(address _address, bytes32[] memory _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function safeMint(bytes32[] memory _merkleProof) public returns (uint256 tokenId) {
        if(!mintActive) revert MintNotActive();
        if(!isAllowedToMint(msg.sender, _merkleProof)) revert NotOnTheAllowlist();

        // Collect payment
        uint256 balance = _usdc.balanceOf(msg.sender);
        if(balance < mintingFee) revert NotEnoughUSDC();
        SafeERC20.safeTransferFrom(_usdc, msg.sender, address(this), mintingFee);

        return _safeMint();
    }

    function safeMintBatch(uint256 amount, bytes32[] memory _merkleProof) external {
        if(!mintActive) revert MintNotActive();
        if(!isAllowedToMint(msg.sender, _merkleProof)) revert NotOnTheAllowlist();

        // Collect payment
        uint256 balance = _usdc.balanceOf(msg.sender);
        if(balance < mintingFee * amount) revert NotEnoughUSDC();
        SafeERC20.safeTransferFrom(_usdc, msg.sender, address(this), mintingFee * amount);

        for (uint256 i = 0; i < amount; i++) {
            _safeMint();
        }
    }

    function _safeMint() internal returns (uint256 tokenId) {
        return _container.safeMint(msg.sender);
    }
}
