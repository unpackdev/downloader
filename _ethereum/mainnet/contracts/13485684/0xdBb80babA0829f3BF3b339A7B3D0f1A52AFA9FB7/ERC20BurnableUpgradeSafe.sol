pragma solidity ^0.6.0;

import "./Initializable.sol";
import "./ContextUpgradeSafe.sol";
import "./ERC20UpgradeSafe.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */



// interface MasterChef{
//      function checkHighestStaker(uint256 _pid, address user) external returns (bool);
//      function checkStakingScoreForDelegation(uint256 _pid, address user) external  returns (bool);
    
// }



abstract contract ERC20BurnableUpgradeSafe is Initializable, ContextUpgradeSafe, ERC20UpgradeSafe {

    // address public chefAddress;
    // uint256 public deployedtimestamp=block.timestamp;
    // constructor() public{
    //       deployedtimestamp=block.timestamp;

    // }

    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {

    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    //to set chef contract address
    // function setChefAddress(address _chefaddress) external{
    //     chefAddress=_chefaddress;

    // }

    uint256[50] private __gap;
}