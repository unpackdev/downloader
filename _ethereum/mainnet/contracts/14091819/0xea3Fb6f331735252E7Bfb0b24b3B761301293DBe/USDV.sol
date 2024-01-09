// SPDX-License-Identifier: MIT AND AGPL-3.0-or-later

pragma solidity =0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

import "./ProtocolConstants.sol";

import "./IERC20Extended.sol";
import "./IUSDV.sol";
import "./IUnlockValidator.sol";

contract USDV is IUSDV, ProtocolConstants, ERC20, Ownable {
    /* ========== LIBRARIES ========== */

    // Used for safe token transfers
    using SafeERC20 for IERC20Extended;

    /* ========== STATE VARIABLES ========== */

    // The VADER token used for burns and mints
    IERC20Extended public immutable vader;

    // All mint/burn locks
    mapping(address => Lock[]) public locks;

    // Guardian Account
    address public guardian;

    // Lock system
    bool public isLocked;

    // Minter contract
    address public minter;

    // Validator contract
    IUnlockValidator public validator;

    /* ========== CONSTRUCTOR ========== */

    constructor(IERC20Extended _vader) ERC20("Vader USD", "USDV") {
        require(
            _vader != IERC20Extended(_ZERO_ADDRESS),
            "USDV::constructor: Improper Configuration"
        );
        vader = _vader;
    }

    /* ========== VIEWS ========== */
    /*
     * @dev Returns number of locks for {account}
     *
     * @param account
     **/
    function getLockCount(address account) external view returns (uint256) {
        return locks[account].length;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /*
     * @dev Mints the amount given represented by the param {vAmount}.
     *
     * @param account is msg.sender.
     * @param exchangeFee is VaderMinterUpgradable.getPublicFee()
     * @returns amount of USDV minted.
     *
     * Requirements:
     * - Contract is not locked.
     * - Only minter contract can call this function.
     * - Param {vAmount} can not be zero.
     * - Param {uAmount} can not be zero.
     **/
    function mint(
        address account,
        uint256 vAmount,
        uint256 uAmount,
        uint256 exchangeFee,
        uint256 window
    ) external onlyWhenNotLocked onlyMinter returns (uint256) {
        require(
            vAmount != 0 && uAmount != 0,
            "USDV::mint: Zero Input / Output"
        );
        require(
            window <= _MAX_LOCK_DURATION,
            "USDV::mint: Window > max lock duration"
        );

        vader.transferFrom(account, address(this), vAmount);
        vader.burn(vAmount);

        if (exchangeFee != 0) {
            uint256 fee = (uAmount * exchangeFee) / _MAX_BASIS_POINTS;
            uAmount = uAmount - fee;
            _mint(owner(), fee);
        }

        _mint(address(this), uAmount);

        _createLock(LockTypes.USDV, uAmount, account, window);

        return uAmount;
    }

    /*
     * @dev Burns the amount given represented by the param {uAmount}.
     *
     * @param account is msg.sender.
     * @param exchangeFee is VaderMinterUpgradable.getPublicFee()
     * @returns amount of Vader minted.
     *
     * Requirements:
     * - Contract is not locked.
     * - Only minter contract can call this function.
     * - Param {uAmount} can not be zero.
     * - Param {vAmount} can not be zero.
     **/
    function burn(
        address account,
        uint256 uAmount,
        uint256 vAmount,
        uint256 exchangeFee,
        uint256 window
    ) external onlyWhenNotLocked onlyMinter returns (uint256) {
        require(
            uAmount != 0 && vAmount != 0,
            "USDV::burn: Zero Input / Output"
        );
        require(
            window <= _MAX_LOCK_DURATION,
            "USDV::burn: Window > max lock duration"
        );

        _burn(account, uAmount);

        if (exchangeFee != 0) {
            uint256 fee = (vAmount * exchangeFee) / _MAX_BASIS_POINTS;
            vAmount = vAmount - fee;
            vader.mint(owner(), fee);
        }

        vader.mint(address(this), vAmount);

        _createLock(LockTypes.VADER, vAmount, account, window);

        return vAmount;
    }

    /*
     * @dev Claim vested tokens for lock index {i}.
     *
     * Requirements:
     * - Contract is not locked.
     **/
    function claim(uint256 i) external onlyWhenNotLocked returns (uint256) {
        Lock[] storage userLocks = locks[msg.sender];
        Lock memory lock = userLocks[i];

        require(lock.release <= block.timestamp, "USDV::claim: Vesting");
        require(
            validator.isValid(msg.sender, lock.amount, lock.token),
            "USDV::claim: Prohibited Claim"
        );

        uint256 last = userLocks.length - 1;
        if (i != last) {
            userLocks[i] = userLocks[last];
        }

        userLocks.pop();

        if (lock.token == LockTypes.USDV)
            _transfer(address(this), msg.sender, lock.amount);
        else vader.transfer(msg.sender, lock.amount);

        emit LockClaimed(msg.sender, lock.token, lock.amount, lock.release);

        return lock.amount;
    }

    /*
     * @dev Claim all vested tokens.
     *
     * Requirements:
     * - Contract is not locked.
     **/
    function claimAll()
        external
        onlyWhenNotLocked
        returns (uint256 usdvAmount, uint256 vaderAmount)
    {
        Lock[] memory userLocks = locks[msg.sender];
        delete locks[msg.sender];

        for (uint256 i = 0; i < userLocks.length; i++) {
            Lock memory lock = userLocks[i];

            require(lock.release <= block.timestamp, "USDV::claimAll: Vesting");
            require(
                validator.isValid(msg.sender, lock.amount, lock.token),
                "USDV::claimAll: Prohibited Claim"
            );

            if (lock.token == LockTypes.USDV) {
                _transfer(address(this), msg.sender, lock.amount);
                usdvAmount += lock.amount;
            } else {
                vader.transfer(msg.sender, lock.amount);
                vaderAmount += lock.amount;
            }

            emit LockClaimed(msg.sender, lock.token, lock.amount, lock.release);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /*
     * @dev Sets the validator implementation represented by the param {_validator}.
     *
     * Requirements:
     * - Only existing owner can call this function.
     * - Param {_validator} cannot be a zero address.
     **/
    function setValidator(IUnlockValidator _validator) external onlyOwner {
        require(
            _validator != IUnlockValidator(_ZERO_ADDRESS),
            "USDV::setValidator: Improper Configuration"
        );
        emit ValidatorSet(address(validator), address(_validator));
        validator = _validator;
    }

    /*
     * @dev Sets the guardian address represented by the param {_guardian}.
     *
     * Requirements:
     * - Only existing owner can call this function.
     * - Param {_guardian} cannot be a zero address.
     **/
    function setGuardian(address _guardian) external onlyOwner {
        require(_guardian != address(0), "USDV::setGuardian: Zero Address");
        emit GuardianSet(guardian, _guardian);
        guardian = _guardian;
    }

    /*
     * @dev Sets the lock mechanism status represented by the param {_lock}.
     *
     * Requirements:
     * - Only existing owner or guardian can call this function.
     **/
    function setLock(bool _lock) external {
        require(
            msg.sender == owner() || msg.sender == guardian,
            "USDV::setLock: Insufficient Privileges"
        );
        emit LockStatusSet(_lock);
        isLocked = _lock;
    }

    /*
     * @dev Sets the minter contract address represented by the param {_minter}.
     *
     * Requirements:
     * - Only existing owner can call this function.
     * - Param {_minter} cannot be a zero address.
     * - Minter is not already set.
     **/
    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "USDV::setMinter: Zero address");
        emit MinterSet(_minter);
        minter = _minter;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /* ========== PRIVATE FUNCTIONS ========== */

    /*
     * @dev Creates a lock by type with param {lockType} and amount with param {amount}.
     *
     **/
    function _createLock(
        LockTypes lockType,
        uint256 amount,
        address account,
        uint256 window
    ) private {
        if (window != 0) {
            uint256 release = block.timestamp + window;

            locks[account].push(Lock(lockType, amount, release));

            emit LockCreated(account, lockType, amount, release);
        } else if (lockType == LockTypes.USDV)
            _transfer(address(this), account, amount);
        else vader.transfer(account, amount);
    }

    /* ========== MODIFIERS ========== */
    modifier onlyWhenNotLocked() {
        require(!isLocked, "USDV::onlyWhenNotLocked: System is Locked");
        _;
    }

    modifier onlyMinter() {
        require(
            msg.sender == minter,
            "USDV::onlyMinter: Insufficient Privileges"
        );
        _;
    }
}
