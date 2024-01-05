// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155MetadataURI.sol";
import "./Address.sol";
import "./Context.sol";
import "./ERC165.sol";

contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    enum APPROVAL_MODE { NONE, APPROVE, DENY }

    mapping (uint256 => mapping(address => uint256)) private _balances;
    mapping (address => mapping(address => bool)) private _operatorApprovals;
    mapping (uint256 => address) internal _creators;
    mapping (uint256 => address) internal _owners;
    mapping (address => mapping(address => bool)) internal _marketApprovals;
    mapping (address => APPROVAL_MODE) internal _trustGlobalMarketApprovals;
    mapping (address => bool) internal _globalCreatorApprovals;
    string private _uri;
    uint256 internal NFT_MAX = 0x1000000000000;
    event ApprovalForMarket(address indexed creator, address indexed operator, bool approved);
    event BatchApprovalForMarket(address indexed creator, address[] operators, bool[] approved);

    constructor (string memory uri_) {
        _setURI(uri_);
    }

    function getCreator(uint256 _tokenId) public view returns (address) {
      return _creators[_tokenId];
    }

    function getOwner(uint256 _tokenId) public view returns (address) {
      return _owners[_tokenId];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC1155MetadataURI).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function _concatStringsUri(string memory _baseUri, string memory _tokenStr, string memory _fileType) internal pure returns (string memory) {
      return string(abi.encodePacked(_baseUri, _tokenStr, _fileType));
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
      return _concatStringsUri(_uri, toString(_tokenId), ".json");
    }

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "zero address");
        return _balances[id][account];
    }

    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
      require(accounts.length == ids.length, "ids/length mismatch");

      uint256[] memory batchBalances = new uint256[](accounts.length);

      for (uint256 i = 0; i < accounts.length; ++i) {
          batchBalances[i] = balanceOf(accounts[i], ids[i]);
      }

      return batchBalances;
    }

    function _hasInitializedTrust(address creator) internal view returns (bool) {
      return APPROVAL_MODE.NONE == _trustGlobalMarketApprovals[creator];
    }

    function _trustTabuArt(address creator) internal {
      if (_hasInitializedTrust(creator)) {
        _trustGlobalMarketApprovals[creator] = APPROVAL_MODE.APPROVE;
      }
    }

    function doesTrustTabuArt(address creator) public view returns (bool) {
      return _trustGlobalMarketApprovals[creator] != APPROVAL_MODE.DENY;
    }

    function setTrustGlobalMarkets(bool approved) public {
      if (approved) {
        _trustGlobalMarketApprovals[_msgSender()] = APPROVAL_MODE.APPROVE;
      }
      else {
        _trustGlobalMarketApprovals[_msgSender()] = APPROVAL_MODE.DENY;
      }
    }

    function setApprovalForMarketBatch(address[] memory operators, bool[] memory approved) public {
      require(operators.length == approved.length, "operators/approved mismatch length");

      for (uint256 i = 0; i < operators.length; ++i) {
        _marketApprovals[_msgSender()][operators[i]] = approved[i];
      }

      emit BatchApprovalForMarket(_msgSender(), operators, approved);
    }

    function isApprovedForMarket(address creator, address operator) public view returns (bool) {
      if (doesTrustTabuArt(creator)) {
        return _globalCreatorApprovals[operator] ||
               _globalCreatorApprovals[address(0)];
      }

      return _marketApprovals[creator][operator] ||
             _marketApprovals[creator][address(0)];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
      require(_msgSender() != operator, "self approve");

      _operatorApprovals[_msgSender()][operator] = approved;
      emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function _transferAfterMint(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        internal
    {
        require(to != address(0), "zero address");

        address operator = _msgSender();

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "insufficient balance");
        _balances[id][from] = fromBalance - amount;
        _balances[id][to] += amount;

        if (address(0) == from) {
          _creators[id] = to;
        }

        _owners[id] = to;

        _trustTabuArt(from);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "caller not approved"
        );
        require(
          isApprovedForMarket(getCreator(id), _msgSender()),
          "need creator approval"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "insufficient balance");
        _balances[id][from] = fromBalance - amount;
        _balances[id][to] += amount;

        if (address(0) == from) {
          _creators[id] = to;
        }

        _owners[id] = to;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ids/length mismatch");
        require(to != address(0), "zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "caller not approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            address _creator = getCreator(id);

            require(
              isApprovedForMarket(_creator, _msgSender()),
              "need creator approval"
            );

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "insufficient balance");
            _balances[id][from] = fromBalance - amount;
            _balances[id][to] += amount;

            if (address(0) == from) {
              _creators[id] = to;
            }

            _owners[id] = to;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "zero address");
        if (id < NFT_MAX) {
          require(
            address(0) == getCreator(id) && amount == 1,
            "duplicate nft"
          );
        }

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;

        _creators[id] = account;
        _owners[id] = account;

        _trustTabuArt(account);

        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "zero address");
        require(ids.length == amounts.length, "ids/length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][to] += amount;

            if (id < NFT_MAX) {
              require(
                address(0) == getCreator(id) && amount == 1,
                "duplicate nft"
              );
            }

            _creators[id] = to;
            _owners[id] = to;
        }

        _trustTabuArt(to);

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "zero address");
        require(
          isApprovedForMarket(getCreator(id), _msgSender()),
          "need creator approval"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "insufficient balance");
        _balances[id][account] = accountBalance - amount;

        _owners[id] = address(0);

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "zero address");
        require(ids.length == amounts.length, "ids/length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            require(
              isApprovedForMarket(getCreator(id), operator),
              "need creator approval"
            );

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "insufficient balance");

            _owners[id] = address(0);

            _balances[id][account] = accountBalance - amount;
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    {
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
