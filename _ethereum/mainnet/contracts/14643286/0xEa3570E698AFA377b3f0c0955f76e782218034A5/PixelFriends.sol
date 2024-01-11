// SPDX-License-Identifier: MIT
import "./Address.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";

pragma solidity ^0.8.0;

contract PixelFriends is ERC721A, Ownable, PaymentSplitter, ReentrancyGuard {
    using ECDSA for bytes32;
    using Strings for uint256;
    using Address for address payable;

    struct saleParams {
        string name;
        uint256 price;
        uint64 startTime;
        uint64 endTime;
        uint64 supply;
        uint32 claimable;
        bool requireSignature;
    }

    address private signer = 0xe61F5A159a82888f88bEcb2B5C3d7bBB7260ef0F;

    address[] private _team = [
        0x7F69FD48122F79B06916f2705dE4a80D7978eF26,
        0x42AD36b7C4D208858020D95DC3Ae50dd99588fA1,
        0xb32586614aAc71B83a4dc1C83D20e4Fc0e7C407c,
        0xE5401538A12c560d954B896f35A62f14c1BE7A09,
        0x96f4B26D2ECDB2390cca3f493433BE5a7EA3792A
    ];
    uint256[] private _teamShares = [2750, 2750, 2750, 750, 1000];

    uint256 public constant MAX_SUPPLY = 10_000;

    mapping(uint32 => saleParams) public sales;
    mapping(string => mapping(address => uint256)) public mintsPerWallet;
    mapping(string => uint256) public mintsPerSale;
    string public baseURI;
    bool public revealed;

    event TokensMinted(address mintedBy, uint256 quantity, string saleName);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _newBaseURI
    ) ERC721A(_name, _symbol) PaymentSplitter(_team, _teamShares) {
        baseURI = _newBaseURI;
    }

    // MODIFIERS
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // ADMIN
    function withdrawAll() external onlyOwner nonReentrant {
        for (uint32 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setReveal(bool _revealed) external onlyOwner {
        revealed = _revealed;
    }

    function setSignerAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Invalid address.");
        signer = _newAddress;
    }

    function configureSale(
        uint32 _id,
        string memory _name,
        uint256 _price,
        uint64 _startTime,
        uint64 _endTime,
        uint64 _supply,
        uint32 _claimable,
        bool _requireSignature
    ) external onlyOwner {
        require(_startTime > 0 && _endTime > 0 && _endTime > _startTime, "Time range is invalid.");
        sales[_id] = saleParams(_name, _price, _startTime, _endTime, _supply, _claimable, _requireSignature);
    }

    // VIEW
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI();
        if (!revealed) {
            return bytes(base).length > 0 ? string(abi.encodePacked(base)) : "";
        }
        return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString())) : "";
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    // MINT
    function airdrop(address _to, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left.");
        internalMint(_to, quantity);
    }

    function saleMint(
        uint32 _saleId,
        uint256 quantity,
        uint256 _alloc,
        bytes calldata _signature
    ) external payable callerIsUser {
        saleParams memory _sale = sales[_saleId];
        require(_sale.startTime > 0 && _sale.endTime > 0, "Sale doesn't exists");

        uint256 alloc = _sale.requireSignature ? _alloc : uint256(_sale.claimable);

        if (_sale.requireSignature) {
            bytes32 _messageHash = hashMessage(abi.encode(_sale.name, address(this), _msgSender(), _alloc));
            require(verifyAddressSigner(_messageHash, _signature), "Invalid signature.");
        }
        require(quantity > 0, "Wrong amount requested");
        require(block.timestamp > _sale.startTime && block.timestamp < _sale.endTime, "Sale is not active.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left.");
        require(mintsPerSale[_sale.name] + quantity <= _sale.supply, "Not enough supply.");

        require(msg.value >= quantity * uint256(_sale.price), "Insufficient amount.");
        require(mintsPerWallet[_sale.name][_msgSender()] + quantity <= alloc, "Allocation exceeded.");

        mintsPerWallet[_sale.name][_msgSender()] += quantity;
        mintsPerSale[_sale.name] += quantity;
        internalMint(_msgSender(), quantity);
        emit TokensMinted(_msgSender(), quantity, _sale.name);
    }

    // INTERNAL
    function internalMint(address _to, uint256 quantity) internal {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left.");
        _safeMint(_to, quantity);
    }

    function internalBurn(uint256 _tokenId) internal {
        _burn(_tokenId, true);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // PRIVATE
    function verifyAddressSigner(bytes32 _messageHash, bytes memory _signature) private view returns (bool) {
        return signer == _messageHash.toEthSignedMessageHash().recover(_signature);
    }

    function hashMessage(bytes memory _msg) private pure returns (bytes32) {
        return keccak256(_msg);
    }
}
