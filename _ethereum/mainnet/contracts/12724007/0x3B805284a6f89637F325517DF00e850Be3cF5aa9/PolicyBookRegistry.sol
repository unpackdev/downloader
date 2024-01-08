// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./EnumerableSet.sol";
import "./Math.sol";
import "./SafeMath.sol";

import "./IPolicyBook.sol";
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
    mapping(address => address) public policyBooksByInsuredAddress;

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
        address policyBook
    ) external override onlyPolicyBookFabric {
        require(
            policyBooksByInsuredAddress[insuredContract] == address(0),
            "PolicyBookRegistry: PolicyBook for the contract is already created"
        );

        policyBooksByInsuredAddress[insuredContract] = policyBook;

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
            require(isPolicyBook(policyBooks[i]), "PolicyBookRegistry: Not a PolicyBook");

            (_durations[i], _allowances[i]) = IPolicyBook(policyBooks[i]).getPolicyPrice(
                epochsNumbers[i],
                coversTokens[i]
            );
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
            require(isPolicyBook(policyBooks[i]), "PolicyBookRegistry: Not a PolicyBook");

            IPolicyBook(policyBooks[i]).buyPolicyFor(
                msg.sender,
                epochsNumbers[i],
                coversTokens[i]
            );
        }
    }

    function isPolicyBook(address policyBook) public view override returns (bool) {
        return _policyBooks.contains(policyBook);
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
            (
                _stats[i].symbol,
                _stats[i].insuredContract,
                _stats[i].contractType,
                _stats[i].whitelisted
            ) = IPolicyBook(policyBooks[i]).info();

            (
                _stats[i].maxCapacity,
                _stats[i].totalDaiLiquidity,
                _stats[i].stakedDAI,
                _stats[i].APY,
                _stats[i].annualInsuranceCost,
                _stats[i].bmiDaiRatio
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
            ) = IPolicyBook(policyBooksByInsuredAddress[insuredContracts[i]]).info();

            (
                _stats[i].maxCapacity,
                _stats[i].totalDaiLiquidity,
                _stats[i].stakedDAI,
                _stats[i].APY,
                _stats[i].annualInsuranceCost,
                _stats[i].bmiDaiRatio
            ) = IPolicyBook(policyBooksByInsuredAddress[insuredContracts[i]]).numberStats();
        }
    }
}
