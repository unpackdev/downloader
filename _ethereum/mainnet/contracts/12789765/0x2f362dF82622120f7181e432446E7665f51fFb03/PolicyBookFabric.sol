// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./TransparentUpgradeableProxy.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

import "./DecimalsConverter.sol";

import "./IPolicyBook.sol";
import "./IPolicyBookAdmin.sol";
import "./IPolicyBookFabric.sol";
import "./IPolicyBookRegistry.sol";
import "./IContractsRegistry.sol";
import "./ILiquidityMining.sol";

import "./AbstractDependant.sol";

import "./Globals.sol";

contract PolicyBookFabric is IPolicyBookFabric, AbstractDependant {
    using SafeERC20 for ERC20;

    uint256 public constant MINIMAL_INITIAL_DEPOSIT = 1000 * DECIMALS18; // 1000 STBL

    IContractsRegistry public contractsRegistry;
    IPolicyBookRegistry public policyBookRegistry;
    IPolicyBookAdmin public policyBookAdmin;
    ILiquidityMining public liquidityMining;
    ERC20 public stblToken;

    uint256 public stblDecimals;

    event Created(address insured, ContractType contractType, address at);

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        contractsRegistry = _contractsRegistry;

        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
        policyBookAdmin = IPolicyBookAdmin(_contractsRegistry.getPolicyBookAdminContract());
        liquidityMining = ILiquidityMining(_contractsRegistry.getLiquidityMiningContract());
        stblToken = ERC20(_contractsRegistry.getUSDTContract());

        stblDecimals = stblToken.decimals();
    }

    function create(
        address _insuranceContract,
        ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol,
        uint256 _initialDeposit
    ) external override returns (address) {
        require(_insuranceContract != address(0), "PBF: Null address");
        require(bytes(_description).length <= 200, "PBF: Project description is too long");
        require(
            bytes(_projectSymbol).length != 0 && bytes(_projectSymbol).length <= 30,
            "PBF: Project symbol is too long/short"
        );
        require(!liquidityMining.isLMLasting(), "PBF: Creation is blocked during LME");
        require(
            !liquidityMining.isLMEnded() || _initialDeposit >= MINIMAL_INITIAL_DEPOSIT,
            "PBF: Too small deposit"
        );

        TransparentUpgradeableProxy _proxy =
            new TransparentUpgradeableProxy(
                policyBookAdmin.getCurrentPolicyBooksImplementation(),
                policyBookAdmin.getUpgrader(),
                ""
            );

        IPolicyBook(address(_proxy)).__PolicyBook_init(
            _insuranceContract,
            _contractType,
            _description,
            _projectSymbol
        );

        AbstractDependant(address(_proxy)).setDependencies(contractsRegistry);
        AbstractDependant(address(_proxy)).setInjector(address(policyBookAdmin));

        policyBookRegistry.add(_insuranceContract, _contractType, address(_proxy));

        emit Created(_insuranceContract, _contractType, address(_proxy));

        /// @dev make creation of pool free before LME (mind that creation is blocked during LME)
        if (_initialDeposit > 0) {
            stblToken.safeTransferFrom(
                msg.sender,
                address(_proxy),
                DecimalsConverter.convertFrom18(_initialDeposit, stblDecimals)
            );

            IPolicyBook(address(_proxy)).addLiquidityFor(msg.sender, _initialDeposit);
        }

        return address(_proxy);
    }
}
