// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC20Pausable.sol";
import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";
import "./ERC20FlashMint.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20.sol";
import "./ERC777.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";

import "./IERC777OperatorBatchFunctions.sol";
import "./IERC777BatchBalanceOf.sol";
import "./ISignedTokenFeeTransfer.sol";
import "./IOperatorTransferAnyERC20Token.sol";
import "./ICirculatingSupply.sol";
import "./IOperatorMint.sol";

contract ERC777MintableToken is ERC777, IOperatorMint, ICirculatingSupply, IOperatorTransferAnyERC20Token, ISignedTokenFeeTransfer, IERC777BatchBalanceOf, IERC777OperatorBatchFunctions {
    using ECDSA for bytes32;
    using SafeMath for uint256;

    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators,
        uint256 initialSupply
    )
        ERC777(name, symbol, defaultOperators)
    {
        if(initialSupply > 0) {
            _mint(msg.sender, initialSupply, "", "");
        }
    }

    function destroy() public {
        require(isOperatorFor(_msgSender(), address(this)), "ERC777: caller is not an operator for this contract");
        selfdestruct(payable(_msgSender()));
    }

    function batchBalanceOf(address[] memory holders)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        uint256[] memory batchBalances = new uint256[](holders.length);

        for (uint256 i = 0; i < holders.length; ++i) {
            batchBalances[i] = balanceOf(holders[i]);
        }

        return batchBalances;
    }

    function operatorBatchTransfer(
        address sender,
        address[] memory recipients,
        uint256[] memory amounts,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(isOperatorFor(_msgSender(), sender), "ERC777: caller is not an operator for sender");
        require(recipients.length == amounts.length, "ERC777: recipients and amounts length mismatch");

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];

            _send(sender, recipient, amount, data, operatorData, false);
        }
    }

    function operatorBatchMint(
        address[] memory recipients,
        uint256[] memory amounts,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(recipients.length == amounts.length, "ERC777: recipients and amounts length mismatch");

        address operator = _msgSender();
        require(operator != address(0), "ERC777: batch mint using the zero address");

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];

            require(isOperatorFor(operator, recipient), "ERC777: caller is not an operator for recipient");

            _mint(recipient, amount, data, operatorData);
        }
    }

    function operatorBatchBurn(
        address[] memory holders,
        uint256[] memory amounts,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(holders.length == amounts.length, "ERC777: holders and amounts length mismatch");

        address operator = _msgSender();
        require(operator != address(0), "ERC777: batch burn using the zero address");

        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];
            uint256 amount = amounts[i];

            require(isOperatorFor(operator, holder), "ERC777: caller is not an operator for holder");

            _burn(holder, amount, data, operatorData);
        }
    }

    /**
     * Emits {Minted} and {IERC20-Transfer} events.
     */
    function operatorMint(
        address account,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(isOperatorFor(_msgSender(), account), "ERC777: caller is not an operator for holder");
        _mint(account, amount, data, operatorData);
    }

    /**
     * Returns the circulating supply (total supply minus tokens held by owner)
     */
    function circulatingSupply() public view virtual override returns (uint256) {
        uint256 result = totalSupply();
        address[] memory operators = defaultOperators();
        for (uint256 i = 0; i < operators.length; i++) {
            result.sub(balanceOf(operators[i]));
        }
        return result;
    }

    /**
     * Operator can withdraw any ERC20 token received by the contract
     */
    function operatorTransferAnyERC20Token(
        address token,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool success) {
        require(isOperatorFor(_msgSender(), address(this)), "ERC777: caller is not an operator for this contract");
        return ERC20(token).transfer(recipient, amount);
    }

    mapping(bytes32 => bool) invalidHashes;

    /**
     * Transfer tokens as the owner on his behalf for signer of signature.
     *
     * @param to address The address which you want to transfer to.
     * @param value uint256 The amount of tokens to be transferred.
     * @param gasPrice uint256 The price in tokens that will be paid per unit of gas.
     * @param nonce uint256 The unique transaction number per user.
     * @param signature bytes The signature of the signer.
     */
    function transferPreSigned(
        address to,
        uint256 value,
        uint256 gasPrice,
        uint256 nonce,
        bytes memory signature
    )
        public
        virtual
        override
        returns (bool)
    {
        uint256 gas = gasleft();

        require(to != address(0));

        bytes32 payloadHash = transferPreSignedPayloadHash(address(this), to, value, gasPrice, nonce);

        // Recover signer address from signature
        address from = payloadHash.toEthSignedMessageHash().recover(signature);
        require(from != address(0), "Invalid signature provided.");

        // Generate transaction hash
        bytes32 txHash = keccak256(abi.encodePacked(from, payloadHash));

        // Make sure this transfer didn't happen yet
        require(!invalidHashes[txHash], "Transaction has already been executed.");

        // Mark hash as used
        invalidHashes[txHash] = true;

        // Initiate token transfer
        operatorSend(from, to, value, "", "");

        // If a gas price is set, pay the sender of this transaction in tokens
        uint256 fee = 0;
        if (gasPrice > 0) {
            // 21000 base + ~14000 transfer + ~10000 event
            gas = 21000 + 14000 + 10000 + gas.sub(gasleft());
            fee = gasPrice.mul(gas);
            operatorSend(from, tx.origin, fee, "", "");
        }

        emit HashRedeemed(txHash, from);

        return true;
    }

    /**
     * Calculates the hash for the payload used by transferPreSigned
     *
     * @param token address The address of this token.
     * @param to address The address which you want to transfer to.
     * @param value uint256 The amount of tokens to be transferred.
     * @param gasPrice uint256 The price in tokens that will be paid per unit of gas.
     * @param nonce uint256 The unique transaction number per user.
     */
    function transferPreSignedPayloadHash(
        address token,
        address to,
        uint256 value,
        uint256 gasPrice,
        uint256 nonce
    )
        public
        pure
        virtual
        override
        returns (bytes32)
    {
        /* "452d3c59": transferPreSignedPayloadHash(address,address,uint256,uint256,uint256) */
        return keccak256(abi.encodePacked(bytes4(0x452d3c59), token, to, value, gasPrice, nonce));
    }
}
