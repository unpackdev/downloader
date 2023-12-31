// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// imported contracts and interfaces
import "./DepositWithdrawToken.sol";
import "./IMintableBurnable.sol";

import "./errors.sol";

contract CrossChainToken is DepositWithdrawToken, IMintableBurnable {
    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/

    /// @notice the address that is able to mint new tokens
    address public minter;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event MinterSet(address minter, address newMinter);

    event Burn(uint256 amount, string recipient);

    event BurnFor(address indexed from, uint256 amount, string recipient);

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _allowlist, address _underlying)
        DepositWithdrawToken(_name, _symbol, _decimals, _allowlist, _underlying)
        initializer
    {}

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/
    function initialize(string memory _name, string memory _symbol, address _owner, address _minter) external initializer {
        __DepositWithdrawToken_init(_name, _symbol, _owner);

        if (_minter == address(0)) revert BadAddress();

        minter = _minter;
    }

    /*///////////////////////////////////////////////////////////////
                       External Override Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the minter role
     * @param _minter is the address of the new minter
     */
    function setMinter(address _minter) external {
        _checkOwner();

        if (_minter == address(0) || _minter == minter) revert BadAddress();

        emit MinterSet(minter, _minter);

        minter = _minter;
    }

    /*///////////////////////////////////////////////////////////////
                            ERC20 Functions
    //////////////////////////////////////////////////////////////*/

    function mint(address _to, uint256 _amount) external override {
        if (msg.sender != minter) revert NoAccess();

        _checkPermissions(_to);

        _mint(_to, _amount);
    }

    function burn(uint256 _amount) external override {
        _checkPermissions(msg.sender);

        _burn(msg.sender, _amount);
    }

    /**
     * @notice burns tokens and emits Burn event to initiate transfer to a recipient on the foreign chain
     * @param _amount The amount of tokens to burn
     * @param _recipient The recipient of the burn, address on the foreign chain
     */
    function burn(uint256 _amount, string memory _recipient) external {
        _checkPermissions(msg.sender);

        emit Burn(_amount, _recipient);

        _burn(msg.sender, _amount);
    }

    /**
     * @notice burns tokens for a user and emits BurnFor event to initiate transfer to a recipient on the foreign chain
     * @param _from The address to burn tokens for
     * @param _amount The amount of tokens to burn
     * @param _recipient The recipient of the burn, address on the foreign chain
     * @param _v signature recovery byte
     * @param _r signature r value
     * @param _s signature s value
     */
    function burnFor(address _from, uint256 _amount, string memory _recipient, uint8 _v, bytes32 _r, bytes32 _s) external {
        _checkPermissions(msg.sender);
        _assertBurnForSignature(_from, _amount, _recipient, _v, _r, _s);

        emit BurnFor(_from, _amount, _recipient);

        _burn(_from, _amount);
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    function _assertBurnForSignature(address _from, uint256 _amount, string memory _recipient, uint8 _v, bytes32 _r, bytes32 _s)
        internal
    {
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
                                keccak256("BurnFor(address from,uint256 amount,string recipient,uint256 nonce)"),
                                _from,
                                _amount,
                                _recipient,
                                nonces[_from]++
                            )
                        )
                    )
                ),
                _v,
                _r,
                _s
            );

            if (recoveredAddress == address(0) || recoveredAddress != _from) revert InvalidSignature();
        }
    }
}
