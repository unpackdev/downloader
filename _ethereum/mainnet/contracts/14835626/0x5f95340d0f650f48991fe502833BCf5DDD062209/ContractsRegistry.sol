// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./AccessControlUpgradeable.sol";
import "./TransparentUpgradeableProxy.sol";

import "./IContractsRegistry.sol";

import "./AbstractDependant.sol";

import "./Upgrader.sol";

contract ContractsRegistry is IContractsRegistry, AccessControlUpgradeable {
    Upgrader internal upgrader;

    mapping(bytes32 => address) private _contracts;
    mapping(address => bool) private _isProxy;

    bytes32 public constant REGISTRY_ADMIN_ROLE = keccak256("REGISTRY_ADMIN_ROLE");

    bytes32 public constant AMM_ROUTER_NAME = keccak256("AMM_ROUTER");
    bytes32 public constant AMM_BMI_TO_ETH_PAIR_NAME = keccak256("AMM_BMI_ETH_PAIR");
    bytes32 public constant AMM_BMI_TO_USDT_PAIR_NAME = keccak256("AMM_BMI_USDT_PAIR");

    bytes32 public constant SUSHI_SWAP_MASTER_CHEF_V2_NAME =
        keccak256("SUSHI_SWAP_MASTER_CHEF_V2");

    bytes32 public constant PRICE_FEED_NAME = keccak256("PRICE_FEED");

    bytes32 public constant POLICY_BOOK_REGISTRY_NAME = keccak256("BOOK_REGISTRY");
    bytes32 public constant POLICY_BOOK_FABRIC_NAME = keccak256("FABRIC");
    bytes32 public constant POLICY_BOOK_ADMIN_NAME = keccak256("POLICY_BOOK_ADMIN");

    bytes32 public constant BMI_STAKING_NAME = keccak256("BMI_STAKING");
    bytes32 public constant STKBMI_STAKING_NAME = keccak256("STKBMI_STAKING");

    bytes32 public constant BMI_COVER_STAKING_NAME = keccak256("BMI_COVER_STAKING");
    bytes32 public constant BMI_COVER_STAKING_VIEW_NAME = keccak256("BMI_COVER_STAKING_VIEW");
    bytes32 public constant BMI_TREASURY_NAME = keccak256("BMI_TREASURY");
    bytes32 public constant REWARDS_GENERATOR_NAME = keccak256("REWARDS_GENERATOR");

    bytes32 public constant WRAPPEDTOKEN_NAME = keccak256("WRAPPEDTOKEN");
    bytes32 public constant USDT_NAME = keccak256("USDT");
    bytes32 public constant BMI_NAME = keccak256("BMI");
    bytes32 public constant STKBMI_NAME = keccak256("STK_BMI");
    bytes32 public constant VBMI_NAME = keccak256("VBMI");

    bytes32 public constant BMI_UTILITY_NFT_NAME = keccak256("BMI_UTILITY_NFT");
    bytes32 public constant NFT_STAKING_NAME = keccak256("NFT_STAKING");

    bytes32 public constant LIQUIDITY_MINING_STAKING_ETH_NAME = keccak256("LIQ_MINING_STAKING");
    bytes32 public constant LIQUIDITY_MINING_STAKING_USDT_NAME =
        keccak256("LIQ_MINING_STAKING_USDT");

    bytes32 public constant LIQUIDITY_REGISTRY_NAME = keccak256("LIQUIDITY_REGISTRY");
    bytes32 public constant POLICY_REGISTRY_NAME = keccak256("POLICY_REGISTRY");
    bytes32 public constant POLICY_QUOTE_NAME = keccak256("POLICY_QUOTE");

    bytes32 public constant CLAIMING_REGISTRY_NAME = keccak256("CLAIMING_REGISTRY");
    bytes32 public constant CLAIM_VOTING_NAME = keccak256("CLAIM_VOTING");
    bytes32 public constant REPUTATION_SYSTEM_NAME = keccak256("REPUTATION_SYSTEM");
    bytes32 public constant REINSURANCE_POOL_NAME = keccak256("REINSURANCE_POOL");
    bytes32 public constant LEVERAGE_PORTFOLIO_VIEW_NAME = keccak256("LEVERAGE_PORTFOLIO_VIEW");
    bytes32 public constant CAPITAL_POOL_NAME = keccak256("CAPITAL_POOL");
    bytes32 public constant YIELD_GENERATOR_NAME = keccak256("YIELD_GENERATOR");

    bytes32 public constant DEFI_PROTOCOL_1_NAME = keccak256("DEFI_PROTOCOL_1");
    bytes32 public constant AAVE_LENDPOOL_ADDRESS_PROVIDER_NAME =
        keccak256("AAVE_LENDPOOL_ADDRESS_PROVIDER_NAME");
    bytes32 public constant AAVE_ATOKEN_NAME = keccak256("AAVE_ATOKEN");

    bytes32 public constant DEFI_PROTOCOL_2_NAME = keccak256("DEFI_PROTOCOL_2");
    bytes32 public constant COMPOUND_CTOKEN_NAME = keccak256("COMPOUND_CTOKEN");
    bytes32 public constant COMPOUND_COMPTROLLER_NAME = keccak256("COMPOUND_COMPTROLLER");

    bytes32 public constant DEFI_PROTOCOL_3_NAME = keccak256("DEFI_PROTOCOL_3");
    bytes32 public constant YEARN_VAULT_NAME = keccak256("YEARN_VAULT");

    bytes32 public constant SHIELD_MINING_NAME = keccak256("SHIELD_MINING");
    bytes32 public constant LIQUIDITY_BRIDGE_NAME = keccak256("LIQUIDITY_BRIDGE");

    modifier onlyAdmin() {
        require(
            hasRole(REGISTRY_ADMIN_ROLE, msg.sender),
            "ContractsRegistry: Caller is not an admin"
        );
        _;
    }

    function __ContractsRegistry_init() external initializer {
        __AccessControl_init();

        _setupRole(REGISTRY_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(REGISTRY_ADMIN_ROLE, REGISTRY_ADMIN_ROLE);

        upgrader = new Upgrader();
    }

    function getAMMRouterContract() external view override returns (address) {
        return getContract(AMM_ROUTER_NAME);
    }

    function getAMMBMIToETHPairContract() external view override returns (address) {
        return getContract(AMM_BMI_TO_ETH_PAIR_NAME);
    }

    function getAMMBMIToUSDTPairContract() external view override returns (address) {
        return getContract(AMM_BMI_TO_USDT_PAIR_NAME);
    }

    function getSushiSwapMasterChefV2Contract() external view override returns (address) {
        return getContract(SUSHI_SWAP_MASTER_CHEF_V2_NAME);
    }

    function getWrappedTokenContract() external view override returns (address) {
        return getContract(WRAPPEDTOKEN_NAME);
    }

    function getUSDTContract() external view override returns (address) {
        return getContract(USDT_NAME);
    }

    function getBMIContract() external view override returns (address) {
        return getContract(BMI_NAME);
    }

    function getPriceFeedContract() external view override returns (address) {
        return getContract(PRICE_FEED_NAME);
    }

    function getPolicyBookRegistryContract() external view override returns (address) {
        return getContract(POLICY_BOOK_REGISTRY_NAME);
    }

    function getPolicyBookFabricContract() external view override returns (address) {
        return getContract(POLICY_BOOK_FABRIC_NAME);
    }

    function getBMICoverStakingContract() external view override returns (address) {
        return getContract(BMI_COVER_STAKING_NAME);
    }

    function getBMICoverStakingViewContract() external view override returns (address) {
        return getContract(BMI_COVER_STAKING_VIEW_NAME);
    }

    function getBMITreasury() external view override returns (address) {
        return getContract(BMI_TREASURY_NAME);
    }

    function getRewardsGeneratorContract() external view override returns (address) {
        return getContract(REWARDS_GENERATOR_NAME);
    }

    function getBMIUtilityNFTContract() external view override returns (address) {
        return getContract(BMI_UTILITY_NFT_NAME);
    }

    function getNFTStakingContract() external view override returns (address) {
        return getContract(NFT_STAKING_NAME);
    }

    function getLiquidityBridgeContract() external view override returns (address) {
        return getContract(LIQUIDITY_BRIDGE_NAME);
    }

    function getClaimingRegistryContract() external view override returns (address) {
        return getContract(CLAIMING_REGISTRY_NAME);
    }

    function getPolicyRegistryContract() external view override returns (address) {
        return getContract(POLICY_REGISTRY_NAME);
    }

    function getLiquidityRegistryContract() external view override returns (address) {
        return getContract(LIQUIDITY_REGISTRY_NAME);
    }

    function getClaimVotingContract() external view override returns (address) {
        return getContract(CLAIM_VOTING_NAME);
    }

    function getReputationSystemContract() external view override returns (address) {
        return getContract(REPUTATION_SYSTEM_NAME);
    }

    function getReinsurancePoolContract() external view override returns (address) {
        return getContract(REINSURANCE_POOL_NAME);
    }

    function getLeveragePortfolioViewContract() external view override returns (address) {
        return getContract(LEVERAGE_PORTFOLIO_VIEW_NAME);
    }

    function getYieldGeneratorContract() external view override returns (address) {
        return getContract(YIELD_GENERATOR_NAME);
    }

    function getCapitalPoolContract() external view override returns (address) {
        return getContract(CAPITAL_POOL_NAME);
    }

    function getPolicyBookAdminContract() external view override returns (address) {
        return getContract(POLICY_BOOK_ADMIN_NAME);
    }

    function getPolicyQuoteContract() external view override returns (address) {
        return getContract(POLICY_QUOTE_NAME);
    }

    function getBMIStakingContract() external view override returns (address) {
        return getContract(BMI_STAKING_NAME);
    }

    function getStkBMIStakingContract() external view override returns (address) {
        return getContract(STKBMI_STAKING_NAME);
    }

    function getSTKBMIContract() external view override returns (address) {
        return getContract(STKBMI_NAME);
    }

    function getLiquidityMiningStakingETHContract() external view override returns (address) {
        return getContract(LIQUIDITY_MINING_STAKING_ETH_NAME);
    }

    function getLiquidityMiningStakingUSDTContract() external view override returns (address) {
        return getContract(LIQUIDITY_MINING_STAKING_USDT_NAME);
    }

    function getVBMIContract() external view override returns (address) {
        return getContract(VBMI_NAME);
    }

    function getDefiProtocol1Contract() external view override returns (address) {
        return getContract(DEFI_PROTOCOL_1_NAME);
    }

    function getAaveLendPoolAddressProvdierContract() external view override returns (address) {
        return getContract(AAVE_LENDPOOL_ADDRESS_PROVIDER_NAME);
    }

    function getAaveATokenContract() external view override returns (address) {
        return getContract(AAVE_ATOKEN_NAME);
    }

    function getDefiProtocol2Contract() external view override returns (address) {
        return getContract(DEFI_PROTOCOL_2_NAME);
    }

    function getCompoundCTokenContract() external view override returns (address) {
        return getContract(COMPOUND_CTOKEN_NAME);
    }

    function getCompoundComptrollerContract() external view override returns (address) {
        return getContract(COMPOUND_COMPTROLLER_NAME);
    }

    function getDefiProtocol3Contract() external view override returns (address) {
        return getContract(DEFI_PROTOCOL_3_NAME);
    }

    function getYearnVaultContract() external view override returns (address) {
        return getContract(YEARN_VAULT_NAME);
    }

    function getShieldMiningContract() external view override returns (address) {
        return getContract(SHIELD_MINING_NAME);
    }

    function getContract(bytes32 name) public view returns (address) {
        require(_contracts[name] != address(0), "CR.getContract: This mapping doesn't exist");

        return _contracts[name];
    }

    function hasContract(bytes32 name) external view returns (bool) {
        return _contracts[name] != address(0);
    }

    function injectDependencies(bytes32 name) external onlyAdmin {
        address contractAddress = _contracts[name];

        require(
            contractAddress != address(0),
            "CR.injectDependencies: This mapping doesn't exist"
        );

        AbstractDependant dependant = AbstractDependant(contractAddress);

        if (dependant.injector() == address(0)) {
            dependant.setInjector(address(this));
        }

        dependant.setDependencies(this);
    }

    function getUpgrader() external view returns (address) {
        require(address(upgrader) != address(0), "ContractsRegistry: Bad upgrader");

        return address(upgrader);
    }

    function getImplementation(bytes32 name) external returns (address) {
        address contractProxy = _contracts[name];

        require(contractProxy != address(0), "CR.getImplementation: This mapping doesn't exist");
        require(_isProxy[contractProxy], "ContractsRegistry: Not a proxy contract");

        return upgrader.getImplementation(contractProxy);
    }

    function upgradeContract(bytes32 name, address newImplementation) external onlyAdmin {
        _upgradeContract(name, newImplementation, "");
    }

    /// @notice can only call functions that have no parameters
    function upgradeContractAndCall(
        bytes32 name,
        address newImplementation,
        string calldata functionSignature
    ) external onlyAdmin {
        _upgradeContract(name, newImplementation, functionSignature);
    }

    function _upgradeContract(
        bytes32 name,
        address newImplementation,
        string memory functionSignature
    ) internal {
        address contractToUpgrade = _contracts[name];

        require(
            contractToUpgrade != address(0),
            "CR._upgradeContract: This mapping doesn't exist"
        );
        require(_isProxy[contractToUpgrade], "ContractsRegistry: Not a proxy contract");

        if (bytes(functionSignature).length > 0) {
            upgrader.upgradeAndCall(
                contractToUpgrade,
                newImplementation,
                abi.encodeWithSignature(functionSignature)
            );
        } else {
            upgrader.upgrade(contractToUpgrade, newImplementation);
        }
    }

    function addContract(bytes32 name, address contractAddress) external onlyAdmin {
        require(contractAddress != address(0), "ContractsRegistry: Null address is forbidden");

        _contracts[name] = contractAddress;
    }

    function addProxyContract(bytes32 name, address contractAddress) external onlyAdmin {
        require(contractAddress != address(0), "ContractsRegistry: Null address is forbidden");

        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(contractAddress, address(upgrader), "");

        _contracts[name] = address(proxy);
        _isProxy[address(proxy)] = true;
    }

    function justAddProxyContract(bytes32 name, address contractAddress) external onlyAdmin {
        require(contractAddress != address(0), "ContractsRegistry: Null address is forbidden");

        _contracts[name] = contractAddress;
        _isProxy[contractAddress] = true;
    }

    function deleteContract(bytes32 name) external onlyAdmin {
        require(_contracts[name] != address(0), "CR.deleteContract: This mapping doesn't exist");

        delete _isProxy[_contracts[name]];
        delete _contracts[name];
    }
}
