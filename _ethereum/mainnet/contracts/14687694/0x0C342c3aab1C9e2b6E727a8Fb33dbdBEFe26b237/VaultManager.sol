// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./CloneFactory.sol";
import "./IERC20.sol";
import "./IERC721Enumerable.sol";

error NotOwner();
error Initialised();
error MissingWallets();
error FailedTransfer();
error VaultExists(address vault);

contract VaultManager is CloneFactory {
    Vault public singleton = new Vault();
    mapping(address => Vault) public vaults;

    event VaultCreated(address vault);

    constructor() {
        singleton.init(address(this));
    }

    function createVault() external {
        if (address(vaults[msg.sender]) != address(0)) {
            revert VaultExists(address(vaults[msg.sender]));
        }

        Vault vault = _createVaultClone(msg.sender);
        vaults[msg.sender] = vault;
    }

    function _createVaultClone(address owner) internal returns (Vault vault) {
        address _vault = createClone(address(singleton));
        vault = Vault(payable(_vault));
        vault.init(owner);

        emit VaultCreated(_vault);
    }
}

contract Vault {
    bool initialised;
    address public owner;
    IERC20 public constant token =
        IERC20(0x4d224452801ACEd8B2F0aebE155379bb5D594381);
    IERC721Enumerable public constant otherdeed =
        IERC721Enumerable(0x34d85c9CDeB23FA97cb08333b511ac86E1C4E258);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function init(address _owner) external {
        if (initialised) revert Initialised();

        owner = _owner;
        initialised = true;
    }

    receive() external payable {}

    function disperse(address[] calldata wallets, uint256 tokenAmount)
        external
        payable
        onlyOwner
    {
        if (wallets.length == 0) revert MissingWallets();
        uint256 share = msg.value / wallets.length;

        for (uint256 i; i < wallets.length; i++) {
            bool success;

            if (tokenAmount > 0) {
                success = token.transferFrom(
                    msg.sender,
                    wallets[i],
                    tokenAmount
                );
                if (!success) {
                    revert FailedTransfer();
                }
            }

            if (share > 0) {
                (success, ) = wallets[i].call{value: share}("");
                if (!success) {
                    revert FailedTransfer();
                }
            }
        }
    }

    function claimTokensBundle(address[] calldata wallets, uint256 maxMintPerTx)
        external
        onlyOwner
    {
        if (wallets.length == 0) revert MissingWallets();
        uint256 tokenId = otherdeed.tokenOfOwnerByIndex(wallets[0], 0);

        for (uint256 i; i < wallets.length; i++) {
            for (uint256 j; j < maxMintPerTx; j++) {
                otherdeed.transferFrom(wallets[i], msg.sender, tokenId++);
            }
        }
    }

    function claimTokens(address[] calldata wallets) external onlyOwner {
        if (wallets.length == 0) revert MissingWallets();
        for (uint256 i; i < wallets.length; i++) {
            uint256 tokens = otherdeed.balanceOf(wallets[i]);

            for (uint256 j; j < tokens; j++) {
                otherdeed.transferFrom(
                    wallets[i],
                    msg.sender,
                    otherdeed.tokenOfOwnerByIndex(wallets[i], 0)
                );
            }
        }
    }

    function withdraw(address wallet) external onlyOwner {
        bool success;
        uint256 balance = token.balanceOf(address(this));

        if (balance > 0) {
            success = token.transferFrom(address(this), wallet, balance);
            if (!success) {
                revert FailedTransfer();
            }
        }

        if (address(this).balance > 0) {
            (success, ) = wallet.call{value: address(this).balance}("");
            if (!success) {
                revert FailedTransfer();
            }
        }
    }
}
