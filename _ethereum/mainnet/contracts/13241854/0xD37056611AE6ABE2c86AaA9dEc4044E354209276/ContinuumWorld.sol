// This contract is not supposed to be used in production
// It's strictly for testing purpose

pragma solidity 0.6.6;

import "./ERC1155.sol";
import "./IMintableERC1155.sol";
import "./NativeMetaTransaction.sol";
import "./ContextMixin.sol";
import "./AccessControlMixin.sol";

contract ContinuumWorld is
    ERC1155,
    AccessControlMixin,
    NativeMetaTransaction,
    ContextMixin,
    IMintableERC1155
{
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    constructor(string memory uri_) public ERC1155(uri_) {
        _setupContractId("ContinuumWorld");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PREDICATE_ROLE, _msgSender());

        _initializeEIP712(uri_);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external override only(PREDICATE_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override only(PREDICATE_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function _msgSender()
        internal
        override
        view
        returns (address payable sender)
    {
        return ContextMixin.msgSender();
    }
}
