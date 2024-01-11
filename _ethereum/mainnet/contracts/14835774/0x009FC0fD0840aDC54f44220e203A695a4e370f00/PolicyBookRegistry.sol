// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./EnumerableSet.sol";
import "./Math.sol";
import "./SafeMath.sol";

import "./IPolicyBook.sol";
import "./IPolicyBookFacade.sol";
import "./IPolicyBookRegistry.sol";
import "./IContractsRegistry.sol";

import "./AbstractDependant.sol";

contract PolicyBookRegistry is IPolicyBookRegistry, AbstractDependant {
    using Math for uint256;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public policyBookFabricAddress;
    address public policyBookAdminAddress;

    // insured contract address => proxy address
    mapping(address => address) public override policyBooksByInsuredAddress;
    mapping(address => address) public override policyBookFacades;

    EnumerableSet.AddressSet internal _policyBooks;
    mapping(IPolicyBookFabric.ContractType => EnumerableSet.AddressSet)
        internal _policyBooksByType;

    EnumerableSet.AddressSet internal _whitelistedPolicyBooks;
    mapping(IPolicyBookFabric.ContractType => EnumerableSet.AddressSet)
        internal _whitelistedPolicyBooksByType;

    event Added(address insured, address at);

    modifier onlyPolicyBookFabric() {
        require(
            msg.sender == policyBookFabricAddress,
            "PolicyBookRegistry: Not a PolicyBookFabric"
        );
        _;
    }

    modifier onlyPolicyBookAdmin() {
        require(msg.sender == policyBookAdminAddress, "PolicyBookRegistry: Not a PolicyBookAdmin");
        _;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        policyBookFabricAddress = _contractsRegistry.getPolicyBookFabricContract();
        policyBookAdminAddress = _contractsRegistry.getPolicyBookAdminContract();
    }

    function add(
        address insuredContract,
        IPolicyBookFabric.ContractType contractType,
        address policyBook,
        address facadeAddress
    ) external override onlyPolicyBookFabric {
        require(policyBook != address(0), "PolicyBookRegistry: No PB at address zero");
        require(
            policyBooksByInsuredAddress[insuredContract] == address(0),
            "PolicyBookRegistry: PolicyBook for the contract is already created"
        );

        policyBooksByInsuredAddress[insuredContract] = policyBook;
        policyBookFacades[facadeAddress] = policyBook;

        _policyBooks.add(policyBook);
        _policyBooksByType[contractType].add(policyBook);

        emit Added(insuredContract, policyBook);
    }

    function whitelist(address policyBookAddress, bool whitelisted)
        external
        override
        onlyPolicyBookAdmin
    {
        IPolicyBookFabric.ContractType contractType =
            IPolicyBook(policyBookAddress).contractType();

        if (whitelisted) {
            _whitelistedPolicyBooks.add(policyBookAddress);
            _whitelistedPolicyBooksByType[contractType].add(policyBookAddress);
        } else {
            _whitelistedPolicyBooks.remove(policyBookAddress);
            _whitelistedPolicyBooksByType[contractType].remove(policyBookAddress);
        }
    }

    function getPoliciesPrices(
        address[] calldata policyBooks,
        uint256[] calldata epochsNumbers,
        uint256[] calldata coversTokens
    ) external view override returns (uint256[] memory _durations, uint256[] memory _allowances) {
        require(
            policyBooks.length == epochsNumbers.length &&
                policyBooks.length == coversTokens.length,
            "PolicyBookRegistry: Lengths mismatch"
        );

        _durations = new uint256[](policyBooks.length);
        _allowances = new uint256[](policyBooks.length);

        for (uint256 i = 0; i < policyBooks.length; i++) {
            require(
                isPolicyBook(policyBooks[i]) && !isUserLeveragePool(policyBooks[i]),
                "PolicyBookRegistry: Not a PolicyBook"
            );

            (_durations[i], _allowances[i], ) = IPolicyBookFacade(
                IPolicyBook(policyBooks[i]).policyBookFacade()
            )
                .getPolicyPrice(epochsNumbers[i], coversTokens[i], msg.sender);
        }
    }

    function buyPolicyBatch(
        address[] calldata policyBooks,
        uint256[] calldata epochsNumbers,
        uint256[] calldata coversTokens
    ) external override {
        require(
            policyBooks.length == epochsNumbers.length &&
                policyBooks.length == coversTokens.length,
            "PolicyBookRegistry: Lengths mismatch"
        );

        for (uint256 i = 0; i < policyBooks.length; i++) {
            require(
                isPolicyBook(policyBooks[i]) && !isUserLeveragePool(policyBooks[i]),
                "PolicyBookRegistry: Not a PolicyBook"
            );

            IPolicyBook(policyBooks[i]).policyBookFacade().buyPolicyFor(
                msg.sender,
                epochsNumbers[i],
                coversTokens[i]
            );
        }
    }

    function isPolicyBook(address policyBook) public view override returns (bool) {
        return _policyBooks.contains(policyBook);
    }

    function isPolicyBookFacade(address _facadeAddress) public view override returns (bool) {
        address _policyBookAddress = policyBookFacades[_facadeAddress];
        return isPolicyBook(_policyBookAddress);
    }

    function isUserLeveragePool(address policyBookAddress) public view override returns (bool) {
        bool _isLeveragePool;
        if (_policyBooks.contains(policyBookAddress)) {
            _isLeveragePool = (IPolicyBook(policyBookAddress).contractType() ==
                IPolicyBookFabric.ContractType.VARIOUS);
        }
        return _isLeveragePool;
    }

    function countByType(IPolicyBookFabric.ContractType contractType)
        external
        view
        override
        returns (uint256)
    {
        return _policyBooksByType[contractType].length();
    }

    function count() external view override returns (uint256) {
        return _policyBooks.length();
    }

    function countByTypeWhitelisted(IPolicyBookFabric.ContractType contractType)
        external
        view
        override
        returns (uint256)
    {
        return _whitelistedPolicyBooksByType[contractType].length();
    }

    function countWhitelisted() external view override returns (uint256) {
        return _whitelistedPolicyBooks.length();
    }

    /// @notice use with countByType()
    function listByType(
        IPolicyBookFabric.ContractType contractType,
        uint256 offset,
        uint256 limit
    ) public view override returns (address[] memory _policyBooksArr) {
        return _listByType(contractType, offset, limit, _policyBooksByType);
    }

    /// @notice use with count()
    function list(uint256 offset, uint256 limit)
        public
        view
        override
        returns (address[] memory _policyBooksArr)
    {
        return _list(offset, limit, _policyBooks);
    }

    /// @notice use with countByTypeWhitelisted()
    function listByTypeWhitelisted(
        IPolicyBookFabric.ContractType contractType,
        uint256 offset,
        uint256 limit
    ) public view override returns (address[] memory _policyBooksArr) {
        return _listByType(contractType, offset, limit, _whitelistedPolicyBooksByType);
    }

    /// @notice use with countWhitelisted()
    function listWhitelisted(uint256 offset, uint256 limit)
        public
        view
        override
        returns (address[] memory _policyBooksArr)
    {
        return _list(offset, limit, _whitelistedPolicyBooks);
    }

    function listWithStatsByType(
        IPolicyBookFabric.ContractType contractType,
        uint256 offset,
        uint256 limit
    )
        external
        view
        override
        returns (address[] memory _policyBooksArr, PolicyBookStats[] memory _stats)
    {
        _policyBooksArr = listByType(contractType, offset, limit);
        _stats = stats(_policyBooksArr);
    }

    function listWithStats(uint256 offset, uint256 limit)
        external
        view
        override
        returns (address[] memory _policyBooksArr, PolicyBookStats[] memory _stats)
    {
        _policyBooksArr = list(offset, limit);
        _stats = stats(_policyBooksArr);
    }

    function listWithStatsByTypeWhitelisted(
        IPolicyBookFabric.ContractType contractType,
        uint256 offset,
        uint256 limit
    )
        external
        view
        override
        returns (address[] memory _policyBooksArr, PolicyBookStats[] memory _stats)
    {
        _policyBooksArr = listByTypeWhitelisted(contractType, offset, limit);
        _stats = stats(_policyBooksArr);
    }

    function listWithStatsWhitelisted(uint256 offset, uint256 limit)
        external
        view
        override
        returns (address[] memory _policyBooksArr, PolicyBookStats[] memory _stats)
    {
        _policyBooksArr = listWhitelisted(offset, limit);
        _stats = stats(_policyBooksArr);
    }

    function _listByType(
        IPolicyBookFabric.ContractType contractType,
        uint256 offset,
        uint256 limit,
        mapping(IPolicyBookFabric.ContractType => EnumerableSet.AddressSet) storage map
    ) internal view returns (address[] memory _policyBooksArr) {
        uint256 to = (offset.add(limit)).min(map[contractType].length()).max(offset);

        _policyBooksArr = new address[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            _policyBooksArr[i - offset] = map[contractType].at(i);
        }
    }

    function _list(
        uint256 offset,
        uint256 limit,
        EnumerableSet.AddressSet storage set
    ) internal view returns (address[] memory _policyBooksArr) {
        uint256 to = (offset.add(limit)).min(set.length()).max(offset);

        _policyBooksArr = new address[](to - offset);

        for (uint256 i = offset; i < to; i++) {
            _policyBooksArr[i - offset] = set.at(i);
        }
    }

    function stats(address[] memory policyBooks)
        public
        view
        override
        returns (PolicyBookStats[] memory _stats)
    {
        _stats = new PolicyBookStats[](policyBooks.length);

        for (uint256 i = 0; i < policyBooks.length; i++) {
            address policyBookAddress;
            if (isUserLeveragePool(policyBooks[i])) {
                policyBookAddress = policyBooks[i];
            } else {
                policyBookAddress = address(IPolicyBook(policyBooks[i]).policyBookFacade());
            }
            (
                _stats[i].symbol,
                _stats[i].insuredContract,
                _stats[i].contractType,
                _stats[i].whitelisted
            ) = IPolicyBookFacade(policyBookAddress).info();

            (
                _stats[i].maxCapacity,
                ,
                _stats[i].totalSTBLLiquidity,
                _stats[i].totalLeveragedLiquidity,
                _stats[i].stakedSTBL,
                _stats[i].APY,
                _stats[i].annualInsuranceCost,
                _stats[i].bmiXRatio
            ) = IPolicyBook(policyBooks[i]).numberStats();
        }
    }

    function policyBookFor(address insuredContract) external view override returns (address) {
        return policyBooksByInsuredAddress[insuredContract];
    }

    function statsByInsuredContracts(address[] calldata insuredContracts)
        external
        view
        override
        returns (PolicyBookStats[] memory _stats)
    {
        _stats = new PolicyBookStats[](insuredContracts.length);

        for (uint256 i = 0; i < insuredContracts.length; i++) {
            (
                _stats[i].symbol,
                _stats[i].insuredContract,
                _stats[i].contractType,
                _stats[i].whitelisted
            ) = IPolicyBookFacade(
                IPolicyBook(policyBooksByInsuredAddress[insuredContracts[i]]).policyBookFacade()
            )
                .info();

            (
                _stats[i].maxCapacity,
                ,
                _stats[i].totalSTBLLiquidity,
                _stats[i].totalLeveragedLiquidity,
                _stats[i].stakedSTBL,
                _stats[i].APY,
                _stats[i].annualInsuranceCost,
                _stats[i].bmiXRatio
            ) = IPolicyBook(policyBooksByInsuredAddress[insuredContracts[i]]).numberStats();
        }
    }
}
