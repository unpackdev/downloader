//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC165.sol";

/**
 * @notice EIP-721 implementation of Adventurers Token
 */
abstract contract ERC721 is IERC721Enumerable, IERC721Metadata, Ownable {
    string public constant NAME = "Adventurers Of Ether";
    string public constant SYMBOL = "KOE";
    uint private constant MAX_SUPPLY = 6001; // +1 extra 1 for <

    /* state */
    uint256 public maxSupply = 3000;
    uint private minted; // count of minted tokens
    mapping(address /* minter */ => /* minted tokes count */ uint) public minters;

    address[MAX_SUPPLY] private owners;

    mapping(address /* owner */ => /* tokens count */ uint) private balances;
    mapping(uint /* token */ => /* operator */ address) private operatorApprovals;
    mapping(address /* owner */ => mapping(address /* operator */ => bool)) private forallApprovals;

    constructor() {}

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply < MAX_SUPPLY, "max supply exceeded");
        maxSupply = _maxSupply;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() public view returns (uint256) {
        return minted;
    }

    function _mint(address _to, uint256 _amount)
        internal returns (uint _oldIndex, uint _newIndex)
    {
        uint256 _minted = minted;
        require(_minted + _amount - 1 < maxSupply, "tokens are over");

        for (uint256 i = 0; i < _amount; i++){
            _minted++;
            owners[_minted] = _to;
            emit Transfer(address(0), _to, _minted);
        }

        minters[_to] += _amount;
        balances[_to] += _amount;
        minted = _minted;
        return (_minted - _amount, _minted);
    }

    function _mintBatch(address[] memory _to, uint[] memory _amounts)
        internal returns (uint _oldIndex, uint _newIndex)
    {
        require(_to.length == _amounts.length, "array lengths mismatch");
        uint256 _minted = minted;
        uint _total = 0;
        for (uint i = 0; i < _to.length; i++) {
            uint _amount = _amounts[i];
            address _addr = _to[i];

            _total += _amount;
            //minters[_addr] += _amount;
            balances[_addr] += _amount;
            for (uint256 j = 0; j < _amount; j++){
                _minted++;
                owners[_minted] = _addr;
                emit Transfer(address(0), _addr, _minted);
            }
        }

        require(_minted + _total < maxSupply, "tokens are over");
        minted = _minted;
        return (_minted - _total, _minted);
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return ((minted + 1) > _tokenId) && (_tokenId > 0);
    }
    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        uint _ix = 0;
        for (uint _tokenId = 1; _tokenId < minted; _tokenId += 1) {
            if (owners[_tokenId] == _owner) {
                if (_ix == _index) {
                    return _tokenId;
                } else {
                    _ix += 1;
                }
            }
        }
        return 0;
    }

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 _index) external pure returns (uint256) {
        return _index;
    }

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address _owner) public view returns (uint256 _balance) {
        _balance = balances[_owner];
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        _owner = owners[_tokenId];
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public {
        _transfer(_from, _to, _tokenId, _data);
    }

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        _transfer(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        _transfer(_from, _to, _tokenId, "");
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory
    ) internal {
        address _owner = ownerOf(_tokenId);
        require(msg.sender == _owner
            || getApproved(_tokenId) == msg.sender
            || isApprovedForAll(_owner, msg.sender),
            "erc-721: not owner nor approved");
        require(_owner == _from, "erc-721: not owner");
        require(_to != address(0), "zero address");
        operatorApprovals[_tokenId] = address(0);

        owners[_tokenId] = _to;
        balances[_from] -= 1;
        balances[_to] += 1;

        emit Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address _to, uint256 _tokenId) external {
        address _owner = ownerOf(_tokenId);
        require(_owner != _to, "erc-721: approve to caller");
        require(
            msg.sender == _owner || isApprovedForAll(_owner, msg.sender),
            "erc-721: not owner nor approved"
        );
        operatorApprovals[_tokenId] = _to;
        emit Approval(_owner, _to, _tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 _tokenId) public view returns (address _operator) {
        require(exists(_tokenId), "erc-721: nonexistent token");
        _operator = operatorApprovals[_tokenId];
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        require(msg.sender != _operator, "erc-721: approve to caller");
        forallApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return forallApprovals[_owner][_operator];
    }

    /**
     * @dev IERC721Metadata Returns the token collection name.
     */
    function name() external pure returns (string memory) {
        return NAME;
    }

    /**
     * @dev IERC721Metadata Returns the token collection symbol.
     */
    function symbol() external pure returns (string memory) {
        return SYMBOL;
    }
}
