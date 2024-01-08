// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./SafeMath.sol";

import "./IBridgeToken.sol";
import "./Version0.sol";

contract BridgeToken is
    Version0,
    IBridgeToken,
    ERC20Upgradeable,
    OwnableUpgradeable
{
    // ============ Memory ============
    using SafeMath for uint256;

    mapping(address => uint256) private balances;

    mapping(address => mapping(address => uint256)) private allowances;

    uint256 private supply;

    struct Token {
        string name;
        string symbol;
        uint8 decimals;
    }

    Token internal token;

    uint256[49] private __gap;

    // ============ Initializer ============

    function initialize(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals
    ) public initializer {
        __Ownable_init();
        token.name = _name;
        token.symbol = _symbol;
        token.decimals = _decimals;
    }

    // ============ External Functions ============

    /** @notice Creates `_amnt` tokens and assigns them to `_to`, increasing
     * the total supply.
     * @dev Emits a {Transfer} event with `from` set to the zero address.
     * Requirements:
     * - `to` cannot be the zero address.
     * @param _to The destination address
     * @param _amnt The amount of tokens to be minted
     */
    function mint(address _to, uint256 _amnt) external override onlyOwner {
        _mint(_to, _amnt);
    }

    /**
     * @notice Destroys `_amnt` tokens from `_from`, reducing the
     * total supply.
     * @dev Emits a {Transfer} event with `to` set to the zero address.
     * Requirements:
     * - `_from` cannot be the zero address.
     * - `_from` must have at least `_amnt` tokens.
     * @param _from The address from which to destroy the tokens
     * @param _amnt The amount of tokens to be destroyed
     */
    function burn(address _from, uint256 _amnt) external override onlyOwner {
        _burn(_from, _amnt);
    }

    /**
     * @dev This is calculated at runtime
     * because the token name may change
     */
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        uint256 _chainId;
        assembly {
            _chainId := chainid()
        }
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(token.name)),
                    keccak256(abi.encodePacked(VERSION)),
                    _chainId,
                    address(this)
                )
            );
    }

    // ============ ERC 20 ============

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return token.name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory) {
        return token.symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view override returns (uint8) {
        return token.decimals;
    }
}
