// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// imported contracts
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20.sol";

import "./PermissionedToken.sol";

// interfaces
import "./IERC20Metadata.sol";

import "./errors.sol";

abstract contract DepositWithdrawToken is ReentrancyGuardUpgradeable, PermissionedToken {
    using SafeERC20 for IERC20Metadata;

    /*///////////////////////////////////////////////////////////////
                            Immutables
    //////////////////////////////////////////////////////////////*/

    /// @notice the address of the underlying erc-20 token
    IERC20Metadata public immutable underlying;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _allowlist, address _underlying)
        PermissionedToken(_name, _symbol, _decimals, _allowlist)
        initializer
    {
        underlying = IERC20Metadata(_underlying);
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/
    function __DepositWithdrawToken_init(string memory _name, string memory _symbol, address _owner) internal onlyInitializing {
        __PermissionedToken_init(_name, _symbol, _owner);
    }

    /*///////////////////////////////////////////////////////////////
                       External Override Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposits underlying to mint wrapped version
     * @param _amount is the amount of coin to deposit
     */
    function deposit(uint256 _amount) external virtual nonReentrant returns (uint256) {
        return _depositFor(msg.sender, msg.sender, _amount);
    }

    /**
     * @notice Deposits underlying to mint wrapped version to a recipient
     * @param _recipient is the address of the recipient
     * @param _amount is the amount of coin to deposit
     */
    function depositFor(address _recipient, uint256 _amount) external virtual nonReentrant returns (uint256) {
        return _depositFor(msg.sender, _recipient, _amount);
    }

    /**
     * @notice Withdraws underlying by burning wrapped token
     * @param _amount is the amount of wrapped token to burn
     */
    function withdraw(uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s) external virtual nonReentrant returns (uint256) {
        return _withdrawTo(msg.sender, _amount, _v, _r, _s);
    }

    /**
     * @notice Withdraws underlying by burning wrapped token and sends to a recipient
     * @param _recipient is the address of the recipient
     * @param _amount is the amount of wrapped token to burn
     */
    function withdrawTo(address _recipient, uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s)
        external
        virtual
        nonReentrant
        returns (uint256)
    {
        return _withdrawTo(_recipient, _amount, _v, _r, _s);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposits underlying to mint wrapped version to a recipient
     * @param _from is the address to draw from
     * @param _recipient is the address of the recipient
     * @param _amount is the amount of underlying to deposit (underlying decimals)
     */
    function _depositFor(address _from, address _recipient, uint256 _amount) internal virtual returns (uint256) {
        if (_amount == 0) revert BadAmount();
        if (address(underlying) == address(0)) revert();

        if (_from != address(this)) _checkPermissions(_from);
        _checkPermissions(_recipient);

        _mint(_recipient, _amount);

        emit Deposit(_recipient, _amount);

        if (_from != address(this)) underlying.safeTransferFrom(_from, address(this), _amount);

        return _amount;
    }

    /**
     * @notice Withdraws a underlying by burning the wrapper and sends to a recipient
     * @param _recipient is the address of the recipient
     * @param _amount is the amount of wrapper to burn
     */
    function _withdrawTo(address _recipient, uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s)
        internal
        virtual
        returns (uint256)
    {
        if (_amount == 0) revert BadAmount();
        if (address(underlying) == address(0)) revert();

        _checkPermissions(msg.sender);
        if (_recipient != msg.sender) _checkPermissions(_recipient);

        _assertWithdrawSignature(_recipient, _amount, _v, _r, _s);

        _burn(msg.sender, _amount);

        emit Withdrawal(_recipient, _amount);

        underlying.safeTransfer(_recipient, _amount);

        return _amount;
    }

    function _assertWithdrawSignature(address _to, uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s) internal {
        if (address(underlying) == address(0)) revert();

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256("Withdraw(address to,uint256 amount,uint256 nonce)"), _to, _amount, nonces[_to]++
                            )
                        )
                    )
                ),
                _v,
                _r,
                _s
            );

            if (recoveredAddress == address(0) || recoveredAddress != owner()) revert InvalidSignature();
        }
    }
}
