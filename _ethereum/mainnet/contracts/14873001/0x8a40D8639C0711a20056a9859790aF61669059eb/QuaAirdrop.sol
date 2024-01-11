// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IERC20.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

contract QuaAirdrop is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public fee;
    address payable public commissionAddress;

    event MultisendCurrency(uint256 amount);
    event MultisendTokens(address token, uint256 amount);
    event WithdrawCurrency(address to, uint256 amount);
    event WithdrawTokens(address token, address to, uint256 amount);

    /**
     * @notice used in multisendCurrency/Tokens,
     * revert transaction if fee not included in msg.value,
     * also transfer fee to commissionAddress
     * @param distributedAmount amount of currency, that will be airdrop
     */
    modifier includeFee(uint256 distributedAmount) {
        require(msg.value - distributedAmount == fee, "Wrong amount paid");
        _;
        commissionAddress.transfer(fee);
    }

    /**
     * @param owner address of owner, will have DEFAULT_ADMIN_ROLE
     * @param _fee amount of fee in wei
     * @param _commissionAddress commission will be sended to this address
     */
    constructor(
        address owner,
        uint256 _fee,
        address payable _commissionAddress
    ) {
        _setupRole(0x00, owner);
        fee = _fee;
        commissionAddress = _commissionAddress;
    }

    /**
     * @notice this method used for multisend currency (eth, bnb),
     * fire MultisendCurrency event
     * @param addresses list of addresses included in airdrop
     * @param amounts list of amounts of currency, amounts[i] will be sended
     * to addresses[i]
     * @param total total amount of currency, that will be sended
     */
    function multisendCurrency(
        address payable[] calldata addresses,
        uint256[] calldata amounts,
        uint256 total
    ) external payable nonReentrant includeFee(total) {
        require(addresses.length == amounts.length, "Lengths are not equal");

        uint256 _total;
        for (uint256 i = 0; i < addresses.length; i++) {
            _total += amounts[i];
            addresses[i].transfer(amounts[i]);
        }

        require(total == _total, "Wrong total amount");

        emit MultisendCurrency(_total);
    }

    /**
     * @notice this method used for multisend tokens,
     * fire MultisendTokens event
     * @param token address of sended token,
     * tokens must be approved total before call this func
     * @param addresses list of addresses included in airdrop
     * @param amounts list of amounts of currency that will be sended
     * to addresses[i]
     * @param total total amount of tokens, that will be sended
     */
    function multisendTokens(
        IERC20 token,
        address[] calldata addresses,
        uint256[] calldata amounts,
        uint256 total
    ) external payable nonReentrant includeFee(0) {
        require(addresses.length == amounts.length, "Lengths are not equal");
        require(address(token) != address(0), "Token: zero address");
        require(
            token.balanceOf(_msgSender()) >= total,
            "Token: do not enouth tokens"
        );
        token.safeTransferFrom(_msgSender(), address(this), total);

        uint256 _total;
        for (uint256 i = 0; i < addresses.length; i++) {
            _total += amounts[i];
            token.safeTransfer(addresses[i], amounts[i]);
        }

        require(total == _total, "Wrong total amount");

        emit MultisendTokens(address(token), _total);
    }

    /**
     * @notice allow admin withdraw excess tokens from this contract,
     * fire WithdrawTokens event
     * @param token address of withdrawal token
     */
    function withdrawTokens(IERC20 token) external onlyRole(0x0) nonReentrant {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");
        token.safeTransfer(_msgSender(), balance);
        emit WithdrawTokens(address(token), _msgSender(), balance);
    }

    /**
     * @notice allow admin withdraw excess currency from this contract,
     * fire WithdrawCurrency event
     */
    function withdrawCurrency() external onlyRole(0x0) nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to withdraw");
        payable(_msgSender()).transfer(balance);
        emit WithdrawCurrency(_msgSender(), balance);
    }

    /**
     * @notice allow admin set new fee amount
     * @param newFee new fee amount in wei
     */
    function setFee(uint256 newFee) external onlyRole(0x00) {
        fee = newFee;
    }

    /**
     * @notice allow admin set new commissionAddres
     * @param newCommissionAddress new commission address
     */
    function setCommissionAddress(address payable newCommissionAddress)
        external
        onlyRole(0x00)
    {
        commissionAddress = newCommissionAddress;
    }
}
