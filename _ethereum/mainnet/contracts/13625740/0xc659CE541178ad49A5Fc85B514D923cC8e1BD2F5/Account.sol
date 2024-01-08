//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "./Context.sol";
import "./ECDSA.sol";
import "./ERC721Holder.sol";
import "./ERC1155Holder.sol";
import "./IERC721Receiver.sol";
import "./IERC1271.sol";
import "./IAccount.sol";

abstract contract Account is
    IAccount,
    IERC1271,
    Context,
    ERC721Holder,
    ERC1155Holder
{
    using ECDSA for bytes32;

    event Executed(address to, uint256 value, bytes data);

    constructor() {}

    receive() external payable virtual {}

    modifier onlyOwner() {
        require(
            owner() == _msgSender() || address(this) == _msgSender(),
            "Account: only owner can call"
        );
        _;
    }

    function execute(Transaction calldata transaction)
        public
        payable
        virtual
        override
        onlyOwner
    {
        _call(transaction);
    }

    function batchExecute(Transaction[] calldata transactions)
        public
        payable
        virtual
        override
        onlyOwner
    {
        for (uint256 i = 0; i < transactions.length; i += 1) {
            _call(transactions[i]);
        }
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        override
        returns (bytes4 magicValue)
    {
        return
            (owner() == hash.recover(signature))
                ? IERC1271.isValidSignature.selector
                : bytes4(0xffffffff);
    }

    function owner() public view virtual override returns (address);

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC1271).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IAccount).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _call(Transaction memory transaction) internal {
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "Account: transaction reverted");
        emit Executed(transaction.to, transaction.value, transaction.data);
    }
}
