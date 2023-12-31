//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./NameMintingController.sol";
import "./NameMintingRegistrar.sol";
import "./NameRegistry.sol";
import "./WhitelistRegistry.sol";
import "./ReservedRegistry.sol";
import "./NameWrapperDelegate.sol";
import "./PaymentCall.sol";
import "./SubmintValidationCall.sol";
import "./RegistryCalls.sol";
import "./BulkWrapper.sol";
import "./IBaseRegistrar.sol";

contract Deployer {
    BulkWrapper public bulkWrapper;
    NameRegistry public nameRegistry;
    WhitelistRegistry public whitelistRegistry;
    ReservedRegistry public reservedRegistry;
    NameWrapperDelegate public nameWrapperDelegate;
    NameMintingRegistrar public nameMintingRegistrar;
    NameMintingController public nameMintingController;
    PaymentCall public paymentCall;
    SubmintValidationCall public validation;
    RegistryCalls public registryCalls;
    address public multisigTreasury;
    address public multisigDeployer;

    constructor(
        INameWrapper nameWrapper,
        IBaseRegistrar ensBaseRegistrar,
        address _multisigTreasury,
        address _multisigDeployer,
        address wethAddress
    ) {
        multisigTreasury = _multisigTreasury;
        multisigDeployer = _multisigDeployer;

        // registries
        nameRegistry = new NameRegistry();
        whitelistRegistry = new WhitelistRegistry();
        reservedRegistry = new ReservedRegistry();

        // NameWrapper delegate
        nameWrapperDelegate = new NameWrapperDelegate(nameWrapper);

        // registrar
        nameMintingRegistrar = new NameMintingRegistrar(
            nameRegistry,
            whitelistRegistry,
            reservedRegistry,
            nameWrapper,
            nameWrapperDelegate
        );
        nameRegistry.setController(address(nameMintingRegistrar), true);
        reservedRegistry.setController(address(nameMintingRegistrar), true);
        whitelistRegistry.setController(address(nameMintingRegistrar), true);

        registryCalls = new RegistryCalls();
        validation = new SubmintValidationCall();
        paymentCall = new PaymentCall();

        // controller
        nameMintingController = new NameMintingController(
            nameWrapperDelegate,
            multisigTreasury,
            address(nameRegistry),
            address(whitelistRegistry),
            address(reservedRegistry),
            address(registryCalls),
            address(validation),
            address(paymentCall),
            wethAddress
        );
        nameMintingController.setController(msg.sender, true);
        nameRegistry.setController(address(nameMintingController), true);
        reservedRegistry.setController(address(nameMintingController), true);
        whitelistRegistry.setController(address(nameMintingController), true);

        nameMintingRegistrar.setController(
            address(nameMintingController),
            true
        );

        nameWrapperDelegate.setController(address(nameMintingRegistrar), true);
        nameWrapperDelegate.setController(address(nameMintingController), true);

        bulkWrapper = new BulkWrapper(nameWrapper, ensBaseRegistrar);

        // transfer ownerships to the multisig wallet
        nameRegistry.transferOwnership(multisigDeployer);
        whitelistRegistry.transferOwnership(multisigDeployer);
        reservedRegistry.transferOwnership(multisigDeployer);
        nameWrapperDelegate.transferOwnership(multisigDeployer);
        nameMintingRegistrar.transferOwnership(multisigDeployer);
        nameMintingController.transferOwnership(multisigDeployer);
        bulkWrapper.transferOwnership(multisigDeployer);
    }
}
