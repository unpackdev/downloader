// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "./Context.sol";
import "./AccessControlEnumerable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC20Burnable.sol";
import "./I1MIL.sol";


contract Tile is Context, ERC721Enumerable {

    address private moneybox = 0xA2eb9BfF23f5117979767bD0c51BE8E2F7Fbf52F;
    address private free = 0x1cc1bD553dF7f45F697a85Cac7a121c0A7E2e1C4;

    ERC20Burnable mil;

    struct TileInfo {
        string title;
        string ownerURL;
        uint256[100] colors;
    }

    struct Invoice {
        address sender;
        uint256 amount;
        uint timestamp;
    }

    mapping(uint256 => Invoice) private invoiceMap;
    uint256 lastInvoiceNumber = 0;

    // Mapping from token ID to Tile objects
    mapping(uint256 => TileInfo) private tiles;

    mapping(address => bool) private owners;

    mapping(uint256 => bool) usedNonces;

    constructor(ERC20Burnable _mil) ERC721('Tile', 'TIL') {
        owners[msg.sender] = true;
        mil = _mil;
    }

    function mint(address to, uint256 tokenId) public {
        require(owners[msg.sender], "Tile: must have admin role to mint");
        _mint(to, tokenId);
    }

    function addOwner(address newOwner) public {
        require(owners[msg.sender], "Tile: Only owner can add owners");
        owners[newOwner] = true;
    }

    function removeOwner(address oldOwner) public {
        require(owners[msg.sender], "Tile: Only owner can add owners");
        require(address(msg.sender) != address(oldOwner), "Tile: Only owner can add owners");
        owners[oldOwner] = false;
    }

    function baseTokenURI() public pure returns (string memory) {
        return "https://api.mil.zyxit.dev/api/nft/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.mil.zyxit.dev/api/proj-info";
    }

    function tokenURI(uint256 _tokenId) override public pure returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }


    function payForInfoAndColors(uint256 totalPrice) public {

        if (totalPrice > 0) {
            mil.transferFrom(address(tx.origin), address(this), totalPrice / 2);
            mil.transferFrom(address(tx.origin), moneybox, totalPrice / 2);
            mil.burn(mil.balanceOf(address(this)));
        }

        Invoice memory invoice = Invoice(msg.sender, totalPrice, block.timestamp);
        uint256 invoiceId = ++lastInvoiceNumber;
        invoiceMap[invoiceId] = invoice;
    }

    function getInvoice(uint256 invoiceId) public view returns (address, uint256, uint256){
        return (invoiceMap[invoiceId].sender, invoiceMap[invoiceId].amount, invoiceMap[invoiceId].timestamp);
    }


    function setInfo(uint256 id, string memory title, string memory ownerURL) public {
        require(ownerOf(id) == msg.sender, "Tile: only owner can save Info");

        if (msg.sender != free) {
            mil.transferFrom(address(tx.origin), address(this), 500000000000000000);
            mil.transferFrom(address(tx.origin), moneybox, 500000000000000000);
            mil.burn(mil.balanceOf(address(this)));
        }

        tiles[id].title = title;
        tiles[id].ownerURL = ownerURL;
    }

    function setColors(uint256 id, uint256[100] memory colors) public {
        require(ownerOf(id) == msg.sender, "Tile: only owner can save Info");

        if (msg.sender != free) {
            mil.transferFrom(address(tx.origin), address(this), 500000000000000000);
            mil.transferFrom(address(tx.origin), moneybox, 500000000000000000);
            mil.burn(mil.balanceOf(address(this)));
        }

        tiles[id].colors = colors;
    }

    function setMultiColors(uint256[] memory ids, uint256[100][] memory colors) public {
        for(uint256 i = 0; i < ids.length;i++){
            setColors(ids[i],colors[i]);
        }
    }

    function setInfoAndColors(uint256 id, string memory title, string memory ownerURL, uint256[100] memory colors) public {
        require(ownerOf(id) == msg.sender, "Tile: only owner can save Info");

        if (msg.sender != free) {
            mil.transferFrom(address(tx.origin), address(this), 1000000000000000000);
            mil.transferFrom(address(tx.origin), moneybox, 1000000000000000000);
            mil.burn(mil.balanceOf(address(this)));
        }

        tiles[id].title = title;
        tiles[id].ownerURL = ownerURL;
        tiles[id].colors = colors;
    }

    function getTileInfo(uint256 id) public view returns (string memory, string memory, uint256[100] memory){
        TileInfo memory tile = tiles[id];
        return (tile.title, tile.ownerURL, tile.colors);
    }

    function getOneMil() public view returns (address) {
        return address(mil);
    }

    function buyTile(uint256 tileId, uint256 totalPrice,
        uint256 nonce, uint8 v, bytes32 r, bytes32 s) public {

        require(!usedNonces[nonce]);
        usedNonces[nonce] = true;

        bytes32 message = prefixed(keccak256(abi.encodePacked(uint256(1), msg.sender, tileId, totalPrice, nonce, this)));

        require(owners[ecrecover(message, v, r, s)], "Tile: signature error");

        if (totalPrice > 0) {
            mil.transferFrom(address(tx.origin), moneybox, totalPrice - (totalPrice / 2));
            mil.burnFrom(address(tx.origin), totalPrice / 2);
        }

        _mint(msg.sender, tileId);
    }

    function buyTiles(uint256[] calldata tilesId, uint256 totalPrice,
        uint256 nonce, uint8 v, bytes32 r, bytes32 s) public {
        require(!usedNonces[nonce]);
        usedNonces[nonce] = true;

        uint256 concatId = tilesId[0];
        for (uint256 i = 1; i < tilesId.length; i++) {
            concatId = concatId ^ tilesId[i];
        }

        bytes32 message = prefixed(keccak256(abi.encodePacked(uint256(1), msg.sender, concatId, totalPrice, nonce, this)));

        require(owners[ecrecover(message, v, r, s)], "Tile: signature error");
        if (totalPrice > 0) {
            mil.transferFrom(address(tx.origin), moneybox, totalPrice - (totalPrice / 2));
            mil.burnFrom(address(tx.origin), totalPrice / 2);
        }

        for (uint256 i = 0; i < tilesId.length; i++) {
            _mint(msg.sender, tilesId[i]);
        }

    }

    function setMoneyBox(address _moneybox) public {
        require(owners[msg.sender], 'Only Owner can change MoneyBox');
        moneybox = _moneybox;
    }

    function getMoneyBox() public view returns (address) {
        return moneybox;
    }


    function setFree(address _free) public {
        require(owners[msg.sender], 'Only Owner can change Free');
        free = _free;
    }

    function getFree() public view returns (address) {
        return free;
    }

    /// builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    function checkOwner(uint256[] calldata tilesId, address _owner) public view returns (bool) {
        for (uint256 i = 0; i < tilesId.length; i++) {
            if (ownerOf(tilesId[i]) != _owner) return false;
        }
        return true;
    }
}
