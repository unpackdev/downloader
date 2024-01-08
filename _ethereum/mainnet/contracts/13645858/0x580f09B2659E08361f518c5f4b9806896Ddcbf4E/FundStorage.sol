// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "Initializable.sol";
import "SetGetAssembly.sol";

contract FundStorage is Initializable, SetGetAssembly {
    bytes32 internal constant _UNDERLYING_SLOT =
        0xe0dc1d429ff8628e5936b3d6a6546947e1cc9ea7415a59d46ce95b3cfa4442b9;
    bytes32 internal constant _UNDERLYING_UNIT_SLOT =
        0x4840b03aa097a422092d99dc6875c2b69e8f48c9af2563a0447f3b4e4928d962;
    bytes32 internal constant _DECIMALS_SLOT =
        0x15b9fa1072bc4b2cdb762a49a2c7917b8b3af02283e37ffd41d0fccd4eef0d48;
    bytes32 internal constant _FUND_MANAGER_SLOT =
        0x670552e214026020a9e6caa820519c7f879b21bd75b5571387d6a9cf8f94bd18;
    bytes32 internal constant _RELAYER_SLOT =
        0x84e8c6b8f2281d51d9f683d351409724c3caa7848051aeb9d92c106ab36cc24c;
    bytes32 internal constant _PLATFORM_REWARDS_SLOT =
        0x92260bfe68dd0f8a9f5439b75466781ba1ce44523ed1a3026a73eada49072e65;
    bytes32 internal constant _CHANGE_DELAY_SLOT =
        0x0391715d0dd26b729c4ba34639ad5bdb0a7feb89f59a1e38f38485ea7f5a1583;
    bytes32 internal constant _DEPOSIT_LIMIT_SLOT =
        0xca2f8a3e9ea81335bcce793cde55fc0c38129b594f53052d2bb18099ffa72613;
    bytes32 internal constant _DEPOSIT_LIMIT_TX_MAX_SLOT =
        0x769f312c3790719cf1ea5f75303393f080fd62be88d75fa86726a6be00bb5a24;
    bytes32 internal constant _DEPOSIT_LIMIT_TX_MIN_SLOT =
        0x9027949576d185c74d79ad3b8a8dbff32126f3a3ee140b346f146beb18234c85;
    bytes32 internal constant _PERFORMANCE_FEE_FUND_SLOT =
        0x5b8979500398f8fbeb42c36d18f31a76fd0ab30f4338d864e7d8734b340e9bb9;
    bytes32 internal constant _PLATFORM_FEE_SLOT =
        0x2084059f3bff3cc3fd204df32325dcb05f47c2f590aba5d103ec584523738e7a;
    bytes32 internal constant _MAX_INVESTMENT_IN_STRATEGIES_SLOT =
        0xe3b5969c9426551aa8f16dbc7b25042b9b9c9869b759c77a85f0b097ac363475;
    bytes32 internal constant _TOTAL_WEIGHT_IN_STRATEGIES_SLOT =
        0x63177e03c47ab825f04f5f8f2334e312239890e7588db78cabe10d7aec327fd2;
    bytes32 internal constant _TOTAL_ACCOUNTED_SLOT =
        0xa19f3b8a62465676ae47ab811ee15e3d2b68d88869cb38686d086a11d382f6bb;
    bytes32 internal constant _TOTAL_INVESTED_SLOT =
        0x49c84685200b42972f845832b2c3da3d71def653c151340801aeae053ce104e9;
    bytes32 internal constant _DEPOSITS_PAUSED_SLOT =
        0x3cefcfe9774096ac956c0d63992ea27a01fb3884a22b8765ad63c8366f90a9c8;
    bytes32 internal constant _SHOULD_REBALANCE_SLOT =
        0x7f8e3dfb98485aa419c1d05b6ea089a8cddbafcfcf4491db33f5d0b5fe4f32c7;
    bytes32 internal constant _LAST_HARDWORK_TIMESTAMP_SLOT =
        0x0260c2bf5555cd32cedf39c0fcb0eab8029c67b3d5137faeb3e24a500db80bc9;
    bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT =
        0xa7ae0fa763ec3009113ccc5eb9089e1f0028607f5b8198c52cd42366c1ddb17b;
    bytes32 internal constant _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT =
        0x5e1f7083e1d90c44893f97806d0ec517436a58b85860b28247fd6fd56f5dc897;

    constructor() public {
        assert(
            _UNDERLYING_SLOT ==
                bytes32(
                    uint256(
                        keccak256("eip1967.mesh.finance.fundStorage.underlying")
                    ) - 1
                )
        );
        assert(
            _UNDERLYING_UNIT_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.underlyingUnit"
                        )
                    ) - 1
                )
        );
        assert(
            _DECIMALS_SLOT ==
                bytes32(
                    uint256(
                        keccak256("eip1967.mesh.finance.fundStorage.decimals")
                    ) - 1
                )
        );
        assert(
            _FUND_MANAGER_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.fundManager"
                        )
                    ) - 1
                )
        );
        assert(
            _RELAYER_SLOT ==
                bytes32(
                    uint256(
                        keccak256("eip1967.mesh.finance.fundStorage.relayer")
                    ) - 1
                )
        );
        assert(
            _PLATFORM_REWARDS_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.platformRewards"
                        )
                    ) - 1
                )
        );
        assert(
            _CHANGE_DELAY_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.changeDelay"
                        )
                    ) - 1
                )
        );
        assert(
            _DEPOSIT_LIMIT_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.depositLimit"
                        )
                    ) - 1
                )
        );
        assert(
            _DEPOSIT_LIMIT_TX_MAX_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.depositLimitTxMax"
                        )
                    ) - 1
                )
        );
        assert(
            _DEPOSIT_LIMIT_TX_MIN_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.depositLimitTxMin"
                        )
                    ) - 1
                )
        );
        assert(
            _PERFORMANCE_FEE_FUND_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.performanceFeeFund"
                        )
                    ) - 1
                )
        );
        assert(
            _PLATFORM_FEE_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.platformFee"
                        )
                    ) - 1
                )
        );
        assert(
            _MAX_INVESTMENT_IN_STRATEGIES_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.maxInvestmentInStrategies"
                        )
                    ) - 1
                )
        );
        assert(
            _TOTAL_WEIGHT_IN_STRATEGIES_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.totalWeightInStrategies"
                        )
                    ) - 1
                )
        );
        assert(
            _TOTAL_ACCOUNTED_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.totalAccounted"
                        )
                    ) - 1
                )
        );
        assert(
            _TOTAL_INVESTED_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.totalInvested"
                        )
                    ) - 1
                )
        );
        assert(
            _DEPOSITS_PAUSED_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.depositsPaused"
                        )
                    ) - 1
                )
        );
        assert(
            _SHOULD_REBALANCE_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.shouldRebalance"
                        )
                    ) - 1
                )
        );
        assert(
            _LAST_HARDWORK_TIMESTAMP_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.lastHardworkTimestamp"
                        )
                    ) - 1
                )
        );
        assert(
            _NEXT_IMPLEMENTATION_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.nextImplementation"
                        )
                    ) - 1
                )
        );
        assert(
            _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT ==
                bytes32(
                    uint256(
                        keccak256(
                            "eip1967.mesh.finance.fundStorage.nextImplementationTimestamp"
                        )
                    ) - 1
                )
        );
    }

    function initializeFundStorage(
        address _underlying,
        uint256 _underlyingUnit,
        uint8 _decimals,
        address _fundManager,
        address _relayer,
        address _platformRewards,
        uint256 _changeDelay
    ) public initializer {
        _setUnderlying(_underlying);
        _setUnderlyingUnit(_underlyingUnit);
        _setDecimals(_decimals);
        _setFundManager(_fundManager);
        _setRelayer(_relayer);
        _setPlatformRewards(_platformRewards);
        _setChangeDelay(_changeDelay);
        _setDepositLimit(0);
        _setDepositLimitTxMax(0);
        _setDepositLimitTxMin(0);
        _setPerformanceFeeFund(0);
        _setPlatformFee(0);
        _setMaxInvestmentInStrategies(9500); // 9500 BPS (95%) can be accessed by the strategies. This is to keep something in fund for withdrawal.
        _setTotalWeightInStrategies(0);
        _setTotalAccounted(0);
        _setTotalInvested(0);
        _setDepositsPaused(false);
        _setShouldRebalance(false);
        _setLastHardworkTimestamp(0);
        _setNextImplementation(address(0));
        _setNextImplementationTimestamp(0);
    }

    function _setUnderlying(address _address) internal {
        setAddress(_UNDERLYING_SLOT, _address);
    }

    function _underlying() internal view returns (address) {
        return getAddress(_UNDERLYING_SLOT);
    }

    function _setUnderlyingUnit(uint256 _value) internal {
        setUint256(_UNDERLYING_UNIT_SLOT, _value);
    }

    function _underlyingUnit() internal view returns (uint256) {
        return getUint256(_UNDERLYING_UNIT_SLOT);
    }

    function _setDecimals(uint8 _value) internal {
        setUint8(_DECIMALS_SLOT, _value);
    }

    function _decimals() internal view returns (uint8) {
        return getUint8(_DECIMALS_SLOT);
    }

    function _setFundManager(address _fundManager) internal {
        setAddress(_FUND_MANAGER_SLOT, _fundManager);
    }

    function _fundManager() internal view returns (address) {
        return getAddress(_FUND_MANAGER_SLOT);
    }

    function _setRelayer(address _relayer) internal {
        setAddress(_RELAYER_SLOT, _relayer);
    }

    function _relayer() internal view returns (address) {
        return getAddress(_RELAYER_SLOT);
    }

    function _setPlatformRewards(address _rewards) internal {
        setAddress(_PLATFORM_REWARDS_SLOT, _rewards);
    }

    function _platformRewards() internal view returns (address) {
        return getAddress(_PLATFORM_REWARDS_SLOT);
    }

    function _setChangeDelay(uint256 _value) internal {
        setUint256(_CHANGE_DELAY_SLOT, _value);
    }

    function _changeDelay() internal view returns (uint256) {
        return getUint256(_CHANGE_DELAY_SLOT);
    }

    function _setDepositLimit(uint256 _value) internal {
        setUint256(_DEPOSIT_LIMIT_SLOT, _value);
    }

    function _depositLimit() internal view returns (uint256) {
        return getUint256(_DEPOSIT_LIMIT_SLOT);
    }

    function _setDepositLimitTxMax(uint256 _value) internal {
        setUint256(_DEPOSIT_LIMIT_TX_MAX_SLOT, _value);
    }

    function _depositLimitTxMax() internal view returns (uint256) {
        return getUint256(_DEPOSIT_LIMIT_TX_MAX_SLOT);
    }

    function _setDepositLimitTxMin(uint256 _value) internal {
        setUint256(_DEPOSIT_LIMIT_TX_MIN_SLOT, _value);
    }

    function _depositLimitTxMin() internal view returns (uint256) {
        return getUint256(_DEPOSIT_LIMIT_TX_MIN_SLOT);
    }

    function _setPerformanceFeeFund(uint256 _value) internal {
        setUint256(_PERFORMANCE_FEE_FUND_SLOT, _value);
    }

    function _performanceFeeFund() internal view returns (uint256) {
        return getUint256(_PERFORMANCE_FEE_FUND_SLOT);
    }

    function _setPlatformFee(uint256 _value) internal {
        setUint256(_PLATFORM_FEE_SLOT, _value);
    }

    function _platformFee() internal view returns (uint256) {
        return getUint256(_PLATFORM_FEE_SLOT);
    }

    function _setMaxInvestmentInStrategies(uint256 _value) internal {
        setUint256(_MAX_INVESTMENT_IN_STRATEGIES_SLOT, _value);
    }

    function _maxInvestmentInStrategies() internal view returns (uint256) {
        return getUint256(_MAX_INVESTMENT_IN_STRATEGIES_SLOT);
    }

    function _setTotalWeightInStrategies(uint256 _value) internal {
        setUint256(_TOTAL_WEIGHT_IN_STRATEGIES_SLOT, _value);
    }

    function _totalWeightInStrategies() internal view returns (uint256) {
        return getUint256(_TOTAL_WEIGHT_IN_STRATEGIES_SLOT);
    }

    function _setTotalAccounted(uint256 _value) internal {
        setUint256(_TOTAL_ACCOUNTED_SLOT, _value);
    }

    function _totalAccounted() internal view returns (uint256) {
        return getUint256(_TOTAL_ACCOUNTED_SLOT);
    }

    function _setTotalInvested(uint256 _value) internal {
        setUint256(_TOTAL_INVESTED_SLOT, _value);
    }

    function _totalInvested() internal view returns (uint256) {
        return getUint256(_TOTAL_INVESTED_SLOT);
    }

    function _setDepositsPaused(bool _value) internal {
        setBool(_DEPOSITS_PAUSED_SLOT, _value);
    }

    function _depositsPaused() internal view returns (bool) {
        return getBool(_DEPOSITS_PAUSED_SLOT);
    }

    function _setShouldRebalance(bool _value) internal {
        setBool(_SHOULD_REBALANCE_SLOT, _value);
    }

    function _shouldRebalance() internal view returns (bool) {
        return getBool(_SHOULD_REBALANCE_SLOT);
    }

    function _setLastHardworkTimestamp(uint256 _value) internal {
        setUint256(_LAST_HARDWORK_TIMESTAMP_SLOT, _value);
    }

    function _lastHardworkTimestamp() internal view returns (uint256) {
        return getUint256(_LAST_HARDWORK_TIMESTAMP_SLOT);
    }

    function _setNextImplementation(address _newImplementation) internal {
        setAddress(_NEXT_IMPLEMENTATION_SLOT, _newImplementation);
    }

    function _nextImplementation() internal view returns (address) {
        return getAddress(_NEXT_IMPLEMENTATION_SLOT);
    }

    function _setNextImplementationTimestamp(uint256 _value) internal {
        setUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT, _value);
    }

    function _nextImplementationTimestamp() internal view returns (uint256) {
        return getUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT);
    }

    uint256[50] private bigEmptySlot;
}
