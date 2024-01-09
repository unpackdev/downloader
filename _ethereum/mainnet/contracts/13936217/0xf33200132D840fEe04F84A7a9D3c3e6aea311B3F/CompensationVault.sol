// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import "./console.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";
import "./ICompensationVault.sol";
import "./CompensationVaultStorage.sol";

// TODO: optimize by storage layout

contract CompensationVault is ICompensationVault, CompensationVaultStorage {
    using SafeMath for uint256;

    modifier onlySigner(address account) {
        require(isSigner[account], "invalid-signer");
        _;
    }

    modifier onlyRouter(address account) {
        require(isRouter[account], "invalid-router");
        _;
    }

    modifier whenPaused() {
        require(paused, "not-paused-yet");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "still-paused");
        _;
    }

    event Paused();
    event Unpaused();
    event SignerSet(address indexed account, bool value);
    event RouterSet(address indexed account, bool value);
    event CompensationAdded(address indexed sender, uint256 compensationAmount, uint256 flag);
    event CompensationClaimed(address indexed sender, uint256 compensationAmount);

    event LimitsUpdated(uint256 LIMIT_PER_TX, uint256 LIMIT_PER_DAY);
    event VaultReset(
        uint256 START_TIME,
        uint256 MAX_RUNNING_DAYS,
        uint256 TOTAL_ALLOCATED,
        uint256 LIMIT_PER_TX,
        uint256 LIMIT_PER_DAY,
        uint256 remainings,
        uint256 pastDebt
    );

    // initialize proxy
    function _initialize(
        address _owner,
        address _token,
        uint256 _START_TIME,
        uint256 _MAX_RUNNING_DAYS,
        uint256 _TOTAL_ALLOCATED,
        uint256 _LIMIT_PER_TX,
        uint256 _LIMIT_PER_DAY
    ) public {
        require(!_initialized0, "IE"); // initialize error
        token = _token;

        _setOwner(_owner);

        START_TIME = uint64(_START_TIME);
        MAX_RUNNING_DAYS = uint64(_MAX_RUNNING_DAYS);
        TOTAL_ALLOCATED = uint128(_TOTAL_ALLOCATED);
        LIMIT_PER_TX = uint128(_LIMIT_PER_TX);
        LIMIT_PER_DAY = uint128(_LIMIT_PER_DAY);

        _initialized0 = true;
    }

    function updateLimits(uint256 _LIMIT_PER_TX, uint256 _LIMIT_PER_DAY) external onlyOwner {
        LIMIT_PER_TX = uint128(_LIMIT_PER_TX);
        LIMIT_PER_DAY = uint128(_LIMIT_PER_DAY);

        emit LimitsUpdated(_LIMIT_PER_TX, _LIMIT_PER_DAY);
    }

    function reset(
        uint256 _START_TIME,
        uint256 _MAX_RUNNING_DAYS,
        uint256 _TOTAL_ALLOCATED,
        uint256 _LIMIT_PER_TX,
        uint256 _LIMIT_PER_DAY
    ) public onlyOwner whenPaused {
        START_TIME = uint64(_START_TIME);
        MAX_RUNNING_DAYS = uint64(_MAX_RUNNING_DAYS);
        TOTAL_ALLOCATED = uint128(_TOTAL_ALLOCATED);
        LIMIT_PER_TX = uint128(_LIMIT_PER_TX);
        LIMIT_PER_DAY = uint128(_LIMIT_PER_DAY);

        address _token = token;
        uint256 _debt = debt;
        uint256 _pastDebt = pastDebt;
        uint256 totalDebt = _pastDebt.add(_debt);

        // transfer remaining tokens
        uint256 balance = IERC20(_token).balanceOf(address(this));
        uint256 remainings = balance.sub(totalDebt);

        debt = 0;
        totalCompensation = 0;
        pastDebt = uint128(totalDebt);

        if (remainings > 0) TransferHelper.safeTransfer(_token, msg.sender, remainings);

        TransferHelper.safeTransferFrom(_token, msg.sender, address(this), _TOTAL_ALLOCATED);

        emit VaultReset(
            _START_TIME,
            _MAX_RUNNING_DAYS,
            _TOTAL_ALLOCATED,
            _LIMIT_PER_TX,
            _LIMIT_PER_DAY,
            remainings,
            totalDebt
        );

        unpause();
    }

    function remainingCompensation() public view returns (uint256) {
        return uint256(TOTAL_ALLOCATED).sub(totalCompensation);
    }

    function getDailyLimit() public view returns (uint256) {
        uint256 _START_TIME = START_TIME;
        uint256 _MAX_RUNNING_DAYS = MAX_RUNNING_DAYS;
        uint256 _TOTAL_ALLOCATED = TOTAL_ALLOCATED;
        uint256 _LIMIT_PER_DAY = LIMIT_PER_DAY;

        if (block.timestamp < _START_TIME) return 0;
        uint256 runningDays = (block.timestamp - _START_TIME) / 1 days + 1;
        uint256 maxDailyLimit = runningDays >= _MAX_RUNNING_DAYS ? _TOTAL_ALLOCATED : _LIMIT_PER_DAY * runningDays;
        uint256 dailyLimit = maxDailyLimit.sub(totalCompensation);

        return dailyLimit;
    }

    /**
     * @dev claim compensation tokens
     */
    function claimCompensation() external returns (uint256) {
        return _claimCompensation(msg.sender);
    }

    function _claimCompensation(address account) internal returns (uint256) {
        uint256 compensation = compensations[account];
        require(compensation > 0, "ICA"); // insufficient compensation amount error
        compensations[account] = 0;

        uint256 _debt = debt;
        uint256 _pastDebt = pastDebt;

        require(_debt.add(_pastDebt) >= compensation, "overflow? TBD");

        if (_pastDebt > 0) {
            if (_pastDebt > compensation) {
                _pastDebt -= compensation;
            } else {
                uint256 diff = compensation - _pastDebt;
                _pastDebt = 0;
                _debt = _debt.sub(diff);
            }
        } else {
            _debt = _debt.sub(compensation);
        }

        debt = uint128(_debt);
        pastDebt = uint128(_pastDebt);

        TransferHelper.safeTransfer(token, account, compensation);
        emit CompensationClaimed(account, compensation);

        return compensation;
    }

    function hashParams(CompensationParams calldata compensationParams) public pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                compensationParams.deadline,
                compensationParams.nonce,
                compensationParams.vault,
                compensationParams.quote,
                compensationParams.targetQuote,
                compensationParams.compensationAmount,
                compensationParams.maker,
                compensationParams.signer,
                compensationParams.transferCompensation
            )
        );

        return hash;
    }

    /**
     * @dev add compensation token
     */
    function addCompensation(uint256 amount1Out, CompensationParams calldata compensationParams)
        external
        onlyRouter(msg.sender)
        onlySigner(compensationParams.signer)
    {
        require(compensationParams.vault == address(this), "VAE"); // vault address error

        bytes32 hash = hashParams(compensationParams);

        // check parameter signature
        require(
            ECDSA.recover(ECDSA.toEthSignedMessageHash(hash), compensationParams.signature) ==
                compensationParams.signer,
            "IS"
        ); // invalid signature error

        uint256 flag = 0;
        // set flag if paused
        flag = (flag << 1) + (paused ? 1 : 0);
        // set flag if not start yet
        flag = (flag << 1) + (block.timestamp < START_TIME ? 1 : 0);
        // set flag if our quote is better than target quote
        flag = (flag << 1) + (compensationParams.targetQuote <= compensationParams.quote ? 1 : 0);
        // set flag if execution price is better than target quote
        flag = (flag << 1) + (compensationParams.targetQuote <= amount1Out ? 1 : 0);
        // set flag if deadline exceeds
        flag = (flag << 1) + (compensationParams.deadline <= block.timestamp ? 1 : 0);
        // set flag if nonce is already used
        flag = (flag << 1) + (nonces[compensationParams.nonce] ? 1 : 0);

        if (flag > 0) {
            emit CompensationAdded(compensationParams.maker, 0, flag);
            return;
        }
        nonces[compensationParams.nonce] = true;

        uint256 compensationAmount = compensationParams
            .compensationAmount
            .mul(compensationParams.targetQuote - amount1Out)
            .div(compensationParams.targetQuote - compensationParams.quote);

        compensationAmount = calcCompensationAmount(compensationAmount);

        totalCompensation = uint128(uint256(totalCompensation).add(compensationAmount));
        debt = uint128(uint256(debt).add(compensationAmount));

        compensations[compensationParams.maker] = compensations[compensationParams.maker].add(compensationAmount);
        emit CompensationAdded(compensationParams.maker, compensationAmount, 0);

        if (compensationParams.transferCompensation) {
            _claimCompensation(compensationParams.maker);
        }
    }

    /**
     * @dev calculate compensation amount wrt limits
     */
    function calcCompensationAmount(uint256 compensationAmount) public view returns (uint256) {
        return _min(_min(compensationAmount, remainingCompensation()), _min(LIMIT_PER_TX, getDailyLimit()));
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? b : a;
    }

    function setSigner(address account, bool value) external onlyOwner {
        isSigner[account] = value;
        emit SignerSet(account, value);
    }

    function setRouter(address account, bool value) external onlyOwner {
        isRouter[account] = value;
        emit RouterSet(account, value);
    }

    function chainID() public view returns (uint256) {
        uint256 _chainID;
        assembly {
            _chainID := chainid()
        }
        console.log("solidity: _chainID", _chainID);
        return _chainID;
    }

    // CIRCUIT BREAKER

    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused();
    }

    function rescueTokens(address _token, uint256 _value) external onlyOwner whenPaused {
        if (_token == address(0)) TransferHelper.safeTransferETH(msg.sender, _value);
        else TransferHelper.safeTransfer(_token, msg.sender, _value);
    }

    function getCompensation(address account) external view returns (uint256) {
        return compensations[account];
    }
}
