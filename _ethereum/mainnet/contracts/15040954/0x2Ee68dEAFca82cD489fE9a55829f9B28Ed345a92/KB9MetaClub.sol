// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./PaymentSplitter.sol";
import "./ERC721A.sol";

pragma solidity ^0.8.4;

contract KB9MetaClub is  Ownable, ERC721A, ReentrancyGuard, PaymentSplitter {
    using ECDSA for bytes32;
    using Strings for uint256;

    event SaleUpdate(uint32 indexed saleId);

    address[] private _team = [
        0x60A37f734d3f694E4F882e7Ea42e49FBe39FFccF,
        0xB4187C693bf337fE039C656B742a47a3dE418281,
        0xC5c29c1AecEa6eCd8a21FaB49418C08497A44aC4
    ];

    uint256[] private _teamShares = [70000,19000,11000];

    struct saleParams {
        string name;
        uint256 price;
        uint64 startTime;
        uint64 endTime;
        uint64 supply;
        uint32 claimable;
        bool requireSignature;
    }
    mapping(uint32 => saleParams) public sales;
    mapping(uint32 => uint256) public mintsPerSale;
    uint256 public maxSupply = 1999;
    bool  private revealState = false;
    string public baseURI;

    address private deployer;

    constructor() ERC721A("KB9MetaClub", "KB9MC")  PaymentSplitter(_team, _teamShares) {
        deployer = msg.sender;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
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
        emit SaleUpdate(_id);
    }

    function saleMint(
        uint32 _saleId,
        uint256 numberOfTokens,
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
        require(numberOfTokens > 0, "Wrong amount requested");
        require(block.timestamp > _sale.startTime && block.timestamp < _sale.endTime, "Sale is not active.");
        require(totalSupply() + numberOfTokens <= maxSupply, "Not enough tokens left.");
        require(mintsPerSale[_saleId] + numberOfTokens <= _sale.supply, "Not enough supply.");
        require(msg.value >= numberOfTokens * uint256(_sale.price), "Insufficient amount.");

        uint32[] memory _mintPerWallet = unpackAux(_getAux(_msgSender()));
        _mintPerWallet[_saleId]+= uint32(numberOfTokens);
        require(_mintPerWallet[_saleId] <= alloc, "Allocation exceeded.");

        mintsPerSale[_saleId] += numberOfTokens;
        mintInternal(_msgSender(), numberOfTokens);
        _setAux(_msgSender(), packAux(_mintPerWallet));
    }

    function mintInternal(address wallet, uint amount) internal {
        require(totalSupply() + amount <= maxSupply, "Not enough tokens left");
        _safeMint(wallet, amount);
    }

    function airdropToWallet(address walletAddress, uint amount) external onlyOwner{
        mintInternal(walletAddress, amount);
    }

    function getMintPerSale(address _wallet) public view returns(uint32[] memory mintPerSales) {
       return mintPerSales = unpackAux(_getAux(_wallet));
    }

    function withdrawAll() external onlyOwner nonReentrant {
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }

    function changeStateReveal() public onlyOwner returns(bool) {
        revealState = !revealState;
        return revealState;
    }

    function setBaseURI(string calldata _newBaseUri) external onlyOwner {
        baseURI = _newBaseUri;
    }

    function changeDeployer(address _newDeployer) public onlyOwner returns(address) {
        deployer = _newDeployer;
        return deployer;
    }

    function verifyAddressSigner(bytes32 _messageHash, bytes memory _signature) private view returns (bool) {
        return deployer == _messageHash.toEthSignedMessageHash().recover(_signature);
    }

    function hashMessage(bytes memory _msg) private pure returns (bytes32) {
        return keccak256(_msg);
    }

    function packAux(uint32[] memory _mintPerWallet) private pure returns(uint64) {
        return (uint64(_mintPerWallet[0]) << 32) | uint64(_mintPerWallet[1]);
    }

    function unpackAux(uint64 _aux) private pure returns(uint32[] memory) {
        uint32[] memory _mintPerWallet = new uint32[](2);
        _mintPerWallet[0] = uint32(_aux >> 32);
        _mintPerWallet[1] = uint32(_aux);
        return _mintPerWallet;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        if (!revealState) {
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI)) : "";
        }

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}