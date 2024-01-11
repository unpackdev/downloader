// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";

import "./IPolicyBook.sol";
import "./IPolicyBookRegistry.sol";
import "./IContractsRegistry.sol";
import "./ILiquidityRegistry.sol";
import "./IBMICoverStaking.sol";
import "./ICapitalPool.sol";

import "./AbstractDependant.sol";

import "./Globals.sol";

contract LiquidityRegistry is ILiquidityRegistry, AbstractDependant {
    using SafeMath for uint256;
    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IPolicyBookRegistry public policyBookRegistry;
    IBMICoverStaking public bmiCoverStaking;

    // User address => policy books array
    mapping(address => EnumerableSet.AddressSet) private _policyBooks;

    // User address => policy books array - for withdrawl requests for all pools
    mapping(address => EnumerableSet.AddressSet) private _userWithdrawlRequestsPoolsList;
    // list of all users have withdrawl request
    EnumerableSet.AddressSet internal _withdrawlRequestUsersList;

    address public capitalPool;

    // policy books address => user array - for withdrawl requests for each pool
    mapping(address => EnumerableSet.AddressSet) private _poolWithdrawlRequestsUsersList;

    event PolicyBookAdded(address _userAddr, address _policyBookAddress);
    event PolicyBookRemoved(address _userAddr, address _policyBookAddress);

    modifier onlyEligibleContracts() {
        require(
            msg.sender == address(bmiCoverStaking) ||
                policyBookRegistry.isPolicyBookFacade(msg.sender) ||
                policyBookRegistry.isPolicyBook(msg.sender),
            "LR: Not an eligible contract"
        );
        _;
    }

    modifier onlyCapitalPool() {
        require(msg.sender == capitalPool, "LR: not Capital Pool");
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
        bmiCoverStaking = IBMICoverStaking(_contractsRegistry.getBMICoverStakingContract());
        capitalPool = _contractsRegistry.getCapitalPoolContract();
    }

    function tryToAddPolicyBook(address _userAddr, address _policyBookAddr)
        external
        override
        onlyEligibleContracts
    {
        if (
            IERC20(_policyBookAddr).balanceOf(_userAddr) > 0 ||
            bmiCoverStaking.balanceOf(_userAddr) > 0
        ) {
            _policyBooks[_userAddr].add(_policyBookAddr);

            emit PolicyBookAdded(_userAddr, _policyBookAddr);
        }
    }

    function tryToRemovePolicyBook(address _userAddr, address _policyBookAddr)
        external
        override
        onlyEligibleContracts
    {
        if (
            IERC20(_policyBookAddr).balanceOf(_userAddr) == 0 &&
            bmiCoverStaking.balanceOf(_userAddr) == 0 &&
            IPolicyBook(_policyBookAddr).getWithdrawalStatus(_userAddr) ==
            IPolicyBook.WithdrawalStatus.NONE
        ) {
            _policyBooks[_userAddr].remove(_policyBookAddr);

            // remove user withdraw request from the list
            _userWithdrawlRequestsPoolsList[_userAddr].remove(_policyBookAddr);
            _poolWithdrawlRequestsUsersList[_policyBookAddr].remove(_userAddr);
            if (_userWithdrawlRequestsPoolsList[_userAddr].length() == 0) {
                _withdrawlRequestUsersList.remove(_userAddr);
            }

            emit PolicyBookRemoved(_userAddr, _policyBookAddr);
        }
    }

    function removeExpiredWithdrawalRequest(address _userAddr, address _policyBookAddr)
        external
        override
        onlyEligibleContracts
    {
        // remove user withdraw request from the list
        _userWithdrawlRequestsPoolsList[_userAddr].remove(_policyBookAddr);
        _poolWithdrawlRequestsUsersList[_policyBookAddr].remove(_userAddr);
        if (_userWithdrawlRequestsPoolsList[_userAddr].length() == 0) {
            _withdrawlRequestUsersList.remove(_userAddr);
        }
    }

    function getPolicyBooksArrLength(address _userAddr) external view override returns (uint256) {
        return _policyBooks[_userAddr].length();
    }

    function getPolicyBooksArr(address _userAddr)
        external
        view
        override
        returns (address[] memory _resultArr)
    {
        uint256 _policyBooksArrLength = _policyBooks[_userAddr].length();

        _resultArr = new address[](_policyBooksArrLength);

        for (uint256 i = 0; i < _policyBooksArrLength; i++) {
            _resultArr[i] = _policyBooks[_userAddr].at(i);
        }
    }

    /// @notice _bmiXRatio comes with 10**18 precision
    function getLiquidityInfos(
        address _userAddr,
        uint256 _offset,
        uint256 _limit
    ) external view override returns (LiquidityInfo[] memory _resultArr) {
        uint256 _to = (_offset.add(_limit)).min(_policyBooks[_userAddr].length()).max(_offset);

        _resultArr = new LiquidityInfo[](_to - _offset);

        for (uint256 i = _offset; i < _to; i++) {
            address _currentPolicyBookAddr = _policyBooks[_userAddr].at(i);

            (uint256 _lockedAmount, , ) =
                IPolicyBook(_currentPolicyBookAddr).withdrawalsInfo(_userAddr);
            uint256 _availableAmount =
                IERC20(address(_currentPolicyBookAddr)).balanceOf(_userAddr);

            uint256 _bmiXRaito = IPolicyBook(_currentPolicyBookAddr).convertBMIXToSTBL(10**18);

            _resultArr[i - _offset] = LiquidityInfo(
                _currentPolicyBookAddr,
                _lockedAmount,
                _availableAmount,
                _bmiXRaito
            );
        }
    }

    function getWithdrawalRequests(
        address _userAddr,
        uint256 _offset,
        uint256 _limit
    )
        external
        view
        override
        returns (uint256 _arrLength, WithdrawalRequestInfo[] memory _resultArr)
    {
        uint256 _to = (_offset.add(_limit)).min(_policyBooks[_userAddr].length()).max(_offset);

        _resultArr = new WithdrawalRequestInfo[](_to - _offset);

        for (uint256 i = _offset; i < _to; i++) {
            IPolicyBook _currentPolicyBook = IPolicyBook(_policyBooks[_userAddr].at(i));

            (uint256 _requestAmount, uint256 _readyToWithdrawDate, ) =
                _currentPolicyBook.withdrawalsInfo(_userAddr);

            IPolicyBook.WithdrawalStatus _currentStatus =
                _currentPolicyBook.getWithdrawalStatus(_userAddr);

            if (_currentStatus == IPolicyBook.WithdrawalStatus.NONE) {
                continue;
            }

            uint256 _endWithdrawDate;

            if (block.timestamp > _readyToWithdrawDate) {
                _endWithdrawDate = _readyToWithdrawDate.add(
                    _currentPolicyBook.READY_TO_WITHDRAW_PERIOD()
                );
            }

            (uint256 coverTokens, uint256 liquidity) =
                _currentPolicyBook.getNewCoverAndLiquidity();

            _resultArr[_arrLength] = WithdrawalRequestInfo(
                address(_currentPolicyBook),
                _requestAmount,
                _currentPolicyBook.convertBMIXToSTBL(_requestAmount),
                liquidity.sub(coverTokens),
                _readyToWithdrawDate,
                _endWithdrawDate
            );

            _arrLength++;
        }
    }

    /// @notice Register's Withdrawals for all pools
    /// @dev Requires withdrawls to be serialized
    /// @param _policyBook address of the policybook with requested withdrawl
    /// @param _user address user addres requesting withdrawl
    function registerWithdrawl(address _policyBook, address _user)
        external
        override
        onlyEligibleContracts
    {
        _userWithdrawlRequestsPoolsList[_user].add(_policyBook);
        _poolWithdrawlRequestsUsersList[_policyBook].add(_user);
        _withdrawlRequestUsersList.add(_user);
    }

    /// @notice fetches the withdrawal data and amounts across all policybooks
    /// @dev use with getWithdrawlRequestUsersListCount()
    /// @param _limit max count of the list
    /// @return _totalWithdrawlAmount uint256 collected withdrawl amount
    function getAllPendingWithdrawalRequestsAmount(uint256 _limit)
        external
        view
        override
        returns (uint256 _totalWithdrawlAmount)
    {
        address _userAddr;

        for (uint256 i = 0; i < _limit; i++) {
            _userAddr = _withdrawlRequestUsersList.at(i);
            _totalWithdrawlAmount = _totalWithdrawlAmount.add(
                getAllPendingWithdrawalRequestsAmountByUser(
                    _userAddr,
                    _getUserWithdrawlRequestsPoolsListCount(_userAddr)
                )
            );
        }
    }

    /// @dev use with _getUserWithdrawlRequestsPoolsListCount()
    function getAllPendingWithdrawalRequestsAmountByUser(address _userAddr, uint256 _limit)
        internal
        view
        returns (uint256 _totalWithdrawlAmount)
    {
        IPolicyBook.WithdrawalStatus _currentStatus;
        address policyBookAddr;
        for (uint256 j = 0; j < _limit; j++) {
            policyBookAddr = _userWithdrawlRequestsPoolsList[_userAddr].at(j);
            IPolicyBook _currentPolicyBook = IPolicyBook(policyBookAddr);

            _currentStatus = _currentPolicyBook.getWithdrawalStatus(_userAddr);

            if (
                _currentStatus == IPolicyBook.WithdrawalStatus.NONE ||
                _currentStatus == IPolicyBook.WithdrawalStatus.EXPIRED
            ) {
                continue;
            }

            (uint256 _requestAmount, uint256 _readyToWithdrawDate, ) =
                _currentPolicyBook.withdrawalsInfo(_userAddr);

            ///@dev exclude all ready request until before ready to withdraw date by 24 hrs
            /// + 1 hr (spare time for transaction execution time)
            if (
                block.timestamp >=
                _readyToWithdrawDate.sub(
                    ICapitalPool(capitalPool).rebalanceDuration().add(60 * 60)
                )
            ) {
                _totalWithdrawlAmount = _totalWithdrawlAmount.add(
                    _currentPolicyBook.convertBMIXToSTBL(_requestAmount)
                );
            }
        }
    }

    /// @notice fetches the withdrawal data and amounts by policybook
    /// @dev use with getPoolWithdrawlRequestsUsersListCount()
    /// @param _policyBook address of the policybook with requested withdrawl
    /// @param _limit max count of the list
    /// @return _totalWithdrawlAmount uint256 collected withdrawl amount
    function getPendingWithdrawalAmountByPolicyBook(address _policyBook, uint256 _limit)
        external
        view
        override
        returns (uint256 _totalWithdrawlAmount)
    {
        IPolicyBook.WithdrawalStatus _currentStatus;

        address _userAddr;
        IPolicyBook _currentPolicyBook = IPolicyBook(_policyBook);

        for (uint256 i = 0; i < _limit; i++) {
            _userAddr = _poolWithdrawlRequestsUsersList[_policyBook].at(i);

            _currentStatus = _currentPolicyBook.getWithdrawalStatus(_userAddr);

            if (
                _currentStatus == IPolicyBook.WithdrawalStatus.NONE ||
                _currentStatus == IPolicyBook.WithdrawalStatus.EXPIRED
            ) {
                continue;
            }

            (uint256 _requestAmount, , ) = _currentPolicyBook.withdrawalsInfo(_userAddr);

            _totalWithdrawlAmount = _totalWithdrawlAmount.add(
                _currentPolicyBook.convertBMIXToSTBL(_requestAmount)
            );
        }
    }

    function getWithdrawlRequestUsersListCount() external view override returns (uint256) {
        return _withdrawlRequestUsersList.length();
    }

    function _getUserWithdrawlRequestsPoolsListCount(address _user)
        internal
        view
        returns (uint256)
    {
        return _userWithdrawlRequestsPoolsList[_user].length();
    }

    function getPoolWithdrawlRequestsUsersListCount(address _policyBook)
        external
        view
        override
        returns (uint256)
    {
        return _poolWithdrawlRequestsUsersList[_policyBook].length();
    }
}
