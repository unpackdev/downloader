// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC2981.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";

contract ZombieGoblin is ERC2981, ERC721AQueryable, Ownable {
    using Address for address payable;
    using Strings for uint256;

    bytes32 public immutable _lotterySalt;
    uint256 public immutable _price;
    uint32 public immutable _maxSupply;
    uint32 public immutable _teamSupply;
    uint32 public immutable _instantFreeSupply;
    uint32 public immutable _instantFreeWalletLimit;
    uint32 public immutable _walletLimit;

    uint32 public _teamMinted;
    uint32 public _instantFreeMinted;
    bool public _started;
    string public _metadataURI = "https://metadata.zombiearmy.io/json/";

    struct Status {
        // config
        uint256 price;
        uint32 maxSupply;
        uint32 publicSupply;
        uint32 instantFreeSupply;
        uint32 instantFreeWalletLimit;
        uint32 walletLimit;

        // state
        uint32 publicMinted;
        uint32 instantFreeMintLeft;
        uint32 userMinted;
        bool soldout;
        bool started;
    }

    constructor(
        uint256 price,
        uint32 maxSupply,
        uint32 teamSupply,
        uint32 instantFreeSupply,
        uint32 instantFreeWalletLimit,
        uint32 walletLimit
    ) ERC721A("ZombieGoblin", "ZG") {
        require(maxSupply >= teamSupply + instantFreeSupply);

        _lotterySalt = keccak256(abi.encodePacked(address(this), block.timestamp));
        _price = price;
        _maxSupply = maxSupply;
        _teamSupply = teamSupply;
        _instantFreeSupply = instantFreeSupply;
        _instantFreeWalletLimit = instantFreeWalletLimit;
        _walletLimit = walletLimit;

        setFeeNumerator(750);
    }

    function mint(uint32 amount) external payable {
        require(_started, "ZombieGoblin: Sale is not started");

        uint32 publicMinted = _publicMinted();
        uint32 publicSupply = uint32(_publicSupply());
        require(amount + publicMinted <= publicSupply, "ZombieGoblin: Exceed max supply");

        uint32 minted = uint32(_numberMinted(msg.sender));
        require(amount + minted <= _walletLimit, "ZombieGoblin: Exceed wallet limit");

        uint32 instantFreeWalletLimit = _instantFreeWalletLimit;
        uint32 instantFreeQuota = _instantFreeSupply - _instantFreeMinted;
        instantFreeQuota = instantFreeWalletLimit > instantFreeQuota ? instantFreeQuota : instantFreeWalletLimit;
        uint32 freeAmount = 0;
        if (minted < instantFreeQuota) {
            uint32 quota = instantFreeQuota - minted;
            freeAmount += quota > amount ? amount : quota;
            _instantFreeMinted += freeAmount;
        }

        uint256 requiredValue = (amount - freeAmount) * _price;
        require(msg.value >= requiredValue, "ZombieGoblin: Insufficient fund");

        _safeMint(msg.sender, amount);
    }

    function _publicMinted() public view returns (uint32) {
        return uint32(_totalMinted()) - _teamMinted;
    }

    function _publicSupply() public view returns (uint32) {
        return _maxSupply - _teamSupply;
    }

    function _status(address minter) external view returns (Status memory) {
        uint32 publicSupply = _maxSupply - _teamSupply;
        uint32 publicMinted = uint32(ERC721A._totalMinted()) - _teamMinted;

        return Status({
            // config
            price: _price,
            maxSupply: _maxSupply,
            publicSupply:publicSupply,
            instantFreeSupply: _instantFreeSupply,
            instantFreeWalletLimit: _instantFreeWalletLimit,
            walletLimit: _walletLimit,

            // state
            publicMinted: publicMinted,
            instantFreeMintLeft: _instantFreeSupply - _instantFreeMinted,
            soldout:  publicMinted >= publicSupply,
            userMinted: uint32(_numberMinted(minter)),
            started: _started
        });
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _metadataURI;
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function devMint(address[] memory tos, uint32[] memory amounts) external onlyOwner {
        uint32 totalAmount = 0;
        for (uint i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }

        _teamMinted += totalAmount;
        require(_teamMinted <= _teamSupply, "ZombieGoblin: Exceed max supply");

        for (uint i = 0; i < amounts.length; i++) {
            _safeMint(tos[i], amounts[i]);
        }
    }

    function setFeeNumerator(uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setStarted(bool started) external onlyOwner {
        _started = started;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }
}
