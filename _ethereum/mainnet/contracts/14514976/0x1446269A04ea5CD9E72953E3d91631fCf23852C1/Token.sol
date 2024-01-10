// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./ERC20Burnable.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";

contract Token is Context, AccessControlEnumerable, ERC20, ERC20Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant CLAIMER_ROLE = keccak256("CLAIMER_ROLE");

    event logTokenTransfer(address token, address to, uint256 amount);

    constructor(uint256 initialSupply) ERC20("TreasuryBondToken", "tbUSD") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(CLAIMER_ROLE, _msgSender());
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC20: must have minter role to mint"
        );
        _mint(to, amount);
    }

    /**
     * @dev Claims `_amount` tokens for the token `_tokenContract`.
     *
     * Requirements:
     *
     * - the caller must have the `CLAIMER_ROLE`.
     */
    function claimTokens(address _tokenContract, uint256 _amount)
        external
    {
        require(
            hasRole(CLAIMER_ROLE, _msgSender()),
            "ERC20: must have claimer role to claim"
        );
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount); 
        emit logTokenTransfer(_tokenContract, msg.sender, _amount);
    }
}
