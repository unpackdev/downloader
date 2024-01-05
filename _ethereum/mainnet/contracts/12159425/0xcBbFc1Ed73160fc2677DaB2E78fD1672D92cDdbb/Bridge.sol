// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IPermittableToken.sol";
import "./IERC20.sol";

contract Bridge is Ownable {
    using SafeMath for uint256;

    event Deposit(address indexed recipient, uint value);
    event DepositFor(address indexed sender, uint value, address indexed recipient);
    event Withdrawal(address indexed src, uint value);
    event WithdrawalTo(address indexed sender, uint value, address indexed recipient);
    event DepositTokenFor(address indexed sender, uint amount, address indexed recipient, address indexed tokenAddress);
    event TokenWithdrawal(address indexed sender, address indexed token, uint value, address indexed recipient);
    event DepositWithdrawn(
        address indexed token,
        uint depositValue,
        uint fee,
        uint withdrawAmount,
        bytes32 txHash,
        address indexed recipient,
        bytes32 depositId
    );

    mapping (address => uint256) internal _balances;
    mapping (bytes32 => bool) internal _withdrawnDeposits;

    constructor() public Ownable() {}

    receive() external payable {
        deposit();
    }

    function deposit() virtual public payable {
        _balances[owner()] = _balances[owner()].add(msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function depositFor(address recipient) virtual public payable {
        _balances[owner()] = _balances[owner()].add(msg.value);
        emit DepositFor(msg.sender, msg.value, recipient);
    }

    function depositWithPermit(
        address tokenAddress,
        uint amount,
        address recipient,
        uint256 permitNonce,
        uint256 permitExpiry,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) virtual external {
        IPermittableToken token = IPermittableToken(tokenAddress);

        if (token.allowance(msg.sender, address(this)) < amount) {
            token.permit(
                msg.sender,
                address(this),
                permitNonce,
                permitExpiry,
                true,
                permitV,
                permitR,
                permitS
            );
        }
        depositTokenFor(tokenAddress, amount, recipient);
    }

    function depositTokenFor(
        address tokenAddress,
        uint amount,
        address recipient
    ) virtual public {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), amount);

        emit DepositTokenFor(msg.sender, amount, recipient, tokenAddress);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function balanceOfToken(address token) public view returns (uint256) {
        return _getBalance(address(this), token);
    }

    function balanceOfBatch(address[] calldata tokens) public view returns (uint[] memory)
    {
        uint[] memory result = new uint[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] != address(0x0)) {
                result[i] = _getBalance(address(this), tokens[i]);
            } else {
                result[i] = _balances[owner()];
            }
        }

        return result;
    }

    function withdraw(uint value) virtual external {
        _withdraw(msg.sender, value);
        emit Withdrawal(msg.sender, value);
    }

    function withdrawTo(address recipient, uint value) virtual external {
        _withdraw(recipient, value);
        emit WithdrawalTo(msg.sender, value, recipient);
    }

    function _withdraw(address recipient, uint value) internal {
        _balances[msg.sender] = _balances[msg.sender].sub(value, "Bridge: withdrawal amount exceeds balance");

        require(
            // solhint-disable-next-line check-send-result
            payable(recipient).send(value)
        );
    }

    function withdrawToken(
        address token,
        uint value,
        address recipient
    ) virtual onlyOwner external {
        if (token != address(0x0)) {
            IERC20(token).transfer(recipient, value);
        } else {
            _withdraw(recipient, value);
        }
        emit TokenWithdrawal(msg.sender, token, value, recipient);
    }

    function withdrawTokens(
        address[] calldata tokens,
        uint[] calldata values,
        address[] calldata recipients
    ) virtual onlyOwner external {
        require(tokens.length == values.length, "Bridge#withdrawTokens: INVALID_ARRAY_LENGTH");

        for (uint256 i = 0; i < tokens.length; i++) {
            address recipient = recipients.length == 1 ? recipients[0] : recipients[i];
            if (tokens[i] != address(0x0)) {
                IERC20(tokens[i]).transfer(recipient, values[i]);
            } else {
                _withdraw(recipient, values[i]);
            }
            emit TokenWithdrawal(msg.sender, tokens[i], values[i], recipient);
        }
    }

    // Will be called on another network
    function withdrawDeposit(
        address token,
        uint depositValue,
        uint fee,
        bytes32 txHash,
        address recipient
    ) virtual onlyOwner public {
        bytes32 depositId = keccak256(abi.encodePacked(token, depositValue, txHash));
        require(!_withdrawnDeposits[depositId], 'Bridge#withdrawDeposit: DEPOSIT_ALREADY_WITHDRAWN');

        uint withdrawAmount = depositValue.sub(fee);

        if (token != address(0x0)) {
            IERC20(token).transfer(recipient, withdrawAmount);
        } else {
            _withdraw(recipient, withdrawAmount);
        }

        _withdrawnDeposits[depositId] = true;

        emit DepositWithdrawn(token, depositValue, fee, withdrawAmount, txHash, recipient, depositId);
    }

    function withdrawDepositsBatch(
        address[] calldata tokens,
        uint[] calldata depositValues,
        uint[] calldata fees,
        bytes32[] calldata txHashes,
        address[] calldata recipients
    ) virtual onlyOwner external {
        require(
            tokens.length == depositValues.length &&
            tokens.length == fees.length &&
            tokens.length == txHashes.length &&
            tokens.length == recipients.length
            , "Bridge#withdrawDepositsBatch: INVALID_ARRAY_LENGTH");

        for (uint256 i = 0; i < tokens.length; i++) {
            withdrawDeposit(
                tokens[i],
                depositValues[i],
                fees[i],
                txHashes[i],
                recipients[i]
            );
        }
    }

    function withdrawnDepositStatus(bytes32 depositId) public view returns (bool) {
        return _withdrawnDeposits[depositId];
    }

    // private functions

    function _getBalance(
        address account,
        address token
    )
        private
        view
        returns (uint256)
    {
        uint256 result = 0;
        uint256 tokenCode;

        /// @dev check if token is actually a contract
        // solhint-disable-next-line no-inline-assembly
        assembly { tokenCode := extcodesize(token) } // contract code size

        if (tokenCode > 0) {
            /// @dev is it a contract and does it implement balanceOf
            // solhint-disable-next-line avoid-low-level-calls
            (bool methodExists,) = token.staticcall(
                abi.encodeWithSelector(IERC20(token).balanceOf.selector, account)
            );

            if (methodExists) {
                result = IERC20(token).balanceOf(account);
            }
        }

        return result;
    }
}
