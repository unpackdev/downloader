// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.4;



import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */    
    
contract RGP is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;


    function initialize() initializer public {
    //   __ERC20_init(_name, _symbol);
      __ERC20_init_unchained("RR Global Point", "RGP");
      __Ownable_init_unchained();
    //   __UUPSUpgradeable_init();

      _mint(msg.sender, 1000 * 10 ** decimals());
    }


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function mintTo(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function mint( uint256 _amount) public onlyOwner {
        _mint(msg.sender, _amount);
    }
}