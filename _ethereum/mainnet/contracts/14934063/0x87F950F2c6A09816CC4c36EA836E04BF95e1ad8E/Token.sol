// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./ERC721A.sol";

contract Token is ERC721A, Ownable {
    enum Status {
        Waiting,
        Started,
        Finished
    }

    Status public status;
    string public baseURI;

    // moving all configs under a 256 bit space to save cost
    struct Config {
        uint16 maxSupply;
        uint16 maxQuantityPerPublic; // max quantity per public mint address
    }
    Config public config;

    // EVENTS
    event Minted(address minter, uint256 amount);
    event BaseURIChanged(string newBaseURI);
    event StatusChanged(Status status);

    // CONSTRUCTOR
    constructor(string memory initBaseURI) ERC721A("Magic Mirror", "MMNFT") {
        baseURI = initBaseURI;
        config.maxSupply = 500;
        config.maxQuantityPerPublic = 1;
    }

    // MODIFIERS
    function mintComplianceBase(uint256 _qunatity) public view {
        require(
            totalSupply() + _qunatity <= config.maxSupply,
            "sold out."
        );
    }

    modifier mintComplianceForPublic(uint256 _qunatity) {
        mintComplianceBase(_qunatity);
        require(status == Status.Started, "Hai mei kai shi.");
        require(
            numberMintedForPublic(msg.sender) + _qunatity <=
                config.maxQuantityPerPublic,
            "max hold."
        );
        _;
    }

    modifier OnlyUser() {
        require(tx.origin == msg.sender, "deny contract call.");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // MINTING LOGICS
    function mintMagicMirror(uint256 quantity)
        external
        OnlyUser
        mintComplianceForPublic(quantity)
    {
        _safeMint(msg.sender, quantity);
        emit Minted(msg.sender, quantity);
    }

    function numberMintedForPublic(address owner)
        public
        view
        returns (uint256)
    {
        return _numberMinted(owner) - uint256(_getAux(owner));
    }

    // SETTERS
    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(status);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        config.maxSupply = uint16(_maxSupply);
    }

    function setMaxQuantiyPerAddress(
        uint256 _maxQuantityPerPublic
    ) public onlyOwner {
        config.maxQuantityPerPublic = uint16(_maxQuantityPerPublic);
    }
}