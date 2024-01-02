// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Uncomment this line to use console.log
import "./ERC20.sol";
import "./Multicall.sol";

contract GigaCommunis is ERC20, Multicall {
    address constant public COMM = 0x5A9780Bfe63f3ec57f01b087cD65BD656C9034A8;
    uint256 constant public GIGA = 1000**3; // giga (should be 1024**3 but this is easier for humans)
    constructor() ERC20("Giga Communis", "gCOMM") {}
    /**
     * burn a number of tokens and transfer said tokens out of this contract
     * @param payer the account that will pay for the tokens
     * @param amount the number of tokens that will be burned
     * @param recipient the recipient of the tokens
     */
    function _burnTo(address payer, uint256 amount, address recipient) internal {
        _burn(payer, amount);
        ERC20(COMM).transfer(recipient, amount * GIGA);
    }
    /**
     * check for excess balances of a given token
     * @param target the target contract to check
     */
    function _excess(address target) internal view returns(uint256 limit) {
        limit = ERC20(target).balanceOf(address(this));
        if (target == COMM) {
            unchecked {
                // if comm, limit withdrawal only to Comm.balance - GigaComm.balance*GIGA
                uint256 outstanding = (totalSupply() * GIGA);
                // prevent a panic revert
                limit = outstanding > limit ? 0 : (limit - outstanding);
            }
        }
    }
    /**
     * mints a given number of tokens to the sender after communis tokens are custodied
     * @param amount number of tokens to mint to the sender
     */
    function mint(uint256 amount) external {
        ERC20(COMM).transferFrom(msg.sender, address(this), amount * GIGA);
        _mint(msg.sender, amount);
    }
    /**
     * mint a number of tokens to a given account
     * @param account an account to mint tokens to
     * @param amount the number of tokens to mint to the given account
     * @notice it would be best if transferFrom were called
     * in the same transaction using multicall
     * to remove the possibility of tokens being removed from the contract
     */
    function mintFromExcess(address account, uint256 amount) external {
        uint256 limit = _excess({
            target: COMM
        });
        if (limit > 0) {
            amount = amount == 0 || amount > limit ? limit : amount;
            _mint(account, amount);
        }
    }
    /**
     * burn a given number of tokens and transfer the underlying communis tokens to sender
     * @param amount number of tokens to burn of the sender's balance
     * @notice this method should basically match the ERC20Burnable.burn implementation from oz
     */
    function burn(uint256 amount) external {
        _burnTo({
            payer: msg.sender,
            amount: amount,
            recipient: msg.sender
        });
    }
    /**
     * burn a given number of tokens and release the underlying to an address
     * @param account the account that will provide gCOMM funding
     * @param amount the number of tokens to burn
     * @notice spend allowance must be deducted to reduce funny business
     * @notice this method should basically match the ERC20Burnable.burnFrom implementation from oz
     */
    function burnFrom(address account, uint256 amount) external {
        _spendAllowance(account, msg.sender, amount);
        _burnTo({
            payer: account,
            amount: amount,
            recipient: account
        });
    }
    /**
     * burn a given number of tokens, custodied by this contract
     * @param amount the number of tokens to burn
     * @notice this contract can only burn gCOMM
     * @notice the underlying COMM must be trimmed
     * out of the contract after this method is run
     */
    function burnFromExcess(uint256 amount) external {
        uint256 limit = ERC20(address(this)).balanceOf(address(this));
        if (limit > 0) {
            amount = amount == 0 || amount > limit ? limit : amount;
            _burn(address(this), amount);
        }
    }
    /**
     * remove surplus tokens from the contract
     * @param target the token to transfer out of the contract
     * @param amount the amount of a token to transfer out (limited by outstanding if comm)
     * @param to the recipient of the token
     */
    function trim(address target, uint256 amount, address to) external {
        uint256 limit = _excess({
            target: target
        });
        amount = amount == 0 || amount > limit ? limit : amount;
        if (amount > 0) {
            ERC20(target).transfer(to, amount);
        }
    }
    /**
     * exposes the _excess method to check the amount of balance available for trimming
     * @param target the token to check excess balance for trimming
     */
    function excess(address target) external view returns(uint256) {
        return _excess({
            target: target
        });
    }
}
