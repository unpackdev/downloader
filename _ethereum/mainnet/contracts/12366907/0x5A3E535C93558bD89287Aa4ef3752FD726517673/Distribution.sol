pragma solidity 0.5.12;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./OilerToken.sol";
import "./IDistribution.sol";
import "./IMultipleDistribution.sol";

/// @dev Distributes STAKE tokens.
contract Distribution is Ownable, IDistribution {
    using SafeMath for uint256;
    using Address for address;

    /// @dev Emits when `preInitialize` method has been called.
    /// @param token The address of ERC677MultiBridgeToken.
    /// @param caller The address of the caller.
    event PreInitialized(address token, address caller);

    /// @dev Emits when `initialize` method has been called.
    /// @param caller The address of the caller.
    event Initialized(address caller);

    /// @dev Emits when an installment for the specified pool has been made.
    /// @param pool The index of the pool.
    /// @param value The installment value.
    /// @param caller The address of the caller.
    event InstallmentMade(uint8 indexed pool, uint256 value, address caller);

    /// @dev Emits when the pool address was changed.
    /// @param pool The index of the pool.
    /// @param oldAddress Old address.
    /// @param newAddress New address.
    event PoolAddressChanged(uint8 indexed pool, address oldAddress, address newAddress);

    /// @dev The instance of ERC677MultiBridgeToken.
    OilerToken public token;

    uint8 public constant ECOSYSTEM_FUND = 1;
    uint8 public constant TEAM_FUND = 2;
    uint8 public constant PRIVATE_OFFERING = 3;
    uint8 public constant ADVISORS_REWARD = 4;
    uint8 public constant FOUNDATION_REWARD = 5;
    uint8 public constant LIQUIDITY_FUND = 6;

    /// @dev Pool address.
    mapping (uint8 => address) public poolAddress;
    /// @dev Pool total amount of tokens.
    mapping (uint8 => uint256) public stake;
    /// @dev Amount of remaining tokens to distribute for the pool.
    mapping (uint8 => uint256) public tokensLeft;
    /// @dev Pool cliff period (in seconds).
    mapping (uint8 => uint256) public cliff;
    /// @dev Total number of installments for the pool.
    mapping (uint8 => uint256) public numberOfInstallments;
    /// @dev Number of installments that were made.
    mapping (uint8 => uint256) public numberOfInstallmentsMade;
    /// @dev The value of one-time installment for the pool.
    mapping (uint8 => uint256) public installmentValue;
    /// @dev The value to transfer to the pool at cliff.
    mapping (uint8 => uint256) public valueAtCliff;
    /// @dev Boolean variable that contains whether the value for the pool at cliff was paid or not.
    mapping (uint8 => bool) public wasValueAtCliffPaid;
    /// @dev Boolean variable that contains whether all installments for the pool were made or not.
    mapping (uint8 => bool) public installmentsEnded;

    /// @dev The total token supply.
    uint256 constant public supply = 100_000_000 ether; // `ether` is used to indicate the token has 18 decimals

    /// @dev The timestamp of the distribution start.
    uint256 public distributionStartTimestamp;

    /// @dev The timestamp of pre-initialization.
    uint256 public preInitializationTimestamp;
    /// @dev Boolean variable that indicates whether the contract was pre-initialized.
    bool public isPreInitialized = false;
    /// @dev Boolean variable that indicates whether the contract was initialized.
    bool public isInitialized = false;

    /// @dev Checks that the contract is initialized.
    modifier initialized() {
        require(isInitialized, "not initialized");
        _;
    }

    /// @dev Checks that the installments for the given pool are started and are not finished already.
    /// @param _pool The index of the pool.
    modifier active(uint8 _pool) {
        // Note that the timestamp can have a 900-second error:
        // https://github.com/ethereum/wiki/blob/c02254611f218f43cbb07517ca8e5d00fd6d6d75/Block-Protocol-2.0.md
        require(
            // solium-disable-next-line security/no-block-members
            _now() >= distributionStartTimestamp.add(cliff[_pool]) && !installmentsEnded[_pool],
            "installments are not active for this pool"
        );
        _;
    }

    /// @dev Sets up constants and pools addresses that are used in distribution.
    /// @param _ecosystemFundAddress The address of the Ecosystem Fund.
    /// @param _teamFundAddress The address of the Team Fund.
    /// @param _privateOfferingAddress The address of the Private Offering contract.
    /// @param _advisorsRewardAddress The address of the Advisors Reward contract.
    /// @param _foundationAddress The address of the Foundation Reward.
    /// @param _liquidityFundAddress The address of the Liquidity Fund.
    constructor(
        address _ecosystemFundAddress,
        address _teamFundAddress,
        address _privateOfferingAddress,
        address _advisorsRewardAddress,
        address _foundationAddress,
        address _liquidityFundAddress
    ) public {
        // validate provided addresses
        require(
            _privateOfferingAddress.isContract() &&
            _advisorsRewardAddress.isContract(),
            "not a contract address"
        );
        _validateAddress(_ecosystemFundAddress);
        _validateAddress(_teamFundAddress);
        _validateAddress(_foundationAddress);
        _validateAddress(_liquidityFundAddress);
        poolAddress[ECOSYSTEM_FUND] = _ecosystemFundAddress;
        poolAddress[TEAM_FUND] = _teamFundAddress;
        poolAddress[PRIVATE_OFFERING] = _privateOfferingAddress;
        poolAddress[ADVISORS_REWARD] = _advisorsRewardAddress;
        poolAddress[FOUNDATION_REWARD] = _foundationAddress;
        poolAddress[LIQUIDITY_FUND] = _liquidityFundAddress;

        // initialize token amounts. `ether` is used to indicate the token has 18 decimals
        stake[ECOSYSTEM_FUND] = 20_000_000 ether;
        stake[TEAM_FUND] = 12_500_000 ether;
        stake[PRIVATE_OFFERING] = IMultipleDistribution(poolAddress[PRIVATE_OFFERING]).poolStake();
        stake[ADVISORS_REWARD] = IMultipleDistribution(poolAddress[ADVISORS_REWARD]).poolStake();
        stake[FOUNDATION_REWARD] = 36_812_232 ether;
        stake[LIQUIDITY_FUND] = 10_000_000 ether;

        require(
            stake[ECOSYSTEM_FUND] // solium-disable-line operator-whitespace
                .add(stake[TEAM_FUND])
                .add(stake[PRIVATE_OFFERING])
                .add(stake[ADVISORS_REWARD])
                .add(stake[FOUNDATION_REWARD])
                .add(stake[LIQUIDITY_FUND])
            == supply,
            "wrong sum of pools stakes"
        );

        tokensLeft[ECOSYSTEM_FUND] = stake[ECOSYSTEM_FUND];
        tokensLeft[TEAM_FUND] = stake[TEAM_FUND];
        tokensLeft[PRIVATE_OFFERING] = stake[PRIVATE_OFFERING];
        tokensLeft[ADVISORS_REWARD] = stake[ADVISORS_REWARD];
        tokensLeft[FOUNDATION_REWARD] = stake[FOUNDATION_REWARD];
        tokensLeft[LIQUIDITY_FUND] = stake[LIQUIDITY_FUND];

        valueAtCliff[ECOSYSTEM_FUND] = stake[ECOSYSTEM_FUND].mul(75).div(1000); // 7.5% unlocked at cliff (day 0)
        valueAtCliff[PRIVATE_OFFERING] = 0; // No additional tranche at cliff - just installments
        valueAtCliff[ADVISORS_REWARD] = stake[ADVISORS_REWARD].mul(20).div(100);     // 20% unlocked at cliff
        valueAtCliff[FOUNDATION_REWARD] = stake[FOUNDATION_REWARD].mul(20).div(100); // 20% unlocked at cliff
        valueAtCliff[TEAM_FUND] = stake[TEAM_FUND].mul(10).div(100);     // 10% unlocked at cliff

        cliff[ECOSYSTEM_FUND] = 0 days; // unlock of the cliff tranche and start of installments unlocking
        cliff[PRIVATE_OFFERING] = 44 days; // unlock of the cliff tranche and start of installments unlocking
        cliff[ADVISORS_REWARD] = 180 days; // unlock of the cliff tranche and start of installments unlocking
        cliff[FOUNDATION_REWARD] = 360 days; // unlock of the cliff tranche and start of installments unlocking
        cliff[TEAM_FUND] = 270 days; // unlock of the cliff tranche and start of installments unlocking

        numberOfInstallments[ECOSYSTEM_FUND] = 810; // days for the rest of installments after cliff
        numberOfInstallments[PRIVATE_OFFERING] = 270; // days for the rest of installments after cliff
        numberOfInstallments[ADVISORS_REWARD] = 270; // days for the rest of installments after cliff
        numberOfInstallments[FOUNDATION_REWARD] = 360; // days for the rest of installments after cliff
        numberOfInstallments[TEAM_FUND] = 720; // days for the rest of installments after cliff

        installmentValue[ECOSYSTEM_FUND] = _calculateInstallmentValue(ECOSYSTEM_FUND);
        installmentValue[PRIVATE_OFFERING] = _calculateInstallmentValue(
            PRIVATE_OFFERING,
            stake[PRIVATE_OFFERING].mul(25).div(100) // 25% will be distributed at pre-initializing and 0 at cliff, then installments
        );
        installmentValue[ADVISORS_REWARD] = _calculateInstallmentValue(ADVISORS_REWARD);
        installmentValue[FOUNDATION_REWARD] = _calculateInstallmentValue(FOUNDATION_REWARD);
        installmentValue[TEAM_FUND] = _calculateInstallmentValue(TEAM_FUND);
    }

    /// @dev Pre-initializes the contract after the token is created.
    /// Distributes tokens for Team Fund, Liquidity Fund, and part of Private Offering.
    /// @param _tokenAddress The address of the STAKE token contract.
    function preInitialize(address _tokenAddress) external onlyOwner {
        require(!isPreInitialized, "already pre-initialized");

        token = OilerToken(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance == supply, "wrong contract balance");

        preInitializationTimestamp = _now(); // solium-disable-line security/no-block-members
        isPreInitialized = true;

        IMultipleDistribution(poolAddress[PRIVATE_OFFERING]).initialize(_tokenAddress);
        IMultipleDistribution(poolAddress[ADVISORS_REWARD]).initialize(_tokenAddress);
        uint256 privateOfferingPrerelease = stake[PRIVATE_OFFERING].mul(25).div(100); // 25%

        token.transferDistribution(poolAddress[LIQUIDITY_FUND], stake[LIQUIDITY_FUND]);
        token.transfer(poolAddress[PRIVATE_OFFERING], privateOfferingPrerelease);


        tokensLeft[PRIVATE_OFFERING] = tokensLeft[PRIVATE_OFFERING].sub(privateOfferingPrerelease);
        tokensLeft[LIQUIDITY_FUND] = tokensLeft[LIQUIDITY_FUND].sub(stake[LIQUIDITY_FUND]);

        emit PreInitialized(_tokenAddress, msg.sender);
        emit InstallmentMade(PRIVATE_OFFERING, privateOfferingPrerelease, msg.sender);
        emit InstallmentMade(LIQUIDITY_FUND, stake[LIQUIDITY_FUND], msg.sender);
    }

    /// @dev Initializes token distribution.
    function initialize() external {
        require(isPreInitialized, "not pre-initialized");
        require(!isInitialized, "already initialized");

        if (_now().sub(preInitializationTimestamp) < 90 days) { // solium-disable-line security/no-block-members
            require(isOwner(), "for now only owner can call this method");
        }

        // Note that the timestamp can have a 900-second error:
        // https://github.com/ethereum/wiki/blob/c02254611f218f43cbb07517ca8e5d00fd6d6d75/Block-Protocol-2.0.md
        distributionStartTimestamp = _now(); // solium-disable-line security/no-block-members
        isInitialized = true;

        emit Initialized(msg.sender);
    }

    /// @dev Changes the address of the specified pool.
    /// @param _pool The index of the pool (only ECOSYSTEM_FUND or FOUNDATION_REWARD are allowed).
    /// @param _newAddress The new address for the change.
    function changePoolAddress(uint8 _pool, address _newAddress) external {
        require(_pool == ECOSYSTEM_FUND || _pool == FOUNDATION_REWARD, "wrong pool");
        require(msg.sender == poolAddress[_pool], "not authorized");
        _validateAddress(_newAddress);
        emit PoolAddressChanged(_pool, poolAddress[_pool], _newAddress);
        poolAddress[_pool] = _newAddress;
    }

    /// @dev Makes an installment for one of the following pools:
    /// Team Fund, Private Offering, Advisors Reward, Ecosystem Fund, Foundation Reward.
    /// @param _pool The index of the pool.
    function makeInstallment(uint8 _pool) public initialized active(_pool) {
        require(
            _pool == TEAM_FUND ||
            _pool == PRIVATE_OFFERING ||
            _pool == ADVISORS_REWARD ||
            _pool == ECOSYSTEM_FUND ||
            _pool == FOUNDATION_REWARD,
            "wrong pool"
        );
        uint256 value = 0;
        if (!wasValueAtCliffPaid[_pool]) {
            value = valueAtCliff[_pool];
            wasValueAtCliffPaid[_pool] = true;
        }
        uint256 availableNumberOfInstallments = _calculateNumberOfAvailableInstallments(_pool);
        value = value.add(installmentValue[_pool].mul(availableNumberOfInstallments));

        require(value > 0, "no installments available");

        uint256 remainder = _updatePoolData(_pool, value, availableNumberOfInstallments);
        value = value.add(remainder);

        if (_pool == PRIVATE_OFFERING || _pool == ADVISORS_REWARD) {
            token.transfer(poolAddress[_pool], value);
        } else {
            token.transferDistribution(poolAddress[_pool], value);
        }

        emit InstallmentMade(_pool, value, msg.sender);
    }

    /// @dev This method is called after the STAKE tokens are transferred to this contract.
    function onTokenTransfer(address, uint256, bytes memory) public pure returns (bool) {
        revert("sending tokens to this contract is not allowed");
    }

    /// @dev The removed implementation of the ownership renouncing.
    function renounceOwnership() public onlyOwner {
        revert("not implemented");
    }

    function _now() internal view returns (uint256) {
        return now; // solium-disable-line security/no-block-members
    }

    /// @dev Updates the given pool data after each installment:
    /// the remaining number of tokens,
    /// the number of made installments.
    /// If the last installment are done and the tokens remained
    /// then transfers them to the pool and marks that all installments for the given pool are made.
    /// @param _pool The index of the pool.
    /// @param _value Current installment value.
    /// @param _currentNumberOfInstallments Number of installment that are made.
    function _updatePoolData(
        uint8 _pool,
        uint256 _value,
        uint256 _currentNumberOfInstallments
    ) internal returns (uint256) {
        uint256 remainder = 0;
        tokensLeft[_pool] = tokensLeft[_pool].sub(_value);
        numberOfInstallmentsMade[_pool] = numberOfInstallmentsMade[_pool].add(_currentNumberOfInstallments);
        if (numberOfInstallmentsMade[_pool] >= numberOfInstallments[_pool]) {
            if (tokensLeft[_pool] > 0) {
                remainder = tokensLeft[_pool];
                tokensLeft[_pool] = 0;
            }
            _endInstallment(_pool);
        }
        return remainder;
    }

    /// @dev Marks that all installments for the given pool are made.
    /// @param _pool The index of the pool.
    function _endInstallment(uint8 _pool) internal {
        installmentsEnded[_pool] = true;
    }

    /// @dev Calculates the value of the installment for 1 day for the given pool.
    /// @param _pool The index of the pool.
    /// @param _valueAtCliff Custom value to distribute at cliff.
    function _calculateInstallmentValue(
        uint8 _pool,
        uint256 _valueAtCliff
    ) internal view returns (uint256) {
        return stake[_pool].sub(_valueAtCliff).div(numberOfInstallments[_pool]);
    }

    /// @dev Calculates the value of the installment for 1 day for the given pool.
    /// @param _pool The index of the pool.
    function _calculateInstallmentValue(uint8 _pool) internal view returns (uint256) {
        return _calculateInstallmentValue(_pool, valueAtCliff[_pool]);
    }

    /// @dev Calculates the number of available installments for the given pool.
    /// @param _pool The index of the pool.
    /// @return The number of available installments.
    function _calculateNumberOfAvailableInstallments(
        uint8 _pool
    ) internal view returns (
        uint256 availableNumberOfInstallments
    ) {
        uint256 paidDays = numberOfInstallmentsMade[_pool].mul(1 days);
        uint256 lastTimestamp = distributionStartTimestamp.add(cliff[_pool]).add(paidDays);
        // solium-disable-next-line security/no-block-members
        availableNumberOfInstallments = _now().sub(lastTimestamp).div(1 days);
        // Note that the timestamp can have a 900-second error:
        // https://github.com/ethereum/wiki/blob/c02254611f218f43cbb07517ca8e5d00fd6d6d75/Block-Protocol-2.0.md
        if (numberOfInstallmentsMade[_pool].add(availableNumberOfInstallments) > numberOfInstallments[_pool]) {
            availableNumberOfInstallments = numberOfInstallments[_pool].sub(numberOfInstallmentsMade[_pool]);
        }
    }

    /// @dev Checks for an empty address.
    function _validateAddress(address _address) internal pure {
        if (_address == address(0)) {
            revert("invalid address");
        }
    }
}
