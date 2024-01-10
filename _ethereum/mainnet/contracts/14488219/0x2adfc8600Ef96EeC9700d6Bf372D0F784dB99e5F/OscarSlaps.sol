//,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//,,,,,,,,,,,@&&&&&&&&.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//,,,,,,,,,,@&&&&&&&&&&&%,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&&@,,,,,,,,,,,,,,,,,,,,,
//,,,,,,,,&@&&&&&&&&&&&&&@,,,,,,,,,,,,,,,,,,,,,,,,,,.@@@@@@@@@@@.,,,,,,,,,,,,,,,,,
//,,,,,,,,(((((##&&&&&&@@@,,,,,,,,,,,,,,,,,,,,,,,,,/(@&&&&&&&&@@@,,,,,,,,,,,,,,,,,
//,,,,,,,,,((((((#&#((#&@&/(#,.,,,,,,,,.,,,,,,,,,,,((&&&&&&&&&&@@,,,,,,,,,,,,,,,,,
//,,,,,,,,,,##(((((((((((#**#%%%#######(,,,,,,,,,,,/(///&&&&&&&@@,,,,,,,,,,,,,,,,,
//,,,,,,,,,,(((((((((((((***/%#####%%###%%%%,,,,,,,////////////((,,,,,,,,,,,,,,,,,
//,,,,,,,,,,/(###((#((#(/****##############%%#,..,,.(/(/////////(,,,,,,,,,,,,,,,,,
//,,,,,,,,,(#%%%%%%##%%%%(***#%#########%%#***/,,,,.%%(/*******/##,,,,,,,,,,,,,,,,
//,,,,,,,,(#%#########/******(###%#####%(/***//*(#%%#*****/#%%%#%%,,,,,,,,,,,,,,,,
//,,,,,,,.,#%########%%(/*****%####%###%//*/***/####**/#%#####%%##%#,,,,,,,,,,,,,,
//,,,,,,,,,#####%(#%##%%#/****(%%%%#####(/***//###%%#%%%##########%#,,,,,,,,,,,,,,
//,,,..,,,,##########%###%#**#############%##%%##%%##%#########%%%%#,,,,,,,,,,,,,,
//,,.,,,,,,#(###%###%#(######################%%%###%%###########%%%#,,,,,,,,,,,,,,
//,,.,,,,,,##%%%%%##################################%########%#%%%%#,,,,,,,,,,,,,,
//,../***/////////**%############%%%%%%#####%%#################%%%%#,,,,,,,,,,,,,,
//,,/*////////////(/*%#%%%%%%#%###%%%%%#######################%%%%,,,,,,,,,,,,,,,,
//,,,,,,,,,(///((#%%%#%%%%%%%%%########%#############%######%%%%%%%%####,,,,,,,,,,
//,,,,,,,,,,,,,,,,%%##%%%%%###########%%#########%%##%%%##%%%%%%%###########(,,,,,
//,,,,,,,,,,,,,,,,,,#%######%##%#####%#%###%#%%%%%%%%####%%%%#%%###############,,,
//,,,,,,,,,,,,,,,,,,############(/(#####%%%%%%%%%%%%#########%################%%,,
//,,,,,,,,,,,,,,,,,,#######%###////((%######%##############%%#%%%%%%###%%%%%##%%%,
//,,,,,,,,,,,,,,,,,#%####%%##%//////(#########%%%%%%%%#######%%%%######%%%###%%%%,
//,,,,,,,,,,,,,,,,,#%#%%%##%#//////((########################%%%%%%%%%%##########,
//,,,,,,,,,,,,,,,,,#%####%%%(//////(###################%%####%%##%%%%%%#,,,,,,,,,,
//,,,,,,,,,,,,,,,,,(%%%##%#/////(((/##################%%%%%###%%%%%%%%%%%,,,,,,,,,
//,,,,,,,,,,,,,,,,,((##%#(///(/,,,//#######%#%%%%%%%%%%%%%%%##%%%%%%%%%#%%#/,,,,,,
//,,,,,,,,,,,,,,,,((//////////,,,,//#######%%%%%%%%%%%%%%%%%%##%%%###%%%%,,,,,,,,,

import "./ERC721.sol";
import "./Math.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./IERC721Receiver.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./ERC165.sol";
import "./Context.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";

// File: contracts/ERC721B.sol

pragma solidity ^0.8.0;

/********************
 * @author: Squeebo *
 ********************/

abstract contract ERC721B is Context, ERC165, IERC721, IERC721Metadata {
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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );

        uint256 count = 0;
        uint256 length = _owners.length;
        for (uint256 i = 0; i < length; ++i) {
            if (owner == _owners[i]) {
                ++count;
            }
        }

        delete length;
        return count;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
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
        address owner = ERC721B.ownerOf(tokenId);
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
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
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
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721B.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
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
        address owner = ERC721B.ownerOf(tokenId);

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
        require(
            ERC721B.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
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
        emit Approval(ERC721B.ownerOf(tokenId), to, tokenId);
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
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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

// File: contracts/ERC721EnumerableLite.sol

pragma solidity ^0.8.0;

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableLite is ERC721B, IERC721Enumerable {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721B)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256 tokenId)
    {
        require(
            index < ERC721B.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );

        uint256 count;
        for (uint256 i; i < _owners.length; ++i) {
            if (owner == _owners[i]) {
                if (count == index) return i;
                else ++count;
            }
        }

        require(false, "ERC721Enumerable: owner index out of bounds");
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721EnumerableLite.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return index;
    }
}

// File: contracts/OscarSlaps.sol

pragma solidity ^0.8.2;

contract OscarSlaps is ERC721EnumerableLite, Ownable, PaymentSplitter {
    using Strings for uint256;

    uint256 public _price = 0.02 ether;
    uint256 public _max = 2000;
    uint256 public _txnLimit = 10;
    bool public _saleIsActive = false;

    uint256 public _totalFree = 0;
    uint256 public _freeLimit = 3;
    uint256 public _freeMinted = 0;
    mapping(address => uint256) public _freeTracker;

    string private _tokenBaseURI;

    address[] private addressList = [
        0x304B37026D67DdDb2C2e2CdE94F099E88F25887c,
        0x505C596a88D8cD340FF1e3E61429B570DA4C71c9,
        0x7C1Ec007437759153c73E00333f8b249420C5e0E,
        0x7e5aa86d96f2F2f047afe6577033c0d6C093D924
    ];

    uint256[] private shareList = [15, 15, 35, 35];

    constructor()
        ERC721B("OscarSlaps", "SLAPS")
        PaymentSplitter(addressList, shareList)
    {}

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(_tokenBaseURI, tokenId.toString(), ".json")
            );
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _tokenBaseURI = uri;
    }

    function flipSaleState() public onlyOwner {
        _saleIsActive = !_saleIsActive;
    }

    function mint(uint256 total) public payable {
        require(_saleIsActive, "Sale is not active");
        require(total > 0, "Number to mint must be greater than 0");
        require(total <= _txnLimit, "Over transaction limit");
        require(
            calcMintingFee(total) <= msg.value,
            "Ether value sent is not correct"
        );
        uint256 supply = _owners.length;
        require(supply + total <= _max, "Purchase would exceed max supply");

        for (uint256 i = 0; i < total; i++) {
            _safeMint(msg.sender, supply++);
        }
    }

    function calcMintingFee(uint256 total) internal returns (uint256 cost) {
        uint256 freeMints = 0;

        if (_freeMinted < _totalFree && _freeTracker[msg.sender] < _freeLimit) {
            freeMints = Math.min(_freeLimit, total);
            freeMints = Math.min(
                freeMints,
                _freeLimit - _freeTracker[msg.sender]
            );
            require(
                _freeMinted + freeMints <= _totalFree,
                "No more free mints available"
            );
            _freeTracker[msg.sender] += freeMints;
            _freeMinted += freeMints;
        }

        return (total - freeMints) * _price;
    }

    function freeMintsRemaining(address addr)
        public
        view
        returns (uint256 remaining)
    {
        return _freeLimit - _freeTracker[addr];
    }
}
