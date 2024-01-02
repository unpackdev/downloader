// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./ERC20BurnableUpgradeable.sol";
import "./IUniswapV3Factory.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IESASXVesting.sol";
import "./ESASXErrors.sol";
import "./BuybackV2.sol";

/**
 * @title Asymetrix Protocol V2 ESASXVesting contract
 * @author Asymetrix Protocol Inc Team
 * @notice An implementation of a ESASXVesting contract for esASX token convertion into ASX using vesting positions.
 */
contract ESASXVestingV3 is BuybackV2, IESASXVesting {
    using SafeERC20 for IERC20;

    mapping(address => mapping(uint256 => VestingPosition)) private vestingPositions;

    mapping(address => uint256) private vestingPositionsCount;

    IERC20 public esASX;

    uint256 private minVestingAmount;

    uint256 private totalVestedAmount;
    uint256 private totalReleasedAmount;

    uint256 public availableToBuyWithDiscount;

    uint32 private vestingPeriod;

    uint256 public additionalDiscountedEsAsxPerSecond;

    uint32 private lastUpdatedAdditionalDiscountedEsAsx;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the ESASXVesting V3 contract.
     * @param _name Name of the contract [EIP712].
     * @param _version Version of the contract [EIP712].
     * @param _priceSupplier Address of the price supplier.
     */
    function initializeV3(
        string calldata _name,
        string calldata _version,
        address _priceSupplier
    ) external reinitializer(3) {
        __Buyback_init_V2(_name, _version, _priceSupplier);
    }

    /**
     * @notice Sets new vesting period for the ESASXVesting, callable only by an owner.
     * @param _newVestingPeriod New vesting period of the ESASXVesting.
     */
    function setVestingPeriod(uint32 _newVestingPeriod) external onlyOwner {
        _setVestingPeriod(_newVestingPeriod);
    }

    /**
     * @notice Sets the minimum vesting amount any user must set in order to create a vesting position, callable only by
     *         an owner.
     * @param _minVestingAmount Minimum vesting amount for a vesting position.
     */
    function setMinVestingAmount(uint256 _minVestingAmount) external onlyOwner {
        _setMinVestingAmount(_minVestingAmount);
    }

    /**
     * @notice Sets a new additional discounted esSEX amount that will be ublocked linearly each second, callable only
     *         by an owner.
     * @param _newAdditionalDiscountedEsAsxPerSecond A new additional discounted esSEX amount that will be ublocked
     *                                               linearly each second.
     */
    function setAdditionalDiscountedEsAsxPerSecond(uint256 _newAdditionalDiscountedEsAsxPerSecond) external onlyOwner {
        additionalDiscountedEsAsxPerSecond = _newAdditionalDiscountedEsAsxPerSecond;
    }

    /// @inheritdoc IESASXVesting
    function createVestingPosition(address _user, uint256 _amount) external {
        if (_amount < minVestingAmount) revert ESASXErrors.WrongVestingAmount();
        if (getWithdrawableASXAmount() < _amount) revert ESASXErrors.InvalidEsASXAmount();

        esASX.safeTransferFrom(msg.sender, address(this), _amount);

        _createVestingPosition(_user, _amount);
    }

    /**
     * @notice Releases ASX tokens for a specified vesting position IDs in a batch.
     * @param _vpids An array of vesting position IDs.
     */
    function release(uint256[] memory _vpids) external {
        if (_vpids.length == 0) revert ESASXErrors.InvalidLength();

        for (uint256 _i; _i < _vpids.length; ++_i) {
            _release(_vpids[_i]);
        }
    }

    /**
     * @notice Releases ASX tokens with penalty for a specified vesting position IDs in a batch.
     * @param _vpids An array of vesting position IDs.
     */
    function releaseWithPenalty(uint256[] memory _vpids) external {
        if (_vpids.length == 0) revert ESASXErrors.InvalidLength();

        for (uint256 _i; _i < _vpids.length; ++_i) {
            _releaseWithPenalty(_vpids[_i]);
        }
    }

    /**
     * @notice Sells esASX tokens with discount for anyone.
     * @param _amount An amount of esASX tokens to buy.
     * @param _asxPriceInEthOffchain An offchain ASX price in ETH.
     * @param _signature Signature of the price by price supplier address.
     */
    function buyEsAsxWithDiscount(
        uint256 _amount,
        uint256 _asxPriceInEthOffchain,
        bytes calldata _signature
    ) external payable {
        availableToBuyWithDiscount = getUpdatedAvailableToBuyWithDiscountedEsAsx();
        lastUpdatedAdditionalDiscountedEsAsx = uint32(block.timestamp);

        if (_amount > availableToBuyWithDiscount) revert ESASXErrors.NotEnoughASXWithDiscount();

        availableToBuyWithDiscount -= _amount;

        if (msg.value == 0) {
            address _asx = asx;
            uint256 _amountToBurn = _amount >> 1;

            IERC20(_asx).safeTransferFrom(msg.sender, address(this), _amountToBurn);
            ERC20BurnableUpgradeable(_asx).burn(_amountToBurn);
            _createVestingPosition(msg.sender, _amount);
        } else {
            uint256 _asxPriceInWeth = uint256(asxOracle.latestAnswer());
            uint256 _paymentNeeded = ((_amount * _asxPriceInWeth) >> 1) / 10 ** asxOracle.decimals();

            if (msg.value < _paymentNeeded) revert ESASXErrors.NotEnoughETH();

            _buybackAndBurn(_paymentNeeded, 0, _asxPriceInEthOffchain, _signature);
            _createVestingPosition(msg.sender, _amount);
            payable(msg.sender).transfer(msg.value - _paymentNeeded);
        }
    }

    /**
     * @notice Withdraws unused esASX tokens or other tokens (including ETH) by an owner.
     * @param _token A token to withdraw. If equal to zero address - withdraws ETH.
     * @param _amount An amount of tokens for withdraw.
     * @param _recipient A recipient of withdrawn tokens.
     */
    function withdraw(address _token, uint256 _amount, address _recipient) external onlyOwner {
        if (_recipient == address(0)) revert ESASXErrors.InvalidAddress();

        if (_token == address(0)) {
            payable(_recipient).transfer(_amount);
        } else if (_token == address(asx)) {
            if (getWithdrawableASXAmount() < _amount) revert ESASXErrors.NotEnoughUnlockedASX();

            IERC20(_token).safeTransfer(_recipient, _amount);
        } else if (_token == address(esASX)) {
            if (getWithdrawableESASXAmount() < _amount) revert ESASXErrors.NotEnoughUnlockedESASX();

            IERC20(_token).safeTransfer(_recipient, _amount);
        } else {
            IERC20(_token).safeTransfer(_recipient, _amount);
        }

        emit Withdrawn(_token, _recipient, _amount);
    }

    /**
     * @notice Returns vesting period of the ESASXVesting.
     * @return Vesting period of the ESASXVesting.
     */
    function getVestingPeriod() external view returns (uint256) {
        return vestingPeriod;
    }

    /// @inheritdoc IESASXVesting
    function getMinVestingAmount() external view returns (uint256) {
        return minVestingAmount;
    }

    /**
     * @notice Returns total distribution amount for all vesting positions.
     * @return Total distribution amount for all vesting positions.
     */
    function getTotalVestedAmount() external view returns (uint256) {
        return totalVestedAmount;
    }

    /**
     * @notice Returns total released amount for all vesting positions.
     * @return Total released amount for all vesting positions.
     */
    function getTotalReleasedAmount() external view returns (uint256) {
        return totalReleasedAmount;
    }

    /**
     * @notice Returns vesting position amount for specified user.
     * @param _user An address of the owner of vesting position.
     * @return Total vesting positions for specified user.
     */
    function getVestingPositionsCount(address _user) external view returns (uint256) {
        return vestingPositionsCount[_user];
    }

    /**
     * @notice Returns a vesting position by it's ID. If no vesting position exist with provided ID, returns an empty
     *         vesting position.
     * @param _user An address of the owner of vesting position.
     * @param _vpid An ID of a vesting position.
     * @return A vesting position structure.
     */
    function getVestingPosition(address _user, uint256 _vpid) external view returns (VestingPosition memory) {
        return vestingPositions[_user][_vpid];
    }

    /**
     * @notice Returns a list of vesting positions paginated by their IDs.
     * @param _user An address of the owner of vesting positions.
     * @param _fromVpid An ID of a vesting position to start.
     * @param _toVpid An ID of a vesting position to finish.
     * @return A list with the found vesting position structures.
     */
    function getPaginatedVestingPositions(
        address _user,
        uint256 _fromVpid,
        uint256 _toVpid
    ) external view returns (VestingPosition[] memory) {
        if (_fromVpid > _toVpid) revert ESASXErrors.InvalidRange();

        uint256 _dataSize = vestingPositionsCount[_user];

        if (_fromVpid >= _dataSize) revert ESASXErrors.OutOfBounds();
        if (_toVpid >= _dataSize) revert ESASXErrors.OutOfBounds();

        VestingPosition[] memory _vestingPositions = new VestingPosition[](_toVpid - _fromVpid + 1);

        for (uint256 _i = _fromVpid; _i <= _toVpid; ++_i) {
            _vestingPositions[_i - _fromVpid] = vestingPositions[_user][_i];
        }

        return _vestingPositions;
    }

    /**
     * @notice Returns releasable amount for a vesting position by provided ID. If no vesting position exist with
     *         provided ID, returns zero.
     * @param _user An address of an owner of the vesting position.
     * @param _vpid An ID of a vesting position.
     * @return A releasable amount.
     */
    function getReleasableAmount(address _user, uint256 _vpid) external view returns (uint256) {
        VestingPosition memory _vestingPosition = vestingPositions[_user][_vpid];

        return
            _vestingPosition.releasedAmount == _vestingPosition.amount ? 0 : _computeReleasableAmount(_vestingPosition);
    }

    /**
     * @notice Returns updated amount of esASX tokens that are available to by with discount.
     * @return Updated amount of esASX tokens that are available to by with discount.
     */
    function getUpdatedAvailableToBuyWithDiscountedEsAsx() public view returns (uint256) {
        return
            availableToBuyWithDiscount +
            (additionalDiscountedEsAsxPerSecond * (uint32(block.timestamp) - lastUpdatedAdditionalDiscountedEsAsx));
    }

    /// @inheritdoc IESASXVesting
    function getWithdrawableASXAmount() public view returns (uint256) {
        return IERC20(asx).balanceOf(address(this)) - totalVestedAmount;
    }

    /**
     * @notice Returns an amount of esASX tokens available for withdrawal (unused esASX tokens amount).
     * @return A withdrawable esASX amount.
     */
    function getWithdrawableESASXAmount() public view returns (uint256) {
        return IERC20(esASX).balanceOf(address(this)) - totalVestedAmount;
    }

    /**
     * @notice Sets new vesting period of the ESASXVesting.
     * @param _newVestingPeriod New vesting period of any vesting position.
     */
    function _setVestingPeriod(uint32 _newVestingPeriod) private {
        if (_newVestingPeriod == 0) revert ESASXErrors.WrongVestingPeriod();

        vestingPeriod = _newVestingPeriod;
    }

    /**
     * @notice Sets the minimum vesting amount any user must set in order to create a vesting position.
     * @param _minVestingAmount Minimum vesting amount for a vesting position.
     */
    function _setMinVestingAmount(uint256 _minVestingAmount) private {
        if (_minVestingAmount == 0) revert ESASXErrors.WrongVestingAmount();

        minVestingAmount = _minVestingAmount;
    }

    /**
     * @notice Private function to create vesting position.
     * @param _user Address of the user.
     * @param _amount Amount to be vested.
     */
    function _createVestingPosition(address _user, uint256 _amount) private {
        uint256 _vestingPositionsCount = vestingPositionsCount[_user];
        VestingPosition memory _vestingPosition = VestingPosition({
            lockPeriod: vestingPeriod,
            amount: _amount,
            releasedAmount: 0,
            createdAt: uint32(block.timestamp)
        });

        vestingPositions[_user][_vestingPositionsCount] = _vestingPosition;
        vestingPositionsCount[_user] += 1;
        totalVestedAmount += _amount;

        emit VestingPositionCreated(_vestingPositionsCount, _user, _vestingPosition);
    }

    /**
     * @notice Releases ASX tokens for a specified vesting position ID.
     * @param _vpid A vesting position ID.
     */
    function _release(uint256 _vpid) private {
        VestingPosition memory _vestingPosition = vestingPositions[msg.sender][_vpid];

        if (_vestingPosition.createdAt == 0) revert ESASXErrors.NotExistingVP();
        if (_vestingPosition.releasedAmount == _vestingPosition.amount) revert ESASXErrors.NothingToRelease();

        uint256 _amount = _computeReleasableAmount(_vestingPosition);

        if (_amount == 0) revert ESASXErrors.NothingToRelease();

        _vestingPosition.releasedAmount += _amount;

        totalReleasedAmount += _amount;
        totalVestedAmount -= _amount;

        vestingPositions[msg.sender][_vpid] = _vestingPosition;

        IERC20(asx).safeTransfer(msg.sender, _amount);
        ERC20BurnableUpgradeable(address(esASX)).burn(_amount);

        emit Released(_vpid, msg.sender, _amount);
    }

    /**
     * @notice Releases ASX tokens with penalty for a specified vesting position ID.
     * @param _vpid A vesting position ID.
     */
    function _releaseWithPenalty(uint256 _vpid) private {
        _release(_vpid);

        VestingPosition memory _vestingPosition = vestingPositions[msg.sender][_vpid];
        uint256 _unreleasedTokens = _vestingPosition.amount - _vestingPosition.releasedAmount;

        if (_unreleasedTokens == 0) revert ESASXErrors.NothingToRelease();

        uint256 _percantageReleased = (_vestingPosition.releasedAmount * ONE_HUNDRED_PERCENTS) /
            _vestingPosition.amount;

        _vestingPosition.releasedAmount += _unreleasedTokens;

        totalReleasedAmount += _unreleasedTokens;
        totalVestedAmount -= _unreleasedTokens;

        uint256 _tokensToRelease = (_unreleasedTokens * _percantageReleased) / ONE_HUNDRED_PERCENTS;

        vestingPositions[msg.sender][_vpid] = _vestingPosition;

        IERC20(asx).safeTransfer(msg.sender, _tokensToRelease);
        ERC20BurnableUpgradeable(address(esASX)).burn(_tokensToRelease);

        availableToBuyWithDiscount += _unreleasedTokens - _tokensToRelease;

        emit ReleasedWithPenalty(_vpid, msg.sender, _tokensToRelease, _unreleasedTokens - _tokensToRelease);
    }

    /**
     * @notice A method for computing a releasable amount for a vesting position.
     * @param _vestingPosition A vesting position for which to compute a yreleasable amount.
     */
    function _computeReleasableAmount(VestingPosition memory _vestingPosition) private view returns (uint256) {
        uint32 _createdAt = _vestingPosition.createdAt;
        uint256 _lockTimePassed = block.timestamp - _createdAt;

        if (_lockTimePassed >= _vestingPosition.lockPeriod) {
            return _vestingPosition.amount - _vestingPosition.releasedAmount;
        } else {
            return
                _lockTimePassed *
                (_vestingPosition.amount / _vestingPosition.lockPeriod) -
                _vestingPosition.releasedAmount;
        }
    }
}
