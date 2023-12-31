// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract EdmusCards is ERC721A, Ownable, Pausable {

    enum Category {
        Magnum,
        Jeroboam,
        Balthazar
    }

    struct AmountOfCardsMinted {
        uint256 magnum;
        uint256 jeroboam;
        uint256 balthazar;
    }

    struct MaxSupplyOfCards {
        uint256 magnum;
        uint256 jeroboam;
        uint256 balthazar;
    }

    string public baseURI;

    address public saleAddress;

    mapping(uint256 => bool) public usedOrderIds;
    mapping(uint256 => Category) public categoryOfCard;

    AmountOfCardsMinted public amountOfCardsMinted;
    MaxSupplyOfCards public maxSupplyOfCards;

    event Mint(
        address indexed to,
        uint256 amountMagnum,
        uint256 amountJeroboam,
        uint256 amountBalthazar,
        uint256 firstTokenId,
        uint256 orderID
    );

    event Drop(
        address indexed to,
        uint256 amountMagnum,
        uint256 amountJeroboam,
        uint256 amountBalthazar,
        uint256 firstTokenId
    );

    modifier checkSupplies(
        uint256 amountMagnum,
        uint256 amountJeroboam,
        uint256 amountBalthazar
    ) {
        require(
            amountOfCardsMinted.magnum + amountMagnum <= maxSupplyOfCards.magnum,
            "EdmusCards: MAX_SUPPLY_MAGNUM_REACHED"
        );
        require(
            amountOfCardsMinted.jeroboam + amountJeroboam <= maxSupplyOfCards.jeroboam,
            "EdmusCards: MAX_SUPPLY_JEROBOAM_REACHED"
        );
        require(
            amountOfCardsMinted.balthazar + amountBalthazar <= maxSupplyOfCards.balthazar,
            "EdmusCards: MAX_SUPPLY_BALTHAZAR_REACHED"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupplyOfMagnum,
        uint256 _maxSupplyOfJeroboam,
        uint256 _maxSupplyOfBalthazar
    ) ERC721A(_name, _symbol)
    {
        maxSupplyOfCards = MaxSupplyOfCards({
            magnum: _maxSupplyOfMagnum,
            jeroboam: _maxSupplyOfJeroboam,
            balthazar: _maxSupplyOfBalthazar
        });
    }

    function batchMint(
        address to,
        uint256 amountMagnum,
        uint256 amountJeroboam,
        uint256 amountBalthazar,
        uint256 orderId
    ) external checkSupplies(amountMagnum, amountJeroboam, amountBalthazar) {
        require(msg.sender == saleAddress, "Not allowed");
        require(!usedOrderIds[orderId], "EdmusCards: used order ID");
        usedOrderIds[orderId] = true;

        uint256 firstTokenId = totalSupply() + 1;
        _mintCards(to, amountMagnum, amountJeroboam, amountBalthazar, firstTokenId);

        emit Mint(to, amountMagnum, amountJeroboam, amountBalthazar, firstTokenId, orderId);
    }

    function drop(
        address to,
        uint256 amountMagnum,
        uint256 amountJeroboam,
        uint256 amountBalthazar
    ) public onlyOwner checkSupplies(amountMagnum, amountJeroboam, amountBalthazar) {
        uint256 firstTokenId = totalSupply() + 1;
        _mintCards(to, amountMagnum, amountJeroboam, amountBalthazar, firstTokenId);

        emit Drop(to, amountMagnum, amountJeroboam, amountBalthazar, firstTokenId);
    }

    function _mintCards(
        address to,
        uint256 amountMagnum,
        uint256 amountJeroboam,
        uint256 amountBalthazar,
        uint256 firstTokenId
    ) internal {
        for (uint256 i = 0; i < amountMagnum; i++) {
            categoryOfCard[firstTokenId + i] = Category.Magnum;
        }
        for (uint256 i = 0; i < amountJeroboam; i++) {
            categoryOfCard[firstTokenId + amountMagnum + i] = Category.Jeroboam;
        }
        for (uint256 i = 0; i < amountBalthazar; i++) {
            categoryOfCard[firstTokenId + amountMagnum + amountJeroboam + i] = Category.Balthazar;
        }

        amountOfCardsMinted.magnum += amountMagnum;
        amountOfCardsMinted.jeroboam += amountJeroboam;
        amountOfCardsMinted.balthazar += amountBalthazar;

        _safeMint(to, amountMagnum + amountJeroboam + amountBalthazar);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function setSaleAddress(address _saleAddress) public onlyOwner {
        saleAddress = _saleAddress;
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        require(!paused(), "Pausable: token transfer while paused");
    }

}
