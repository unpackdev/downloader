// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./OwnableUpgradeable.sol";
import "./TransparentUpgradeableProxy.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

import "./DecimalsConverter.sol";

import "./IPolicyBook.sol";
import "./IPolicyBookFacade.sol";
import "./IPolicyBookAdmin.sol";
import "./IPolicyBookFabric.sol";
import "./IPolicyBookRegistry.sol";
import "./IContractsRegistry.sol";
import "./ILiquidityMining.sol";
import "./IShieldMining.sol";
import "./IUserLeveragePool.sol";

import "./AbstractDependant.sol";

import "./PolicyBookFacade.sol";

import "./Globals.sol";

contract PolicyBookFabric is IPolicyBookFabric, OwnableUpgradeable, AbstractDependant {
    using SafeERC20 for ERC20;
    using Address for address;

    uint256 public constant MINIMAL_INITIAL_DEPOSIT = 1000 * DECIMALS18; // 1000 STBL

    IContractsRegistry public contractsRegistry;
    IPolicyBookRegistry public policyBookRegistry;
    IPolicyBookAdmin public policyBookAdmin;
    ILiquidityMining public liquidityMining;
    IShieldMining public shieldMining;
    ERC20 public stblToken;

    address public capitalPoolAddress;

    uint256 public stblDecimals;

    event Created(address insured, ContractType contractType, address at, address facade);

    function __PolicyBookFabric_init() external initializer {
        __Ownable_init();
    }

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
        capitalPoolAddress = IContractsRegistry(_contractsRegistry).getCapitalPoolContract();
        stblDecimals = stblToken.decimals();
        shieldMining = IShieldMining(_contractsRegistry.getShieldMiningContract());
    }

    function create(
        address _insuranceContract,
        ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol,
        uint256 _initialDeposit,
        address _shieldMiningToken
    ) public override returns (address) {
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

        TransparentUpgradeableProxy _policyBookProxy =
            new TransparentUpgradeableProxy(
                policyBookAdmin.getCurrentPolicyBooksImplementation(),
                policyBookAdmin.getUpgrader(),
                ""
            );

        IPolicyBook(address(_policyBookProxy)).__PolicyBook_init(
            _insuranceContract,
            _contractType,
            _description,
            _projectSymbol
        );

        TransparentUpgradeableProxy _policyBookFacadeProxy =
            new TransparentUpgradeableProxy(
                policyBookAdmin.getCurrentPolicyBooksFacadeImplementation(),
                policyBookAdmin.getUpgrader(),
                ""
            );

        IPolicyBookFacade(address(_policyBookFacadeProxy)).__PolicyBookFacade_init(
            address(_policyBookProxy),
            msg.sender,
            _initialDeposit
        );

        AbstractDependant(address(_policyBookProxy)).setDependencies(contractsRegistry);
        AbstractDependant(address(_policyBookProxy)).setInjector(address(policyBookAdmin));

        AbstractDependant(address(_policyBookFacadeProxy)).setDependencies(contractsRegistry);
        AbstractDependant(address(_policyBookFacadeProxy)).setInjector(address(policyBookAdmin));

        IPolicyBook(address(_policyBookProxy)).setPolicyBookFacade(
            address(_policyBookFacadeProxy)
        );

        policyBookRegistry.add(
            _insuranceContract,
            _contractType,
            address(_policyBookProxy),
            address(_policyBookFacadeProxy)
        );

        emit Created(
            _insuranceContract,
            _contractType,
            address(_policyBookProxy),
            address(_policyBookFacadeProxy)
        );

        /// @dev make creation of pool free before LME (mind that creation is blocked during LME)

        stblToken.safeTransferFrom(
            msg.sender,
            capitalPoolAddress,
            DecimalsConverter.convertFrom18(_initialDeposit, stblDecimals)
        );

        IPolicyBook(address(_policyBookProxy)).addLiquidityFor(msg.sender, _initialDeposit);

        if (_shieldMiningToken != address(0)) {
            shieldMining.associateShieldMining(address(_policyBookProxy), _shieldMiningToken);
        }

        return address(_policyBookProxy);
    }

    function createLeveragePools(
        ContractType _contractType,
        string calldata _description,
        string calldata _projectSymbol
    ) public override onlyOwner returns (address) {
        require(bytes(_description).length <= 200, "PBF: Project description is too long");
        require(
            bytes(_projectSymbol).length != 0 && bytes(_projectSymbol).length <= 30,
            "PBF: Project symbol is too long/short"
        );

        TransparentUpgradeableProxy _userLeverageProxy =
            new TransparentUpgradeableProxy(
                policyBookAdmin.getCurrentUserLeverageImplementation(),
                policyBookAdmin.getUpgrader(),
                ""
            );

        IUserLeveragePool(address(_userLeverageProxy)).__UserLeveragePool_init(
            _contractType,
            _description,
            _projectSymbol
        );

        AbstractDependant(address(_userLeverageProxy)).setDependencies(contractsRegistry);
        AbstractDependant(address(_userLeverageProxy)).setInjector(address(policyBookAdmin));
        policyBookRegistry.add(address(0), _contractType, address(_userLeverageProxy), address(0));

        emit Created(address(0), _contractType, address(_userLeverageProxy), address(0));

        return address(_userLeverageProxy);
    }
}
