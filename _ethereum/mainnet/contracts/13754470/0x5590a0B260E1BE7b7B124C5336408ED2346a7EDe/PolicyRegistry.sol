// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./Math.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";

import "./IContractsRegistry.sol";
import "./IPolicyBookRegistry.sol";
import "./IPolicyRegistry.sol";
import "./IClaimingRegistry.sol";
import "./IPolicyBook.sol";

import "./AbstractDependant.sol";

contract PolicyRegistry is IPolicyRegistry, AbstractDependant {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;
    using Math for uint256;

    IPolicyBookRegistry public policyBookRegistry;
    IClaimingRegistry public claimingRegistry;

    uint256 public constant override STILL_CLAIMABLE_FOR = 1 weeks;

    // User address => policy books array
    mapping(address => EnumerableSet.AddressSet) private _policies;

    // User address => policy book address
    mapping(address => mapping(address => PolicyInfo)) public policyInfos;

    event PolicyAdded(address _userAddr, address _policyBook, uint256 _coverAmount);
    event PolicyRemoved(address _userAddr, address _policyBook);

    modifier onlyPolicyBooks() {
        require(
            policyBookRegistry.isPolicyBook(msg.sender),
            "PolicyRegistry: The caller does not have access"
        );
        _;
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        policyBookRegistry = IPolicyBookRegistry(
            _contractsRegistry.getPolicyBookRegistryContract()
        );
        claimingRegistry = IClaimingRegistry(_contractsRegistry.getClaimingRegistryContract());
    }

    function getPoliciesLength(address _userAddr) external view override returns (uint256) {
        return _policies[_userAddr].length();
    }

    function policyExists(address _userAddr, address _policyBookAddr)
        external
        view
        override
        returns (bool)
    {
        return _policies[_userAddr].contains(_policyBookAddr);
    }

    function isPolicyActive(address _userAddr, address _policyBookAddr)
        public
        view
        override
        returns (bool)
    {
        uint256 endTime = policyInfos[_userAddr][_policyBookAddr].endTime;

        return endTime == 0 ? false : endTime.add(STILL_CLAIMABLE_FOR) > block.timestamp;
    }

    function policyStartTime(address _userAddr, address _policyBookAddr)
        public
        view
        override
        returns (uint256)
    {
        return policyInfos[_userAddr][_policyBookAddr].startTime;
    }

    function policyEndTime(address _userAddr, address _policyBookAddr)
        public
        view
        override
        returns (uint256)
    {
        return policyInfos[_userAddr][_policyBookAddr].endTime;
    }

    /// @dev use with getPoliciesLength()
    function getPoliciesInfo(
        address _userAddr,
        bool _isActive,
        uint256 _offset,
        uint256 _limit
    )
        external
        view
        override
        returns (
            uint256 _policiesCount,
            address[] memory _policyBooksArr,
            PolicyInfo[] memory _policiesArr,
            IClaimingRegistry.ClaimStatus[] memory _policyStatuses
        )
    {
        EnumerableSet.AddressSet storage _totalPolicyBooksArr = _policies[_userAddr];

        uint256 to = (_offset.add(_limit)).min(_totalPolicyBooksArr.length()).max(_offset);
        uint256 size = to - _offset;

        _policyBooksArr = new address[](size);
        _policiesArr = new PolicyInfo[](size);
        _policyStatuses = new IClaimingRegistry.ClaimStatus[](size);

        for (uint256 i = _offset; i < to; i++) {
            address _currentPolicyBookAddress = _totalPolicyBooksArr.at(i);

            if (_isActive && isPolicyActive(_userAddr, _currentPolicyBookAddress)) {
                _policiesArr[_policiesCount] = policyInfos[_userAddr][_currentPolicyBookAddress];
                _policyStatuses[_policiesCount] = claimingRegistry.policyStatus(
                    _userAddr,
                    _currentPolicyBookAddress
                );
                _policyBooksArr[_policiesCount] = _currentPolicyBookAddress;

                _policiesCount++;
            } else if (!_isActive && !isPolicyActive(_userAddr, _currentPolicyBookAddress)) {
                _policiesArr[_policiesCount] = policyInfos[_userAddr][_currentPolicyBookAddress];
                _policyStatuses[_policiesCount] = IClaimingRegistry.ClaimStatus.UNCLAIMABLE;
                _policyBooksArr[_policiesCount] = _currentPolicyBookAddress;

                _policiesCount++;
            }
        }
    }

    function getUsersInfo(address[] calldata _users, address[] calldata _policyBooks)
        external
        view
        override
        returns (PolicyUserInfo[] memory _usersInfos)
    {
        require(_users.length == _policyBooks.length, "PolicyRegistry: Lengths' mismatch");

        _usersInfos = new PolicyUserInfo[](_users.length);

        IPolicyBook.PolicyHolder memory policyHolder;

        for (uint256 i = 0; i < _users.length; i++) {
            require(
                policyBookRegistry.isPolicyBook(_policyBooks[i]),
                "PolicyRegistry: Provided address is not a PolicyBook"
            );

            policyHolder = IPolicyBook(_policyBooks[i]).userStats(_users[i]);

            (
                _usersInfos[i].symbol,
                _usersInfos[i].insuredContract,
                _usersInfos[i].contractType,

            ) = IPolicyBook(_policyBooks[i]).info();

            _usersInfos[i].coverTokens = policyHolder.coverTokens;
            _usersInfos[i].startTime = policyStartTime(_users[i], _policyBooks[i]);
            _usersInfos[i].endTime = policyEndTime(_users[i], _policyBooks[i]);
            _usersInfos[i].paid = policyHolder.paid;
        }
    }

    function getPoliciesArr(address _userAddr)
        external
        view
        override
        returns (address[] memory _arr)
    {
        uint256 _size = _policies[_userAddr].length();
        _arr = new address[](_size);

        for (uint256 i = 0; i < _size; i++) {
            _arr[i] = _policies[_userAddr].at(i);
        }
    }

    function addPolicy(
        address _userAddr,
        uint256 _coverAmount,
        uint256 _premium,
        uint256 _durationSeconds
    ) external override onlyPolicyBooks {
        require(
            !isPolicyActive(_userAddr, msg.sender),
            "PolicyRegistry: The policy already exists"
        );

        if (!_policies[_userAddr].contains(msg.sender)) {
            _policies[_userAddr].add(msg.sender);
        }

        policyInfos[_userAddr][msg.sender] = PolicyInfo(
            _coverAmount,
            _premium,
            block.timestamp,
            block.timestamp.add(_durationSeconds)
        );

        emit PolicyAdded(_userAddr, msg.sender, _coverAmount);
    }

    function removePolicy(address _userAddr) external override onlyPolicyBooks {
        require(
            policyInfos[_userAddr][msg.sender].startTime != 0,
            "PolicyRegistry: This policy is not on the list"
        );

        delete policyInfos[_userAddr][msg.sender];

        _policies[_userAddr].remove(msg.sender);

        emit PolicyRemoved(_userAddr, msg.sender);
    }
}
