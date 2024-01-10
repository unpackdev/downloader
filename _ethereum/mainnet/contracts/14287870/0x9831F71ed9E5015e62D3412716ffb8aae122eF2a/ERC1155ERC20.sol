// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC165.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./IERC1155MetadataURI.sol";

contract ERC1155ERC20 is ERC165, IERC20, IERC20Metadata, IERC1155, IERC1155MetadataURI {
    string private _name;
    string private _symbol;
    string private _uri;

    // ERC20-allowances
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(uint256 => mapping(address => uint256)) private _balances;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256 => uint256) private _totalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) {
        _name = name_;
        _symbol = symbol_;
        _uri = uri_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function name()  external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function granularity() external pure returns (uint256) {
        return 1;
    }

    function uri(uint256 id) public view virtual returns (string memory) {
        if (id == 0) {
            return "";
        }
        return _uri;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply[0];
    }

    function totalSupply(uint256 id) public view returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[0][account];
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     */
    function balanceOf(address account, uint256 id) public view returns (uint256) {
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) external view returns (uint256[] memory) {
        require(accounts.length == ids.length, "length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool) {
        require(recipient != address(0), "0 address");

        _safeTransferFrom(msg.sender, recipient, 0, amount, "");
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        require(recipient != address(0), "0 address");
        require(holder != address(0), "0 address");

        uint256 currentAllowance = _allowances[holder][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "exceeds allowance");
            unchecked {
                _approve(holder, msg.sender, currentAllowance - amount);
            }
        }

        _safeTransferFrom(holder, recipient, 0, amount, "");
        return true;
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        require(id > 0, "0 id");
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "not approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "not approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address holder, address spender) external view returns (uint256) {
        return _allowances[holder][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external {
        require(msg.sender != operator, "approval for self");
        require(address(0) != operator, "approval for 0");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function _approve(
        address holder,
        address spender,
        uint256 value
    ) internal virtual {
        require(holder != address(0), "0 address");
        require(spender != address(0), "0 address");

        _allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "0 address");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "insufficient balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        if (id == 0) {
            emit Transfer(from, to, amount);
            return;
        }

        emit TransferSingle(msg.sender, from, to, id, amount);
        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "length mismatch");
        require(to != address(0), "0 address");

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            require(id > 0, "0 id");

            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "insufficient balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
    }

    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "0 address");

        _bareMint(to, id, amount);
        if (id == 0) {
            emit Transfer(address(0), to, amount);
            return;
        }

        emit TransferSingle(msg.sender, address(0), to, id, amount);
        _doSafeTransferAcceptanceCheck(msg.sender, address(0), to, id, amount, data);
    }

    function _bareMint(
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual {
        _totalSupply[id] += amount;
        _balances[id][to] += amount;
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "0 address");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "exceeds balance");
        unchecked {
            _totalSupply[id] -= amount;
            _balances[id][from] = fromBalance - amount;
        }

        if (id == 0) {
            emit Transfer(from, address(0), amount);
        } else {
            emit TransferSingle(msg.sender, from, address(0), id, amount);
        }
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (isContract(to)) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155Receiver rejected");
                }
            } catch {
                revert("non ERC1155Receiver");
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
    ) private {
        if (isContract(to)) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155Receiver rejected");
                }
            } catch {
                revert("non ERC1155Receiver");
            }
        }
    }

    function isContract(address account) public view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
