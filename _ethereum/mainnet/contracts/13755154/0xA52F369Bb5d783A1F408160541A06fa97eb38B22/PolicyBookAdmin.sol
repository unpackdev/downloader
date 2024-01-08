// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./EnumerableSet.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./Address.sol";

import "./OwnableUpgradeable.sol";

import "./IClaimingRegistry.sol";
import "./IPolicyBookAdmin.sol";
import "./IPolicyBookRegistry.sol";
import "./IContractsRegistry.sol";
import "./IPolicyBook.sol";
import "./ILeveragePortfolio.sol";
import "./IUserLeveragePool.sol";

import "./AbstractDependant.sol";

import "./Upgrader.sol";
import "./Globals.sol";

contract PolicyBookAdmin is IPolicyBookAdmin, OwnableUpgradeable, AbstractDependant {
    using Math for uint256;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IContractsRegistry public contractsRegistry;
    IPolicyBookRegistry public policyBookRegistry;

    Upgrader internal upgrader;
    address private policyBookImplementationAddress;

    // new state variables
    address private policyBookFacadeImplementationAddress;
    address private userLeverageImplementationAddress;

    IClaimingRegistry internal claimingRegistry;
    EnumerableSet.AddressSet private _whitelistedDistributors;
    mapping(address => uint256) public override distributorFees;

    event PolicyBookWhitelisted(address policyBookAddress, bool trigger);
    event DistributorWhitelisted(address distributorAddress, uint256 distributorFee);
    event DistributorBlacklisted(address distributorAddress);
    event UpdatedImageURI(uint256 claimIndex, string oldImageUri, string newImageUri);

    uint256 public constant MAX_DISTRIBUTOR_FEE = 20 * PRECISION;

    /// TODO can't init contract after upgrade , workaround to set policyfacade impl
    function __PolicyBookAdmin_init(
        address _policyBookImplementationAddress,
        address _policyBookFacadeImplementationAddress,
        address _userLeverageImplementationAddress
    ) external initializer {
        require(_policyBookImplementationAddress != address(0), "PBA: PB Zero address");
        require(_policyBookFacadeImplementationAddress != address(0), "PBA: PBF Zero address");
        require(_userLeverageImplementationAddress != address(0), "PBA: PBF Zero address");

        __Ownable_init();

        upgrader = new Upgrader();

        policyBookImplementationAddress = _policyBookImplementationAddress;
        policyBookFacadeImplementationAddress = _policyBookFacadeImplementationAddress;
        userLeverageImplementationAddress = _userLeverageImplementationAddress;
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
        claimingRegistry = IClaimingRegistry(_contractsRegistry.getClaimingRegistryContract());
    }

    function injectDependenciesToExistingPolicies(uint256 offset, uint256 limit)
        external
        onlyOwner
    {
        address[] memory _policies = policyBookRegistry.list(offset, limit);
        IContractsRegistry _contractsRegistry = contractsRegistry;

        uint256 to = (offset.add(limit)).min(_policies.length).max(offset);

        for (uint256 i = offset; i < to; i++) {
            AbstractDependant dependant = AbstractDependant(_policies[i]);

            if (dependant.injector() == address(0)) {
                dependant.setInjector(address(this));
            }

            dependant.setDependencies(_contractsRegistry);
        }
    }

    function getUpgrader() external view override returns (address) {
        require(address(upgrader) != address(0), "PolicyBookAdmin: Bad upgrader");

        return address(upgrader);
    }

    function getImplementationOfPolicyBook(address policyBookAddress)
        external
        override
        returns (address)
    {
        require(
            policyBookRegistry.isPolicyBook(policyBookAddress),
            "PolicyBookAdmin: Not a PolicyBook"
        );

        return upgrader.getImplementation(policyBookAddress);
    }

    function getImplementationOfPolicyBookFacade(address policyBookFacadeAddress)
        external
        override
        returns (address)
    {
        require(
            policyBookRegistry.isPolicyBookFacade(policyBookFacadeAddress),
            "PolicyBookAdmin: Not a PolicyBookFacade"
        );

        return upgrader.getImplementation(policyBookFacadeAddress);
    }

    function getCurrentPolicyBooksImplementation() external view override returns (address) {
        return policyBookImplementationAddress;
    }

    function getCurrentPolicyBooksFacadeImplementation() external view override returns (address) {
        return policyBookFacadeImplementationAddress;
    }

    function getCurrentUserLeverageImplementation() external view override returns (address) {
        return userLeverageImplementationAddress;
    }

    function _setPolicyBookImplementation(address policyBookImpl) internal {
        if (policyBookImplementationAddress != policyBookImpl) {
            policyBookImplementationAddress = policyBookImpl;
        }
    }

    function _setPolicyBookFacadeImplementation(address policyBookFacadeImpl) internal {
        if (policyBookFacadeImplementationAddress != policyBookFacadeImpl) {
            policyBookFacadeImplementationAddress = policyBookFacadeImpl;
        }
    }

    function _setUserLeverageImplementation(address userLeverageImpl) internal {
        if (userLeverageImplementationAddress != userLeverageImpl) {
            userLeverageImplementationAddress = userLeverageImpl;
        }
    }

    function upgradePolicyBooks(
        address policyBookImpl,
        uint256 offset,
        uint256 limit
    ) external onlyOwner {
        _upgradePolicyBooks(policyBookImpl, offset, limit, "");
    }

    /// @notice can only call functions that have no parameters
    function upgradePolicyBooksAndCall(
        address policyBookImpl,
        uint256 offset,
        uint256 limit,
        string calldata functionSignature
    ) external onlyOwner {
        _upgradePolicyBooks(policyBookImpl, offset, limit, functionSignature);
    }

    function _upgradePolicyBooks(
        address policyBookImpl,
        uint256 offset,
        uint256 limit,
        string memory functionSignature
    ) internal {
        require(policyBookImpl != address(0), "PolicyBookAdmin: Zero address");
        require(Address.isContract(policyBookImpl), "PolicyBookAdmin: Invalid address");

        _setPolicyBookImplementation(policyBookImpl);

        address[] memory _policies = policyBookRegistry.list(offset, limit);

        for (uint256 i = 0; i < _policies.length; i++) {
            if (!policyBookRegistry.isUserLeveragePool(_policies[i])) {
                if (bytes(functionSignature).length > 0) {
                    upgrader.upgradeAndCall(
                        _policies[i],
                        policyBookImpl,
                        abi.encodeWithSignature(functionSignature)
                    );
                } else {
                    upgrader.upgrade(_policies[i], policyBookImpl);
                }
            }
        }
    }

    function upgradePolicyBookFacades(
        address policyBookFacadeImpl,
        uint256 offset,
        uint256 limit
    ) external onlyOwner {
        _upgradePolicyBookFacades(policyBookFacadeImpl, offset, limit, "");
    }

    /// @notice can only call functions that have no parameters
    function upgradePolicyBookFacadesAndCall(
        address policyBookFacadeImpl,
        uint256 offset,
        uint256 limit,
        string calldata functionSignature
    ) external onlyOwner {
        _upgradePolicyBookFacades(policyBookFacadeImpl, offset, limit, functionSignature);
    }

    function _upgradePolicyBookFacades(
        address policyBookFacadeImpl,
        uint256 offset,
        uint256 limit,
        string memory functionSignature
    ) internal {
        require(policyBookFacadeImpl != address(0), "PolicyBookAdmin: Zero address");
        require(Address.isContract(policyBookFacadeImpl), "PolicyBookAdmin: Invalid address");

        _setPolicyBookFacadeImplementation(policyBookFacadeImpl);

        address[] memory _policies = policyBookRegistry.list(offset, limit);

        for (uint256 i = 0; i < _policies.length; i++) {
            if (!policyBookRegistry.isUserLeveragePool(_policies[i])) {
                IPolicyBook _policyBook = IPolicyBook(_policies[i]);
                address policyBookFacade =
                    address(IPolicyBookFacade(_policyBook.policyBookFacade()));
                if (bytes(functionSignature).length > 0) {
                    upgrader.upgradeAndCall(
                        policyBookFacade,
                        policyBookFacadeImpl,
                        abi.encodeWithSignature(functionSignature)
                    );
                } else {
                    upgrader.upgrade(policyBookFacade, policyBookFacadeImpl);
                }
            }
        }
    }

    /// TODO refactor all upgrades function in one function
    function upgradeUserLeveragePools(
        address userLeverageImpl,
        uint256 offset,
        uint256 limit
    ) external onlyOwner {
        _upgradeUserLeveragePools(userLeverageImpl, offset, limit, "");
    }

    /// @notice can only call functions that have no parameters
    function upgradeUserLeveragePoolsAndCall(
        address userLeverageImpl,
        uint256 offset,
        uint256 limit,
        string calldata functionSignature
    ) external onlyOwner {
        _upgradeUserLeveragePools(userLeverageImpl, offset, limit, functionSignature);
    }

    function _upgradeUserLeveragePools(
        address userLeverageImpl,
        uint256 offset,
        uint256 limit,
        string memory functionSignature
    ) internal {
        require(userLeverageImpl != address(0), "PolicyBookAdmin: Zero address");
        require(Address.isContract(userLeverageImpl), "PolicyBookAdmin: Invalid address");

        _setUserLeverageImplementation(userLeverageImpl);

        address[] memory _policies =
            policyBookRegistry.listByType(IPolicyBookFabric.ContractType.VARIOUS, offset, limit);

        for (uint256 i = 0; i < _policies.length; i++) {
            if (!policyBookRegistry.isUserLeveragePool(_policies[i])) {
                if (bytes(functionSignature).length > 0) {
                    upgrader.upgradeAndCall(
                        _policies[i],
                        userLeverageImpl,
                        abi.encodeWithSignature(functionSignature)
                    );
                } else {
                    upgrader.upgrade(_policies[i], userLeverageImpl);
                }
            }
        }
    }

    /// @notice It blacklists or whitelists a PolicyBook. Only whitelisted PolicyBooks can
    ///         receive stakes and funds
    /// @param policyBookAddress PolicyBook address that will be whitelisted or blacklisted
    /// @param whitelisted true to whitelist or false to blacklist a PolicyBook
    function whitelist(address policyBookAddress, bool whitelisted) public override onlyOwner {
        require(policyBookRegistry.isPolicyBook(policyBookAddress), "PolicyBookAdmin: Not a PB");

        IPolicyBook(policyBookAddress).whitelist(whitelisted);
        policyBookRegistry.whitelist(policyBookAddress, whitelisted);

        emit PolicyBookWhitelisted(policyBookAddress, whitelisted);
    }

    /// @notice Whitelist distributor address and respective fees
    /// @param _distributor distributor address that will receive funds
    /// @param _distributorFee distributor fee amount (passed with its precision : _distributorFee * 10**25)
    function whitelistDistributor(address _distributor, uint256 _distributorFee)
        external
        override
        onlyOwner
    {
        require(_distributor != address(0), "PBAdmin: Null is forbidden");
        require(_distributorFee > 0, "PBAdmin: Fee cannot be 0");

        require(_distributorFee <= MAX_DISTRIBUTOR_FEE, "PBAdmin: Fee is over max cap");

        _whitelistedDistributors.add(_distributor);
        distributorFees[_distributor] = _distributorFee;

        emit DistributorWhitelisted(_distributor, _distributorFee);
    }

    /// @notice Removes a distributor address from the distributor whitelist
    /// @param _distributor distributor address that will be blacklist
    function blacklistDistributor(address _distributor) external override onlyOwner {
        _whitelistedDistributors.remove(_distributor);
        delete distributorFees[_distributor];

        emit DistributorBlacklisted(_distributor);
    }

    /// @notice Distributor commission fee is 2-5% of the Premium.
    ///         It comes from the Protocol’s fee part
    /// @param _distributor address of the distributor
    /// @return true if address is a whitelisted distributor
    function isWhitelistedDistributor(address _distributor) external view override returns (bool) {
        return _whitelistedDistributors.contains(_distributor);
    }

    function listDistributors(uint256 offset, uint256 limit)
        external
        view
        override
        returns (address[] memory _distributors, uint256[] memory _distributorsFees)
    {
        return _listDistributors(offset, limit, _whitelistedDistributors);
    }

    /// @notice Used to get a list of whitelisted distributors
    /// @return _distributors a list containing distritubors addresses
    /// @return _distributorsFees a list containing distritubors fees
    function _listDistributors(
        uint256 offset,
        uint256 limit,
        EnumerableSet.AddressSet storage set
    ) internal view returns (address[] memory _distributors, uint256[] memory _distributorsFees) {
        uint256 to = (offset.add(limit)).min(set.length()).max(offset);

        _distributors = new address[](to - offset);
        _distributorsFees = new uint256[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            _distributors[i - offset] = set.at(i);
            _distributorsFees[i - offset] = distributorFees[_distributors[i]];
        }
    }

    function countDistributors() external view override returns (uint256) {
        return _whitelistedDistributors.length();
    }

    function whitelistBatch(address[] calldata policyBooksAddresses, bool[] calldata whitelists)
        external
        onlyOwner
    {
        require(
            policyBooksAddresses.length == whitelists.length,
            "PolicyBookAdmin: Length mismatch"
        );

        for (uint256 i = 0; i < policyBooksAddresses.length; i++) {
            whitelist(policyBooksAddresses[i], whitelists[i]);
        }
    }

    /// @notice Update Image Uri in case it contains material that is ilegal
    ///         or offensive.
    /// @dev Only the owner can erase/update evidenceUri.
    /// @param _claimIndex Claim Index that is going to be updated
    /// @param _newEvidenceURI New evidence uri. It can be blank.
    function updateImageUriOfClaim(uint256 _claimIndex, string calldata _newEvidenceURI)
        public
        onlyOwner
    {
        IClaimingRegistry.ClaimInfo memory claimInfo = claimingRegistry.claimInfo(_claimIndex);
        string memory oldEvidenceURI = claimInfo.evidenceURI;

        claimingRegistry.updateImageUriOfClaim(_claimIndex, _newEvidenceURI);

        emit UpdatedImageURI(_claimIndex, oldEvidenceURI, _newEvidenceURI);
    }

    /// @notice sets the policybookFacade mpls values
    /// @param _facadeAddress address of the policybook facade
    /// @param _userLeverageMPL uint256 value of the user leverage mpl;
    /// @param _reinsuranceLeverageMPL uint256 value of the reinsurance leverage mpl
    function setPolicyBookFacadeMPLs(
        address _facadeAddress,
        uint256 _userLeverageMPL,
        uint256 _reinsuranceLeverageMPL
    ) external override onlyOwner {
        IPolicyBookFacade(_facadeAddress).setMPLs(_userLeverageMPL, _reinsuranceLeverageMPL);
    }

    /// @notice sets the policybookFacade mpls values
    /// @param _facadeAddress address of the policybook facade
    /// @param _newRebalancingThreshold uint256 value of the reinsurance leverage mpl
    function setPolicyBookFacadeRebalancingThreshold(
        address _facadeAddress,
        uint256 _newRebalancingThreshold
    ) external override onlyOwner {
        IPolicyBookFacade(_facadeAddress).setRebalancingThreshold(_newRebalancingThreshold);
    }

    /// @notice sets the policybookFacade mpls values
    /// @param _facadeAddress address of the policybook facade
    /// @param _safePricingModel bool is pricing model safe (true) or not (false)
    function setPolicyBookFacadeSafePricingModel(address _facadeAddress, bool _safePricingModel)
        external
        override
        onlyOwner
    {
        IPolicyBookFacade(_facadeAddress).setSafePricingModel(_safePricingModel);
    }

    /// @notice sets the user leverage pool Rebalancing Threshold
    /// @param _LeveragePoolAddress address of the policybook facade
    /// @param _newRebalancingThreshold uint256 value of Rebalancing Threshold
    function setLeveragePortfolioRebalancingThreshold(
        address _LeveragePoolAddress,
        uint256 _newRebalancingThreshold
    ) external override onlyOwner {
        ILeveragePortfolio(_LeveragePoolAddress).setRebalancingThreshold(_newRebalancingThreshold);
    }

    function setLeveragePortfolioProtocolConstant(
        address _LeveragePoolAddress,
        uint256 _targetUR,
        uint256 _d_ProtocolConstant,
        uint256 _a_ProtocolConstant,
        uint256 _max_ProtocolConstant
    ) external override onlyOwner {
        ILeveragePortfolio(_LeveragePoolAddress).setProtocolConstant(
            _targetUR,
            _d_ProtocolConstant,
            _a_ProtocolConstant,
            _max_ProtocolConstant
        );
    }

    function setUserLeverageMaxCapacities(address _userLeverageAddress, uint256 _maxCapacities)
        external
        override
        onlyOwner
    {
        IUserLeveragePool(_userLeverageAddress).setMaxCapacities(_maxCapacities);
    }
}
