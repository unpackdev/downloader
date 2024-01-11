// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./Container.sol";
import "./Withdrawable.sol";

error MintNotActive();
error NotEnoughUSDC();

/**
 * @title MRL Container Minter
 * @dev Contract for minting the containers for the https://monsterracingleague.com project
 * @author Phat Loot DeFi Developers
 * @custom:version v1.1
 * @custom:date 25 June 2022
 *
 * @custom:changelog
 *
 * v1.1
 * - Using MerkleTree for whitelisting
 * 
 * v1.2
 * - Remove whitelisting
 */
contract ContainerMinter is AccessControl, Withdrawable {
    bytes32 public constant STAFF_ROLE = keccak256("STAFF_ROLE");

    Container private immutable _container = Container(address(0xa7eF5544a2ABbF5B9D8A0cb4D8530E9D107072B6)); // Ethereum
    IERC20 private immutable _usdc = IERC20(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)); // Ethereum

    bool public mintActive = true;

    uint256 public mintingFee = 200 * 10**6; // 200 USDC (with 6 decimals)

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(STAFF_ROLE, msg.sender);
    }

    function flipMintActive() external onlyRole(STAFF_ROLE) {
        mintActive = !mintActive;
    }

    function safeMint() public returns (uint256 tokenId) {
        if(!mintActive) revert MintNotActive();

        // Collect payment
        uint256 balance = _usdc.balanceOf(msg.sender);
        if(balance < mintingFee) revert NotEnoughUSDC();
        SafeERC20.safeTransferFrom(_usdc, msg.sender, address(this), mintingFee);

        return _safeMint();
    }

    function safeMintBatch(uint256 amount) external {
        if(!mintActive) revert MintNotActive();

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
