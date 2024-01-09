// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ECDSA.sol";

abstract contract ERC721V2 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    address[] internal _owners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        uint count = 0;
        uint length = _owners.length;
        for( uint i = 0; i < length; ++i ){
            if( owner == _owners[i] ){
                ++count;
            }
        }

        delete length;
        return count;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721V2.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _owners.length && _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721V2.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }


    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);
        _owners.push(to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721V2.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        _owners[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
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
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721V2.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721V2.ownerOf(tokenId), to, tokenId);
    }


    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


contract BonnyDolls is Ownable, ERC721V2 {
    using Strings for uint256;
    using SafeMath for uint256;
    using ECDSA for bytes32;

    uint256 public constant PRICE = 60 * 10**15; // .06 eth
    uint256 public constant MAX_BY_MINT = 10;
    uint256 public constant MAX_RESERVE_COUNT = 100;
    uint256 public constant LAUNCH_TIMESTAMP = 1643310000; // Thu Jan 27 2022 19:00:00 GMT+0000
    uint256 public MAX_ELEMENTS = 1500;
    uint256 public WHITELIST_RESERVE = 500;

    uint256 private _reservedCount = 0;
    uint256 private _reserveAtATime = 10;

    bool public isSaleOpen = false;

    mapping(address => bool) public allowedErc20Tokens;
    mapping(address => uint256) public userClaimed;
    mapping(address => uint256) public userBoughtPresale;

    address public constant t1 = 0x891096Eb11b84Aa3c12e346C64ae60f8E54d074a;
    address public constant t2 = 0x80F5D7940408bFaa3Ab08d252C63616e492B4B1e;
    address public constant t3 = 0x0a15f8D9b8aCb352eE11a1D76e967Ab44842e9f3;

    address private _signer = 0x8A5cCf0bb1b0FecC6bed2B3b5Ed3B739030C3DD0;

    string public baseTokenURI;

    constructor(string memory baseURI) ERC721V2("Bonny Dolls", "DOLLS") {
        setBaseURI(baseURI);
    }

    modifier saleIsOpen {
        if (_msgSender() != owner()) {
            require(isSaleOpen, "Sale is not open");
        }
        _;
    }

    function totalMint() public view returns (uint256) {
        return _owners.length;
    }

    function reserveTokens() public onlyOwner {
        require(_reservedCount + _reserveAtATime <= MAX_RESERVE_COUNT, "Max reserve exceeded");
        uint256 total = _owners.length;
        for (uint256 i = 0; i < _reserveAtATime; i++) {
            _reservedCount++;
            _mint(msg.sender, total++);
        }
    }

    function presaleMint(uint256 _amount, uint256 _price, bytes memory _signature) external payable saleIsOpen {
        require(userBoughtPresale[msg.sender] < _amount, "Discounted count exceeds max allowed");
        uint256 total = _owners.length;
        require(total + _amount <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "All NFTs are sold out");
        require(_amount <= MAX_BY_MINT, "Exceeds number");
        require(msg.value >= _price.mul(_amount), "Value below price");
        
        address _minter = _msgSender();

        address signer = verifyMint(_minter, address(0), _amount, _amount, _price, _signature);
        require(signer == _signer, "Not authorized to mint");

        for (uint256 i = 0; i < _amount; i++) {
            userBoughtPresale[msg.sender] += 1;
            _mint(msg.sender, total++);
        }  
    }

    function mint(uint256 _amount) external payable saleIsOpen {
        uint256 total = _owners.length;
        require(total + _amount + WHITELIST_RESERVE <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "All NFTs are sold out");
        require(_amount <= MAX_BY_MINT, "Exceeds per mint");
        require(msg.value >= price(_amount), "Value below price");

        for (uint256 i = 0; i < _amount; i++) {
            _mint(msg.sender, total++);
        }
    }

    function mintWithErc20(address _tokenAddress, uint256 _amount, uint256 _price, bytes memory _signature) external saleIsOpen {
        uint256 total = _owners.length;
        require(total + _amount + WHITELIST_RESERVE <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "All NFTs are sold out");
        require(_amount <= MAX_BY_MINT, "Exceeds number");
        require(allowedErc20Tokens[_tokenAddress], "You can not mint with this token");

        address _minter = _msgSender();
        address signer = verifyMint(_minter, _tokenAddress, _amount, _amount, _price, _signature);
        require(signer == _signer, "Not authorized to mint");  

        IERC20(_tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _price * _amount
        );

        for (uint256 i = 0; i < _amount; i++) {
            _mint(msg.sender, total++);
        }
    }

    function claim(uint256 _userClaims, uint256 _amount, bytes memory _signature) external saleIsOpen {
        require(userClaimed[msg.sender] < _userClaims, "Claiming exceeds max allowed");
        uint256 total = _owners.length;
        require(total + _amount <= MAX_ELEMENTS, "Max limit");
        require(total <= MAX_ELEMENTS, "All NFTs are sold out");

        address _minter = _msgSender();

        address signer = verifyMint(_minter, address(0), _amount, _userClaims, 0, _signature);
        require(signer == _signer, "Not authorized to mint");

        for (uint256 i = 0; i < _amount; i++) {
            userClaimed[msg.sender] += 1;
            _mint(msg.sender, total++);
        }
    }

    function verifyMint(address _minter, address _token, uint256 _amount, uint256 _userClaims, uint256 _price, bytes memory _signature) public pure returns (address) {
        return ECDSA.recover(keccak256(abi.encode(_minter, _token, _amount, _userClaims, _price)), _signature);
    }

    function price(uint256 _count) public pure returns (uint256) {
        return PRICE.mul(_count);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setSaleOpen(bool _isSaleOpen) external onlyOwner {
        isSaleOpen = _isSaleOpen;
    }

    function setReserveAtATime(uint256 _count) public onlyOwner {
        _reserveAtATime = _count;
    }

    function setMaxElements(uint _count) public onlyOwner {
        uint256 total = _owners.length;
        require(_count > total, "Incorrect new amount");
        MAX_ELEMENTS = _count;
    }

    function setAllowanceErc20(address _tokenAddress, bool _allow) external onlyOwner {
        require(_tokenAddress != address(0), "Incorrect address");
        allowedErc20Tokens[_tokenAddress] = _allow;
    }

    function setSigner(address addr) external onlyOwner {
        _signer = addr;
    }

    function setWhitelistReserve(uint _reserve) external onlyOwner {
        WHITELIST_RESERVE = _reserve;
    }

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    function withdrawEther() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdrawEther(t1, balance.mul(50).div(100));
        _withdrawEther(t2, balance.mul(20).div(100));
        _withdrawEther(t3, balance.mul(10).div(100));

        _withdrawEther(t1, address(this).balance);
    }

    function _withdrawEther(address _address, uint256 _amount) private {
        payable(_address).transfer(_amount);
    }

    function withdrawTokens(address _tokenAddress) external onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        require(balance > 0);

        _withdrawTokens(_tokenAddress, t1, balance.mul(50).div(100));
        _withdrawTokens(_tokenAddress, t2, balance.mul(20).div(100));
        _withdrawTokens(_tokenAddress, t3, balance.mul(10).div(100));

        _withdrawTokens(_tokenAddress, t1, IERC20(_tokenAddress).balanceOf(address(this)));
    }

    function _withdrawTokens(address _tokenAddress, address _address, uint256 _amount) private {
        IERC20(_tokenAddress).transfer(_address, _amount);
    }
}