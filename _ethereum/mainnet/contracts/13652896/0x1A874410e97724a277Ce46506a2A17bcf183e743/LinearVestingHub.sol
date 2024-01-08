// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Initializable.sol";
import "./Proxied.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./VestingFormulaFunctions.sol";
import "./SVesting.sol";

// BE CAREFUL: DOT NOT CHANGE THE ORDER OF INHERITED CONTRACT
contract LinearVestingHub is
    Initializable,
    Proxied,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // solhint-disable-next-line max-line-length
    ////////////////////////////////////////// CONSTANTS AND IMMUTABLES ///////////////////////////////////

    // GEL Token
    // solhint-disable var-name-mixedcase
    IERC20 public immutable TOKEN;
    // VESTING_TRE
    address public immutable VESTING_TREASURY;
    // solhint-enable var-name-mixedcase

    // !!!!!!!!!!!!!!!!!!!!!!!! DO NOT CHANGE ORDER !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    mapping(address => uint256) public nextVestingIdByReceiver;
    mapping(address => Vesting[]) public vestingsByReceiver;
    uint256 public totalWithdrawn;

    EnumerableSet.AddressSet private _receivers;

    event LogAddVestings(uint256 sumTokenBalances);
    event LogAddVesting(
        uint256 id,
        address receiver,
        uint256 allocation,
        uint256 startTime,
        uint256 cliffDuration,
        uint256 duration
    );
    event LogRemoveVesting(uint256 id, address receiver, uint256 unvestedToken);
    event LogIncreaseVestingBalance(
        uint256 id,
        address receiver,
        uint256 oldTokenBalance,
        uint256 newTokenBalance
    );
    event LogDecreaseVestingBalance(
        uint256 id,
        address receiver,
        uint256 oldTokenBalance,
        uint256 newTokenBalance
    );
    event LogWithdraw(uint256 id, address receiver, uint256 amountOfTokens);

    // !!!!!!!!!!!!!!!!!!!!!!!! MODIFIER !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    modifier onlyProxyAdminOrReceiver(address _receiver) {
        require(
            msg.sender == _proxyAdmin() || msg.sender == _receiver,
            "LinearVestingHub:: only owner or receiver."
        );
        _;
    }

    constructor(IERC20 token_, address vestingTreasury_) {
        TOKEN = token_;
        VESTING_TREASURY = vestingTreasury_;
    }

    function initialize() external initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    // !!!!!!!!!!!!!!!!!!!!!!!! ADMIN FUNCTIONS !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    function pause() external onlyProxyAdmin {
        _pause();
    }

    function unpause() external onlyProxyAdmin {
        _unpause();
    }

    function withdrawAllTokens() external onlyProxyAdmin whenPaused {
        uint256 balance = TOKEN.balanceOf(address(this));
        require(balance > 0, "LinearVestingHub::withdrawAllTokens: 0 balance");
        TOKEN.safeTransfer(VESTING_TREASURY, balance);
    }

    function addVestings(Vesting[] calldata vestings_) external onlyProxyAdmin {
        uint256 totalBalance;
        for (uint256 i = 0; i < vestings_.length; i++) {
            _addVesting(vestings_[i]);

            emit LogAddVesting(
                vestings_[i].id,
                vestings_[i].receiver,
                vestings_[i].tokenBalance,
                vestings_[i].startTime,
                vestings_[i].cliffDuration,
                vestings_[i].duration
            );
            totalBalance = totalBalance + vestings_[i].tokenBalance;
        }

        TOKEN.safeTransferFrom(VESTING_TREASURY, address(this), totalBalance);

        emit LogAddVestings(totalBalance);
    }

    function addVesting(Vesting calldata vesting_) external onlyProxyAdmin {
        _addVesting(vesting_);
        TOKEN.safeTransferFrom(
            VESTING_TREASURY,
            address(this),
            vesting_.tokenBalance
        );

        emit LogAddVesting(
            vesting_.id,
            vesting_.receiver,
            vesting_.tokenBalance,
            vesting_.startTime,
            vesting_.cliffDuration,
            vesting_.duration
        );
    }

    function removeVesting(address receiver_, uint8 vestingId_)
        external
        onlyProxyAdminOrReceiver(receiver_)
    {
        Vesting memory vesting = vestingsByReceiver[receiver_][vestingId_];

        require(
            vesting.receiver != address(0),
            "LinearVestingHub::removeVesting: vesting non existing."
        );

        delete vestingsByReceiver[receiver_][vestingId_];
        _tryRemoveReceiver(receiver_);

        TOKEN.safeTransfer(VESTING_TREASURY, vesting.tokenBalance);

        emit LogRemoveVesting(
            vesting.id,
            vesting.receiver,
            vesting.tokenBalance
        );
    }

    function increaseVestingBalance(
        address receiver_,
        uint256 vestingId_,
        uint256 addend_
    ) external onlyProxyAdmin {
        Vesting storage vesting = vestingsByReceiver[receiver_][vestingId_];

        require(
            vesting.receiver != address(0),
            "LinearVestingHub::increaseVestingBalance: vesting non existing."
        );
        require(
            addend_ > 0,
            "LinearVestingHub::increaseVestingBalance: addend_ 0"
        );
        require(
            //solhint-disable-next-line not-rely-on-time
            block.timestamp < vesting.startTime + vesting.duration,
            "LinearVestingHub::increaseVestingBalance: cannot increase a completed vesting"
        );

        uint256 initTokenBalance = vesting.tokenBalance;
        vesting.tokenBalance = initTokenBalance + addend_;

        TOKEN.safeTransferFrom(VESTING_TREASURY, address(this), addend_);

        emit LogIncreaseVestingBalance(
            vestingId_,
            receiver_,
            initTokenBalance,
            vesting.tokenBalance
        );
    }

    // solhint-disable-next-line function-max-lines
    function decreaseVestingBalance(
        address receiver_,
        uint256 vestingId_,
        uint256 subtrahend_
    ) external onlyProxyAdmin {
        Vesting storage vesting = vestingsByReceiver[receiver_][vestingId_];

        uint256 startTime = vesting.startTime;
        uint256 duration = vesting.duration;
        uint256 initTokenBalance = vesting.tokenBalance;

        require(
            vesting.receiver != address(0),
            "LinearVestingHub::decreaseVestingBalance: vesting non existing."
        );
        require(
            subtrahend_ > 0,
            "LinearVestingHub::decreaseVestingBalance: subtrahend_ 0"
        );
        require(
            subtrahend_ <= initTokenBalance,
            "LinearVestingHub::decreaseVestingBalance: subtrahend_ gt remaining token balance"
        );
        require(
            //solhint-disable-next-line not-rely-on-time
            block.timestamp < startTime + duration,
            "LinearVestingHub::decreaseVestingBalance: cannot decrease a completed vesting"
        );

        require(
            _getTknMaxWithdraw(
                initTokenBalance,
                vesting.withdrawnTokens,
                startTime,
                vesting.cliffDuration,
                duration
            ) <= initTokenBalance - subtrahend_,
            "LinearVestingHub::decreaseVestingBalance: cannot decrease vested tokens"
        );

        uint256 newTokenBalance = initTokenBalance - subtrahend_;
        vesting.tokenBalance = newTokenBalance;

        if (newTokenBalance == 0) {
            delete vestingsByReceiver[receiver_][vestingId_];
            _tryRemoveReceiver(receiver_);
        }

        TOKEN.safeTransfer(VESTING_TREASURY, subtrahend_);

        emit LogDecreaseVestingBalance(
            vestingId_,
            receiver_,
            initTokenBalance,
            newTokenBalance
        );
    }

    // !!!!!!!!!!!!!!!!!!!!!!!! USER FUNCTIONS !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    // solhint-disable-next-line function-max-lines
    function withdraw(
        address receiver_,
        uint256 vestingId_,
        address to_,
        uint256 value_
    ) external whenNotPaused nonReentrant onlyProxyAdminOrReceiver(receiver_) {
        Vesting storage vesting = vestingsByReceiver[receiver_][vestingId_];

        uint256 startTime = vesting.startTime;
        uint256 cliffDuration = vesting.cliffDuration;
        uint256 initTokenBalance = vesting.tokenBalance;

        require(
            vesting.receiver != address(0),
            "LinearVestingHub::withdraw: vesting non existing."
        );
        require(value_ > 0, "LinearVestingHub::withdraw: value_ 0");
        require(
            //solhint-disable-next-line not-rely-on-time
            block.timestamp > startTime + cliffDuration,
            "LinearVestingHub::withdraw: cliffDuration period."
        );
        require(
            value_ <=
                _getTknMaxWithdraw(
                    initTokenBalance,
                    vesting.withdrawnTokens,
                    startTime,
                    cliffDuration,
                    vesting.duration
                ),
            "LinearVestingHub::withdraw: receiver try to withdraw more than max withdraw"
        );

        vesting.tokenBalance = initTokenBalance - value_;
        vesting.withdrawnTokens = vesting.withdrawnTokens + value_;
        totalWithdrawn = totalWithdrawn + value_;

        if (vesting.tokenBalance == 0) {
            delete vestingsByReceiver[receiver_][vestingId_];
            _tryRemoveReceiver(receiver_);
        }

        TOKEN.safeTransfer(to_, value_);

        emit LogWithdraw(vestingId_, receiver_, value_);
    }

    // !!!!!!!!!!!!!!!!!!!!!!!! HELPERS FUNCTIONS !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    function isReceiver(address receiver_) external view returns (bool) {
        return _receivers.contains(receiver_);
    }

    function receiverAt(uint256 index_) external view returns (address) {
        return _receivers.at(index_);
    }

    function receivers() external view returns (address[] memory r) {
        r = new address[](_receivers.length());
        for (uint256 i = 0; i < _receivers.length(); i++)
            r[i] = _receivers.at(i);
    }

    function numberOfReceivers() external view returns (uint256) {
        return _receivers.length();
    }

    // !!!!!!!!!!!!!!!!!!!!!!!! INTERNAL FUNCTIONS !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    function _addVesting(Vesting calldata vesting_) internal {
        uint256 nextVestingId = nextVestingIdByReceiver[vesting_.receiver];
        require(
            vesting_.receiver != address(0),
            "LinearVestingHub::_addVesting: invalid receiver"
        );
        require(
            nextVestingId == vesting_.id,
            "LinearVestingHub::_addVesting: wrong vesting id"
        );
        require(
            vesting_.tokenBalance > 0,
            "LinearVestingHub::_addVesting: 0 vesting_tokenBalance"
        );

        _receivers.add(vesting_.receiver);

        vestingsByReceiver[vesting_.receiver].push(vesting_);

        nextVestingIdByReceiver[vesting_.receiver] = nextVestingId + 1; // More explicit.
    }

    function _tryRemoveReceiver(address receiver_) internal {
        for (uint256 i = 0; i < nextVestingIdByReceiver[receiver_]; i++)
            if (vestingsByReceiver[receiver_][i].receiver != address(0)) return;

        _receivers.remove(receiver_);
    }
}
