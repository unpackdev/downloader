// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <=0.8.6;

import "./IERC721.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./ILockable.sol";
import "./ERC721Receiver.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Enumerable, IERC721Metadata, ILockable, ERC721Receiver {
    using Address for address;
    using Strings for uint256;

    event AdminSet(address _admin, bool _isAdmin);
    
    bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;

    address payable owner;

    string private _name;

    string private _symbol;

    uint256[] internal _allTokens;

    mapping(uint256 => address) internal _owners;

    mapping(address => uint256) internal _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(address => bool) admins;
    
    mapping(uint256 => bool) lockedTokens;

    mapping(uint256 => string) internal _tokenURIs;

    mapping(address => mapping(uint256 => uint256)) internal _ownedTokens;

    mapping(uint256 => uint256) private _ownedTokensIndex;

    mapping(uint256 => uint256) private _allTokensIndex;

    struct Token {
        uint256 id;
        uint256 price;
        address token;
        address owner;
        address creator;
        string uri;
        bool status;
        bool isLocked;
    }

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner");
        _;
    }

     modifier onlyAdmin() {
        require(admins[msg.sender] || owner == msg.sender, "Only admin or owner");
        _;
    }

    modifier tokenNotFound(uint256 _tokenId) {
        require(exists(_tokenId), "Token isn't exist");
        _;
    }

    modifier isUnlock(uint256 _tokenId) {
        require(!isLock(_tokenId), "Token is locked");
        _;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address _owner) public view virtual override returns (uint256) {
        require(_owner != address(0), "ERC721: balance query for the zero address");
        return _balances[_owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address _owner = _owners[tokenId];
        require(_owner != address(0), "ERC721: owner query for nonexistent token");
        return _owner;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address _owner = ERC721.ownerOf(tokenId);
        require(to != _owner, "ERC721: approval to current owner");

        require(
            _msgSender() == _owner || isApprovedForAll(_owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address _owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[_owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(exists(tokenId), "ERC721: operator query for nonexistent token");
        address _owner = ERC721.ownerOf(tokenId);
        return (spender == _owner || getApproved(tokenId) == spender || isApprovedForAll(_owner, spender));
    }

    function _safeMint(address to, uint256 tokenId, string memory uri) internal virtual {
        _safeMint(to, tokenId, "", uri);
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data,
        string memory _uri
    ) internal virtual {
        _mint(to, tokenId, _uri);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId, string memory uri) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;
        _setTokenURI(tokenId, uri);

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try ERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == ERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function tokenOfOwnerByIndex(address _owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(_owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[_owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (from == address(0)) {
            _allTokensIndex[tokenId] = _allTokens.length;
            _allTokens.push(tokenId);
        } else if (from != to) {
            uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
            uint256 tokenIndex = _ownedTokensIndex[tokenId];

            if (tokenIndex != lastTokenIndex) {
                uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

                _ownedTokens[from][tokenIndex] = lastTokenId; 
                _ownedTokensIndex[lastTokenId] = tokenIndex;
            }

            delete _ownedTokensIndex[tokenId];
            delete _ownedTokens[from][lastTokenIndex];
        }
        if (to == address(0)) {
            uint256 lastTokenIndex = _allTokens.length - 1;
            uint256 tokenIndex = _allTokensIndex[tokenId];

            uint256 lastTokenId = _allTokens[lastTokenIndex];

            _allTokens[tokenIndex] = lastTokenId; 
            _allTokensIndex[lastTokenId] = tokenIndex;

            delete _allTokensIndex[tokenId];
            _allTokens.pop();
        } else if (to != from) {
            uint256 length = ERC721.balanceOf(to);
            _ownedTokens[to][length] = tokenId;
            _ownedTokensIndex[tokenId] = length;
        }
    }
 
  function name() external override view returns (string memory) {
    return _name;
  }

  function symbol() external override view returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) external override view returns (string memory) {
    require(ERC721.exists(tokenId));
    return _tokenURIs[tokenId];
  }

  function _setTokenURI(uint256 tokenId, string memory uri) internal {
    require(ERC721.exists(tokenId));
    _tokenURIs[tokenId] = uri;
  }

    function lock(uint256 _tokenId) public override tokenNotFound(_tokenId) isUnlock(_tokenId) onlyAdmin{
        _transfer(ownerOf(_tokenId), address(0), _tokenId);
        _lock(_tokenId);
    }

    function _lock(uint256 _tokenId) internal {
        lockedTokens[_tokenId] = true;

        emit SetLock(_tokenId, true);
    }

    function unlock(uint256 _tokenId) public override tokenNotFound(_tokenId) onlyAdmin{
        require(isLock(_tokenId), "Token is already unlocked");
        lockedTokens[_tokenId] = false;

        emit SetLock(_tokenId, false);
    }

    function _unlock(uint256 _tokenId) internal {
        lockedTokens[_tokenId] = false;

        emit SetLock(_tokenId, false);
    }

    function isLock(uint256 _tokenId) public view override returns(bool) {
        return lockedTokens[_tokenId];
    }

    function setAdmin(address _user, bool _isAdmin) public onlyOwner() {
        require(!isAdmin(_user), "User is already admin");
        admins[_user] = _isAdmin;

        emit AdminSet(_user, _isAdmin);
    }

    function isAdmin(address _admin) public view returns(bool) {
        return admins[_admin];
    }
}