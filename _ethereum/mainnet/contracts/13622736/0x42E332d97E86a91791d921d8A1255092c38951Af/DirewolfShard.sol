// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./ERC20PresetMinterPauser.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";


/**
 * @title Direwolf Shard
 * @dev ERC20 Token for the Direwolf token migration
 * Deployed on 15 November 2021
 */
contract DirewolfShard is ERC20PresetMinterPauser {

    // The Direwolf v1 contract address on Mainnet
    IERC20 public immutable direwolf1 = IERC20(address(0xBdea5bB640DBFC4593809DEeC5CdB8F99b704Cd2));

    // Roles to allow for the staff to call protected functions
    bytes32 public constant STAFF_ROLE = keccak256("STAFF_ROLE");

    // Control boolean to enable/disable deposit of Direwolf v1
    bool public depositIsActive = true;


    /**
     * @dev Grants `STAFF_ROLE` to the account that deploys the contract
     *
     * See {ERC20}.
     */
    constructor() ERC20PresetMinterPauser("Direwolf Shard", "DWS") {
        _setupRole(STAFF_ROLE, _msgSender());
    }


    /**
     * @dev Override the default decimals of 18 in ERC20.sol to make it 2, in line with Direwolf v1
     */
    function decimals() public view virtual override returns (uint8) {
        return 2;
    }


    /**
     * @dev Allow a user to deposit Direwolf v1 tokens and mint the corresponding number of Direwolf Shard tokens
     */
    function deposit() external {
        require(depositIsActive, "Deposit is not active.");

        // Get the total balance of Direwolf v1 tokens for the caller
        uint256 amount = direwolf1.balanceOf(_msgSender());
        require(amount > 0, "Insufficient Direwolf v1 tokens.");

        // Transfer all Direwolf v1 tokens to this contract
        SafeERC20.safeTransferFrom(direwolf1, _msgSender(), address(this), amount);

        // There are 34 quadrillion Direwolf v1 in circulation, which should match 10 billion Direwolf Shard
        // So we need to divide by 3.4 milion to get from Direwolf v1 to Direwolf Shard
        uint256 amount_to_mint = SafeMath.div(amount, 3400000);

        // Mint new Direwolf Shard tokens for the caller
        _mint(_msgSender(), amount_to_mint);
    }


    /**
     * @dev Allow a user with the STAFF_ROLE to flip the boolean state of depositIsActive to enable/disable deposit of Direwolf v1
     */
    function flipDepositState() external {
        require(hasRole(STAFF_ROLE, _msgSender()), "Must have staff role to call this function.");
        depositIsActive = !depositIsActive;
    }


    /**
     * @dev Allow a user with the STAFF_ROLE to withdraw all Direwolf v1 tokens currently stored in this contract.
     */
    function withdraw() external {
        require(hasRole(STAFF_ROLE, _msgSender()), "Must have staff role to call this function.");

        uint256 amount = direwolf1.balanceOf(address(this));
        SafeERC20.safeTransfer(direwolf1, _msgSender(), amount);
    }
}
