// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";
import "./GluwacoinModel.sol";

import "./Validate.sol";

/**
 * @dev Extension of {ERC20} that allows a certain ERC20 token holders to wrap the token to mint this token.
 * Holder of this token can retrieve the wrapped token by burning this token.
 */
abstract contract ERC20Wrapper is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ERC20Upgradeable
{    
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // base token, the token to be wrapped
    IERC20Upgradeable internal _token;

    mapping(address => mapping(uint256 => bool)) private _usedNonces;

    // collects mint/burn relay fee
    bytes32 public constant WRAPPER_ROLE = keccak256("WRAPPER_ROLE");

    event Mint(address indexed _mintTo, uint256 _value);
    event Burnt(address indexed _burnFrom, uint256 _value);

    function __ERC20Wrapper_init(
        string memory name,
        string memory symbol,
        IERC20Upgradeable baseToken
    ) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Wrapper_init_unchained(baseToken);
    }

    function __ERC20Wrapper_init_unchained(IERC20Upgradeable baseToken)
        internal
        virtual
        onlyInitializing
    {
        _setupToken(baseToken);
        _setupRole(WRAPPER_ROLE, _msgSender());
    }

    /**
     * @dev Returns the address of the base token.
     */
    function token() external view returns (IERC20Upgradeable) {
        return _token;
    }

    /**
     * @dev Creates `amount` tokens to the caller, transferring base tokens from the caller to the contract.
     *
     * See {ERC20-_mint} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have base tokens of at least `amount`.
     * - the contract must have allowance for caller's base tokens of at least
     * `amount`.
     */
    function mint(uint256 amount) external {
        __mint(_msgSender(), amount);
    }

    /**
     * @dev `mint` but with `minter`, `fee`, `nonce`, and `sig` as extra parameters.
     * `fee` is a mint fee amount in Gluwacoin, which the minter will pay for the mint.
     * `sig` is a signature created by signing the mint information with the minter’s private key.
     * Anyone can initiate the mint for the minter by calling the Etherless Mint function
     * with the mint information and the signature.
     * The caller will have to pay the gas for calling the function.
     *
     * Transfers `amount` + `fee` of base tokens from the minter to the contract using `transferFrom`.
     * Creates `amount` + `fee` of tokens to the minter and transfers `fee` tokens to the caller.
     *
     * See {ERC20-_mint} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the minter must have base tokens of at least `amount`.
     * - the contract must have allowance for receiver's base tokens of at least `amount`.
     * - `fee` will be deducted after successfully minting
     */
    function mint(
        address minter,
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        bytes calldata sig
    ) external virtual {
        _useWrapperNonce(minter, nonce);

        bytes32 hash = keccak256(
            abi.encodePacked(
                GluwacoinModel.SigDomain.Mint,
                block.chainid,
                address(this),
                minter,
                amount,
                fee,
                nonce
            )
        );
        Validate.validateSignature(hash, minter, sig);

        __mint(minter, amount);

        address wrapper = getRoleMember(WRAPPER_ROLE, 0);

        _transfer(minter, wrapper, fee);
    }

    /**
     * @dev Destroys `amount` tokens from the caller, transferring base tokens from the contract to the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external {
        __burn(_msgSender(), amount);
    }

    /**
     * @dev `burn` but with `burner`, `fee`, `nonce`, and `sig` as extra parameters.
     * `fee` is a burn fee amount in Gluwacoin, which the burner will pay for the burn.
     * `sig` is a signature created by signing the burn information with the burner’s private key.
     * Anyone can initiate the burn for the burner by calling the Etherless Burn function
     * with the burn information and the signature.
     * The caller will have to pay the gas for calling the function.
     *
     * Destroys `amount` + `fee` tokens from the burner.
     * Transfers `amount` of base tokens from the contract to the burner and `fee` of base token to the caller.
     *
     * See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - the burner must have tokens of at least `amount`, the `fee` is included in the amount.
     */
    function burn(
        address burner,
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        bytes calldata sig
    ) external virtual {
        uint256 burnerBalance = balanceOf(burner);
        require(
            burnerBalance >= amount,
            "ERC20Wrapper: burn amount exceed balance"
        );

        _useWrapperNonce(burner, nonce);

        bytes32 hash = keccak256(
            abi.encodePacked(
                GluwacoinModel.SigDomain.Burn,
                block.chainid,
                address(this),
                burner,
                amount,
                fee,
                nonce
            )
        );
        Validate.validateSignature(hash, burner, sig);

        address wrapper = getRoleMember(WRAPPER_ROLE, 0);
        _transfer(burner, wrapper, fee);

        __burn(burner, amount - fee);
    }    

    function __mint(address account, uint256 amount) internal virtual {
        _token.safeTransferFrom(account, address(this), amount);
        emit Mint(account, amount);

        _mint(account, amount);
    }

    function __burn(address account, uint256 amount) internal virtual {       
        _token.safeTransfer(account, amount);
        emit Burnt(account, amount);

        _burn(account, amount);
    }

    /**
     * @dev Sets {token} as the base token.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {token} to ever change, and may work incorrectly if it does.
     */
    function _setupToken(IERC20Upgradeable token_) internal {
        _token = token_;
    }

    /* @dev Uses `nonce` for the signer.
     */
    function _useWrapperNonce(address signer, uint256 nonce) internal {
        require(
            !_usedNonces[signer][nonce],
            "ERC20Wrapper: the nonce has already been used for this address"
        );
        _usedNonces[signer][nonce] = true;
    }

    uint256[50] private __gap;
}
