//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./Ownable.sol";

// for click to source
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";

contract Memento is Context, ERC165, IERC721, IERC721Metadata, Ownable {
    //
    // Libraries
    //

    using Address for address;
    using Strings for uint256;

    //
    // Constants
    //

    // Token name
    string private _name = "Project Memento";

    // Token symbol
    string private _symbol = "MEM";

    //
    // Variables
    //

    // The price at which characters without owners
    uint256 public mintAmount;
    uint256 public multiplier;
    uint256 public cap;

    // Metadata linked to an NFT
    struct Tile {
        string char;
        address owner;
    }

    // This represents a matrix of tiles
    Tile[20][20] public tiles; // TODO: it'd be good to hardcore these numbers

    //
    // Maps
    //

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals; // TODO: what??

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals; // TODO: what?

    //
    // Constructor
    //

    constructor(
        uint256 _mintAmount,
        uint256 _multiplier,
        uint256 _cap
    ) Ownable() {
        mintAmount = _mintAmount;
        multiplier = _multiplier;
        cap = _cap;
    }

    //
    // ERC-165
    //

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

    //
    // ERC-721
    //

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
        return _balances[owner];
    }

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

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

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

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    //
    // Helpers for ERC-721
    //

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

    // TODO: I can simply check that it converts back to a valid tokenId no?
    // TODO: also this is more like "it does not have an owner", where is this used?
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

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
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    //
    // Contract logic
    //

    // a tile was altered!
    event Alteration(
        uint256 indexed _x,
        uint256 indexed _y,
        string _char,
        address owner
    );

    // set the price to pay to mint new tiles
    function setMintAmount(uint256 _mintAmount) public onlyOwner {
        mintAmount = _mintAmount;
    }

    // check if it's a valid char in the range of visible ASCII symbols
    function requireValidChar(string memory _char) private pure {
        bytes memory strBytes = bytes(_char);
        require(strBytes.length == 1);
        require(strBytes[0] > 0x20); // !
        require(strBytes[0] < 0x7F); // ~
    }

    // converts coordinates x and y into a tokenId, deterministically
    function coordsToTokenId(uint256 _x, uint256 _y)
        private
        pure
        returns (uint256)
    {
        assert(_x < 20);
        assert(_y < 20);
        return _x * 20 + _y;
    }

    // converts a tokenId into coordinates x and y, deterministically
    // (the inverse of the function above)
    function tokenIdToCoords(uint256 _tokenId)
        private
        pure
        returns (uint256, uint256)
    {
        assert(_tokenId < 20 * 20);
        uint256 _x = _tokenId / 20; // TODO: test that
        uint256 _y = _tokenId % 20;
        return (_x, _y);
    }

    // mint a tile that belongs to no one (yet)
    function mintLetter(
        uint256 _x,
        uint256 _y,
        string memory _char
    ) public payable returns (uint256) {
        require(_x < 20); // TODO: this is unecessary atm as the array is already constrained
        require(_y < 20);
        require(msg.value >= mintAmount);
        Tile memory tile = tiles[_x][_y];
        require(tile.owner == 0x0000000000000000000000000000000000000000);
        requireValidChar(_char);

        // derive tokenId
        uint256 tokenId = coordsToTokenId(_x, _y);

        // set tile
        tile.char = _char;
        tile.owner = msg.sender;
        tiles[_x][_y] = tile;

        // update maps
        _balances[msg.sender] += 1;
        _owners[tokenId] = msg.sender;

        // event
        emit Transfer(address(0), msg.sender, tokenId);
        emit Alteration(_x, _y, _char, msg.sender);

        // increase price if we're lower than the cap
        if (mintAmount <= cap) {
            mintAmount = (mintAmount * multiplier) / 100;
        }

        // return token id
        return tokenId;
    }

    // allows the owner of a tile to alter it
    function alterLetter(
        uint256 _x,
        uint256 _y,
        string memory _char
    ) public {
        require(_x < 20);
        require(_y < 20);
        Tile memory tile = tiles[_x][_y];
        require(tile.owner == msg.sender);

        // alert
        tiles[_x][_y].char = _char;

        // event
        emit Alteration(_x, _y, _char, msg.sender);
    }

    //
    // ERC721Metadata
    //

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "the tile does not exists");
        require(tokenId < 20 * 20);

        (uint256 _x, uint256 _y) = tokenIdToCoords(tokenId);

        string memory url = "https://project-memento.com/metadata/";
        url = string(abi.encodePacked(url, _x.toString()));
        url = string(abi.encodePacked(url, "-"));
        url = string(abi.encodePacked(url, _y.toString()));
        url = string(abi.encodePacked(url, ".json"));
        return url;
    }

    //
    // Admin logic
    //

    // admin function to withdraw paid fees in the contract (anyone can call it)
    function adminWithdraw() public {
        require(
            msg.sender == 0x9B14624A80e8C40aEfA604bE8Cba683b2cE987Cd ||
                msg.sender == 0x1E4F1275bB041586D7Bec44D2E3e4F30e0dA7Ba4 ||
                msg.sender == 0xe1811eC49f493afb1F4B42E3Ef4a3B9d62d9A01b ||
                msg.sender == owner()
        );

        // divide the amount for founders
        uint256 perFounder = address(this).balance / 3;
        payable(address(0x9B14624A80e8C40aEfA604bE8Cba683b2cE987Cd)).transfer(
            perFounder
        );
        payable(address(0x1E4F1275bB041586D7Bec44D2E3e4F30e0dA7Ba4)).transfer(
            perFounder
        ); // simon
        payable(address(0xe1811eC49f493afb1F4B42E3Ef4a3B9d62d9A01b)).transfer(
            perFounder
        ); // david
    }

    //
    // Maybe delete?
    //

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
