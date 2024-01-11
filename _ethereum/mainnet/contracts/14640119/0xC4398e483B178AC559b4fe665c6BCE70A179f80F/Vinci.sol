// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./TokenTimelock.sol";
import "./VinciSale.sol";

contract Vinci is ERC20, Ownable {
    constructor() ERC20("Vinci", "VINCI") {
        _mint(address(this), 200 * 500 * 10**6 * 10**18);
    }

    event TokenLocked(
        address indexed beneficiary,
        uint256 amount,
        uint256 releaseTime,
        address contractAddress
    );

    event SalesContract(
        uint256 amount,
        uint256 releaseTime,
        uint256 vinciTokenPrice,
        address contractAddress
    );

    /**
     * @dev Creates new TokenTimelock contract (from openzeppelin) and
     * locks `amount` tokens in it.
     *
     * The arguments `beneficiary` and `releaseTime` are passed to the
     * TokenTimelock contract. Returns the address of the newly created
     * TokenTimelock contract.
     *
     * Emits a {TokenLocked} event.
     *
     * Requirements:
     *
     * - `beneficiary` cannot be the zero address.
     * - `releaseTime` must be in the future (compared to `block.timestamp`).
     */
    function lockTokens(
        address beneficiary,
        uint256 amount,
        uint256 releaseTime
    ) public onlyOwner returns (address) {
        TokenTimelock token_timelock_contract = new TokenTimelock(
            IERC20(this),
            beneficiary,
            releaseTime
        );

        _transfer(address(this), address(token_timelock_contract), amount);

        emit TokenLocked(
            beneficiary,
            amount,
            releaseTime,
            address(token_timelock_contract)
        );

        return address(token_timelock_contract);
    }

    /**
     * @dev Withdraw tokens from contract
     *
     * Withdraw unlocked tokens from contract.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     */
    function withdraw(address recipient, uint256 amount) public onlyOwner {
        _transfer(address(this), recipient, amount);
    }

    /**
     * @dev Creates a VinciSale sales contract with the specified `vinciAmount`
     * and `vinciTokenPrice`.
     *
     * Note that vinciTokenPrice is specified in the exchangeAsset unit, and
     * the price is for 1 Token (i.e. 10**18 amount of vinci). If the specifed
     * `releaseTime` is in the past, tokens will be paid out immediately.
     * Otherwise they will be stored in a TokenTimelock Contract.
     *
     * Emits a {SalesContract} event.
     */
    function createSalesContract(
        IERC20 exchangeAsset,
        uint256 vinciTokenPrice,
        uint256 releaseTime,
        uint256 vinciAmount
    ) public onlyOwner {
        VinciSale vinci_sale = new VinciSale(
            exchangeAsset,
            IERC20(this),
            vinciTokenPrice,
            releaseTime,
            _msgSender()
        );

        emit SalesContract(
            vinciAmount,
            releaseTime,
            vinciTokenPrice,
            address(vinci_sale)
        );

        _transfer(address(this), address(vinci_sale), vinciAmount);
    }
}
