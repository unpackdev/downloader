// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC1155.sol";
import "./IERC1155Receiver.sol";
import "./ERC721.sol";
import "./EnumerableSet.sol";

import "./IERC998ERC721TopDown.sol";
import "./IERC998ERC1155TopDown.sol";

contract ERC998TopDown is ERC721, IERC998ERC721TopDown, IERC998ERC1155TopDown {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    // What tokens does the 998 own, by child address?
    // _balances[tokenId][child address] = [child tokenId 1, child tokenId 2]
    mapping(uint256 => mapping(address => EnumerableSet.UintSet)) internal _balances721;
    // Which 998s own a a child 721 contract's token?
    // _holdersOf[child address] = [tokenId 1, tokenId 2]
    mapping(address => EnumerableSet.UintSet) internal _holdersOf721;

    // _balances[tokenId][child address][child tokenId] = amount
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) internal _balances1155;
    // _holdersOf[child address][child tokenId] = [tokenId 1, tokenId 2]
    mapping(address => mapping(uint256 => EnumerableSet.UintSet)) internal _holdersOf1155;

    // What child 721 contracts does a token have children of?
    // _child721Contracts[tokenId] = [child address 1, child address 2]
    mapping(uint256 => EnumerableSet.AddressSet) internal _child721Contracts;
    // What child tokens does a token have for a child 721 contract?
    // _childrenForChild721Contracts[tokenId][child address] = [child tokenId 1, child tokenId 2]
    mapping(uint256 => mapping(address => EnumerableSet.UintSet)) internal _childrenForChild721Contracts;

    mapping(uint256 => EnumerableSet.AddressSet) internal _child1155Contracts;
    mapping(uint256 => mapping(address => EnumerableSet.UintSet)) internal _childrenForChild1155Contracts;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    /**
     * @dev Gives child balance for a specific child 721 contract.
     */
    function child721Balance(uint256 tokenId, address childContract, uint256 childTokenId) public view override returns (uint256) {
        return _balances721[tokenId][childContract].contains(childTokenId) ? 1 : 0;
    }

    /**
     * @dev Gives child balance for a specific child 1155 contract and child id.
     */
    function child1155Balance(uint256 tokenId, address childContract, uint256 childTokenId) public view override returns (uint256) {
        return _balances1155[tokenId][childContract][childTokenId];
    }

    /**
     * @dev Gives list of child 721 contracts where token ID has childs.
     */
    function child721ContractsFor(uint256 tokenId) override public view returns (address[] memory) {
        address[] memory childContracts = new address[](_child721Contracts[tokenId].length());

        for(uint256 i = 0; i < _child721Contracts[tokenId].length(); i++) {
            childContracts[i] = _child721Contracts[tokenId].at(i);
        }

        return childContracts;
    }

    /**
     * @dev Gives list of child 1155 contracts where token ID has childs.
     */
    function child1155ContractsFor(uint256 tokenId) override public view returns (address[] memory) {
        address[] memory childContracts = new address[](_child1155Contracts[tokenId].length());

        for(uint256 i = 0; i < _child1155Contracts[tokenId].length(); i++) {
            childContracts[i] = _child1155Contracts[tokenId].at(i);
        }

        return childContracts;
    }

    /**
     * @dev Gives list of owned child IDs on a child 721 contract by token ID.
     */
    function child721IdsForOn(uint256 tokenId, address childContract) override public view returns (uint256[] memory) {
        uint256[] memory childTokenIds = new uint256[](_childrenForChild721Contracts[tokenId][childContract].length());

        for(uint256 i = 0; i < _childrenForChild721Contracts[tokenId][childContract].length(); i++) {
            childTokenIds[i] = _childrenForChild721Contracts[tokenId][childContract].at(i);
        }

        return childTokenIds;
    }

    /**
     * @dev Gives list of owned child IDs on a child 1155 contract by token ID.
     */
    function child1155IdsForOn(uint256 tokenId, address childContract) override public view returns (uint256[] memory) {
        uint256[] memory childTokenIds = new uint256[](_childrenForChild1155Contracts[tokenId][childContract].length());

        for(uint256 i = 0; i < _childrenForChild1155Contracts[tokenId][childContract].length(); i++) {
            childTokenIds[i] = _childrenForChild1155Contracts[tokenId][childContract].at(i);
        }

        return childTokenIds;
    }

    /**
     * @dev Transfers child 721 token from a token ID.
     */
    function safeTransferChild721From(uint256 fromTokenId, address to, address childContract, uint256 childTokenId, bytes memory data) public override {
        require(to != address(0), "ERC998: transfer to the zero address");

        address operator = _msgSender();
        require(
            ownerOf(fromTokenId) == operator ||
            isApprovedForAll(ownerOf(fromTokenId), operator),
            "ERC998: caller is not owner nor approved"
        );

        _beforeChild721Transfer(operator, fromTokenId, to, childContract, childTokenId, data);

        _removeChild721(fromTokenId, childContract, childTokenId);

        ERC721(childContract).safeTransferFrom(address(this), to, childTokenId, data);
        emit TransferChild721(fromTokenId, to, childContract, childTokenId);
    }


    /**
     * @dev Transfers child 1155 token from a token ID.
     */
    function safeTransferChild1155From(uint256 fromTokenId, address to, address childContract, uint256 childTokenId, uint256 amount, bytes memory data) public override {
        require(to != address(0), "ERC998: transfer to the zero address");

        address operator = _msgSender();
        require(
            ownerOf(fromTokenId) == operator ||
            isApprovedForAll(ownerOf(fromTokenId), operator),
            "ERC998: caller is not owner nor approved"
        );

        _beforeChild1155Transfer(operator, fromTokenId, to, childContract, _asSingletonArray(childTokenId), _asSingletonArray(amount), data);

        _removeChild1155(fromTokenId, childContract, childTokenId, amount);

        ERC1155(childContract).safeTransferFrom(address(this), to, childTokenId, amount, data);
        emit TransferSingleChild1155(fromTokenId, to, childContract, childTokenId, amount);
    }

    /**
     * @dev Transfers batch of child 1155 tokens from a token ID.
     */
    function safeBatchTransferChild1155From(uint256 fromTokenId, address to, address childContract, uint256[] memory childTokenIds, uint256[] memory amounts, bytes memory data) public override {
        require(childTokenIds.length == amounts.length, "ERC998: ids and amounts length mismatch");
        require(to != address(0), "ERC998: transfer to the zero address");

        address operator = _msgSender();
        require(
            ownerOf(fromTokenId) == operator ||
            isApprovedForAll(ownerOf(fromTokenId), operator),
            "ERC998: caller is not owner nor approved"
        );

        _beforeChild1155Transfer(operator, fromTokenId, to, childContract, childTokenIds, amounts, data);

        for (uint256 i = 0; i < childTokenIds.length; ++i) {
            uint256 childTokenId = childTokenIds[i];
            uint256 amount = amounts[i];

            _removeChild1155(fromTokenId, childContract, childTokenId, amount);
        }

        ERC1155(childContract).safeBatchTransferFrom(address(this), to, childTokenIds, amounts, data);
        emit TransferBatchChild1155(fromTokenId, to, childContract, childTokenIds, amounts);
    }

    /**
     * @dev Receives a child token, the receiver token ID must be encoded in the
     * field data. Operator is the account who initiated the transfer.
     */
    function onERC721Received(address operator, address from, uint256 id, bytes memory data) virtual public override returns (bytes4) {
        require(data.length == 32, "ERC998: data must contain the unique uint256 tokenId to transfer the child token to");

        uint256 _receiverTokenId;
        uint256 _index = msg.data.length - 32;
        assembly {_receiverTokenId := calldataload(_index)}

        _receiveChild721(_receiverTokenId, msg.sender, id);
        emit ReceivedChild721(from, _receiverTokenId, msg.sender, id);

        return this.onERC721Received.selector;
    }

    /**
     * @dev Receives a child token, the receiver token ID must be encoded in the
     * field data. Operator is the account who initiated the transfer.
     */
    function onERC1155Received(address operator, address from, uint256 id, uint256 amount, bytes memory data) virtual public override returns (bytes4) {
        require(data.length == 32, "ERC998: data must contain the unique uint256 tokenId to transfer the child token to");

        uint256 _receiverTokenId;
        uint256 _index = msg.data.length - 32;
        assembly {_receiverTokenId := calldataload(_index)}

        _receiveChild1155(_receiverTokenId, msg.sender, id, amount);
        emit ReceivedChild1155(from, _receiverTokenId, msg.sender, id, amount);

        return this.onERC1155Received.selector;
    }

    /**
     * @dev Receives a batch of child tokens, the receiver token ID must be
     * encoded in the field data. Operator is the account who initiated the transfer.
     */
    function onERC1155BatchReceived(address operator, address from, uint256[] memory ids, uint256[] memory values, bytes memory data) virtual public override returns (bytes4) {
        require(data.length == 32, "ERC998: data must contain the unique uint256 tokenId to transfer the child token to");
        require(ids.length == values.length, "ERC1155: ids and values length mismatch");

        uint256 _receiverTokenId;
        uint256 _index = msg.data.length - 32;
        assembly {_receiverTokenId := calldataload(_index)}

        for (uint256 i = 0; i < ids.length; i++) {
            _receiveChild1155(_receiverTokenId, msg.sender, ids[i], values[i]);
            emit ReceivedChild1155(from, _receiverTokenId, msg.sender, ids[i], values[i]);
        }

        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Update bookkeeping when a 998 is sent a child 721 token.
     */
    function _receiveChild721(uint256 tokenId, address childContract, uint256 childTokenId) internal virtual {
        if (!_child721Contracts[tokenId].contains(childContract)) {
            _child721Contracts[tokenId].add(childContract);
        }

        if (!_balances721[tokenId][childContract].contains(childTokenId)) {
            _childrenForChild721Contracts[tokenId][childContract].add(childTokenId);
        }

        _balances721[tokenId][childContract].add(childTokenId);
    }

    /**
     * @dev Update bookkeeping when a child 721 token is removed from a 998.
     */
    function _removeChild721(uint256 tokenId, address childContract, uint256 childTokenId) internal virtual {
        require(_balances721[tokenId][childContract].contains(childTokenId), "ERC998: insufficient child balance for transfer");

        _balances721[tokenId][childContract].remove(childTokenId);
        _holdersOf721[childContract].remove(tokenId);
        _childrenForChild721Contracts[tokenId][childContract].remove(childTokenId);
        if (_childrenForChild721Contracts[tokenId][childContract].length() == 0) {
            _child721Contracts[tokenId].remove(childContract);
        }
    }

    /**
     * @dev Update bookkeeping when a 998 is sent a child 1155 token.
     */
    function _receiveChild1155(uint256 tokenId, address childContract, uint256 childTokenId, uint256 amount) internal virtual {
        if (!_child1155Contracts[tokenId].contains(childContract)) {
            _child1155Contracts[tokenId].add(childContract);
        }

        if (_balances1155[tokenId][childContract][childTokenId] == 0) {
            _childrenForChild1155Contracts[tokenId][childContract].add(childTokenId);
        }

        _balances1155[tokenId][childContract][childTokenId] += amount;
    }

    /**
     * @dev Update bookkeeping when a child 1155 token is removed from a 998.
     */
    function _removeChild1155(uint256 tokenId, address childContract, uint256 childTokenId, uint256 amount) internal virtual {
        require(amount != 0 || _balances1155[tokenId][childContract][childTokenId] >= amount, "ERC998: insufficient child balance for transfer");

        _balances1155[tokenId][childContract][childTokenId] -= amount;
        if (_balances1155[tokenId][childContract][childTokenId] == 0) {
            _holdersOf1155[childContract][childTokenId].remove(tokenId);
            _childrenForChild1155Contracts[tokenId][childContract].remove(childTokenId);
            if (_childrenForChild1155Contracts[tokenId][childContract].length() == 0) {
                _child1155Contracts[tokenId].remove(childContract);
            }
        }
    }

    function _beforeChild721Transfer(
        address operator,
        uint256 fromTokenId,
        address to,
        address childContract,
        uint256 id,
        bytes memory data
    )
        internal virtual
    { }

    function _beforeChild1155Transfer(
        address operator,
        uint256 fromTokenId,
        address to,
        address childContract,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual
    { }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }
}
