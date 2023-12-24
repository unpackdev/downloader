// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title Reservable
 */

import "./GluwacoinBase.sol";

import "./ERC20Upgradeable.sol";
import "./Validate.sol";
import "./SignerNonce.sol";

contract ERC20Reservable is GluwacoinBase, SignerNonce, ERC20Upgradeable {
    enum ReservationStatus {
        Draft, // 0
        Active, // 1
        Reclaimed, // 2
        Completed // 3
    }

    struct Reservation {
        uint96 amount;
        uint96 fee;
        address recipient;
        address executor;
        uint64 expiryBlockNum; /// @dev to ensure the return reservation object is compatible to the current BE
        ReservationStatus status;
    }

    uint64 public constant MINIMUM_BLOCK_FOR_RESERVATION = 14400;

    // Total balance of all active reservations per address
    mapping(address => uint256) private _totalReserved;

    // Mapping of all reservations per address and nonces
    mapping(address => mapping(uint256 => Reservation)) private _reservation;

    function __Reservable_init_unchained() internal onlyInitializing {}

    function _reserve(
        address from_,
        address to_,
        address executor_,
        uint96 amount_,
        uint96 executionFee_,
        uint256 nonce_,
        uint64 deadline_
    ) private {
        require(
            balanceOf(from_) >= amount_ + executionFee_,
            "Reservable: reserve amount exceeds balance"
        );
        _reservation[from_][nonce_] = Reservation(
            amount_,
            executionFee_,
            to_,
            executor_,
            deadline_,
            ReservationStatus.Active
        );
        unchecked {
            _totalReserved[from_] += amount_ + executionFee_;
        }
    }

    function reserve(
        address sender,
        address recipient,
        address executor,
        uint96 amount,
        uint96 fee,
        uint256 gluwaNonce,
        uint64 deadline_,
        bytes calldata sig
    ) external virtual returns (bool success) {
        require(
            executor != address(0),
            "Reservable: cannot execute from zero address"
        );
        require(
            deadline_ >= block.number + MINIMUM_BLOCK_FOR_RESERVATION,
            "Reservable: invalid block expiry number"
        );
        _useNonce(sender, gluwaNonce);

        bytes32 hash_ = keccak256(
            abi.encodePacked(
                _GENERIC_SIG_RESERVE_DOMAIN,
                block.chainid,
                address(this),
                sender,
                recipient,
                executor,
                amount,
                fee,
                gluwaNonce,
                deadline_
            )
        );
        Validate._validateSignature(hash_, sender, sig);
        _reserve(
            sender,
            recipient,
            executor,
            amount,
            fee,
            gluwaNonce,
            deadline_
        );
        return true;
    }

    function reserveOf(address account_) external view returns (uint256 count) {
        return _totalReserved[account_];
    }

    function getReservation(
        address account_,
        uint256 nonce_
    ) external view returns (Reservation memory) {
        return _reservation[account_][nonce_];
    }

    function _execute(address from_, Reservation storage reservation) private {
        address sender = _msgSender();
        require(
            reservation.executor == sender || from_ == sender,
            "Reservable: not authorized to execute"
        );
        require(
            reservation.expiryBlockNum > block.number &&
                reservation.status == ReservationStatus.Active,
            "Reservable: expired or invalid reservation status"
        );

        uint256 fee = reservation.fee;
        uint96 amount = reservation.amount;
        address recipient = reservation.recipient;
        address executor = reservation.executor;

        reservation.status = ReservationStatus.Completed;
        unchecked {
            _totalReserved[from_] -= amount + fee;
        }

        _transfer(from_, executor, fee);
        _transfer(from_, recipient, amount);
    }

    function execute(
        address from_,
        uint256 nonce_
    ) external returns (bool success) {
        _execute(from_, _reservation[from_][nonce_]);
        return true;
    }

    function reclaim(
        address from_,
        uint256 nonce_
    ) external returns (bool success) {
        Reservation storage reservation = _reservation[from_][nonce_];
        address sender = _msgSender();

        require(
            reservation.status == ReservationStatus.Active,
            "Reservable: invalid reservation status"
        );       

        require(
            from_ == sender || sender == reservation.executor,
            "Reservable: only the sender or the executor to call"
        );
        require(
            reservation.expiryBlockNum <= block.number ||
                sender == reservation.executor,
            "Reservable: reservation not expired or you not executor"
        );

        reservation.status = ReservationStatus.Reclaimed;
        unchecked {
            _totalReserved[from_] -= reservation.amount + reservation.fee;
        }

        return true;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256 amount) {
        return super.balanceOf(account) - _totalReserved[account];
    }

    uint256[50] private __gap;
}
