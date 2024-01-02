//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "./Ownable.sol";
import "./Pausable.sol";
import "./TransparentUpgradeableProxy.sol";
import "./ProxyAdmin.sol";
import "./CHARACTER_V1_UPGRADABLE.sol";

contract CHARACTER_UPGRADEABLE_FACTORY_V1 is Pausable, Ownable{
    event ContractDeployed(address indexed deployerAddress, address indexed contractAddress);
    mapping(address => bool) public whitelist;

    function addToWhitelist(address[] calldata toAddAddresses) external onlyOwner {
        for (uint256 i = 0; i < toAddAddresses.length; i++) {
            whitelist[toAddAddresses[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata toRemoveAddresses) external onlyOwner {
        for (uint256 i = 0; i < toRemoveAddresses.length; i++) {
            delete whitelist[toRemoveAddresses[i]];
        }
    }

    function deployProxyContract(
        address implementationContract,
        string memory name,
        string memory symbol,
        address ownerAddress,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator,
        address[] calldata minterRoleAddress
    ) whenNotPaused() external returns (address) {
        require(whitelist[msg.sender], "NOT_IN_WHITELIST");
        require(implementationContract != address(0));

        ProxyAdmin PROXY_ADMIN = new ProxyAdmin();
        PROXY_ADMIN.transferOwnership(msg.sender);

        TransparentUpgradeableProxy newProxy = new TransparentUpgradeableProxy(
            implementationContract,
            address(PROXY_ADMIN),
            abi.encodeWithSelector(CHARACTER_V1_UPGRADEABLE.initialize.selector, name, symbol)
        );

        CHARACTER_V1_UPGRADEABLE proxyCharacter = CHARACTER_V1_UPGRADEABLE(address(newProxy));

        // Set roles and other initialization logic
        proxyCharacter.transferOwnership(ownerAddress);
        proxyCharacter.grantRole(proxyCharacter.DEFAULT_ADMIN_ROLE(), ownerAddress);
        proxyCharacter.grantRole(proxyCharacter.PAUSER_ROLE(), ownerAddress);
        proxyCharacter.grantRole(proxyCharacter.ROYALTY_ROLE(), ownerAddress);

        // Setting Royalty & minter role
        proxyCharacter.setDefaultRoyalty(royaltyReceiver, royaltyFeeNumerator);
        for (uint i = 0; i < minterRoleAddress.length; i++) {
            proxyCharacter.grantRole(proxyCharacter.MINTER_ROLE(), minterRoleAddress[i]);
        }

        // revoke roles of factory
        proxyCharacter.renounceRole(proxyCharacter.DEFAULT_ADMIN_ROLE(), address(this));
        proxyCharacter.renounceRole(proxyCharacter.PAUSER_ROLE(), address(this));
        proxyCharacter.renounceRole(proxyCharacter.ROYALTY_ROLE(), address(this));
        proxyCharacter.renounceRole(proxyCharacter.MINTER_ROLE(), address(this));

        emit ContractDeployed(msg.sender, address(proxyCharacter));
        return address(newProxy);
    }

}