// SPDX-License-Identifier: MIT
import "./ERC1155Supply.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

pragma solidity ^0.8.0;

// @author: Array
// dsc: Array#0007
// tw: @arraythedev
// Contact me on twitter

contract HumansFactoryPass is ERC1155Supply, Ownable, PaymentSplitter, ReentrancyGuard {
    using ECDSA for bytes32;
    using Strings for uint256;
    using Address for address payable;

    struct saleParams {
        string name;
        bool requireSignature;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        uint256 claimable;
        uint256 supply;
        uint256 tokenId;
    }

    address private signerAddress = 0xDC90586e77086E3A236ad5145df7B4bd7F628067;

    address[] private _team = [
        0xe2fe6d312138417Cdab7184D70D03B74f2Ce698C,
        0xBf4fA1d9b2bAdBeA3373c637168191F07b317c17,
        0x0b742B76A4C702262EcDd7DB75965c1754e8623a,
        0x3433699934cd2485fa4fd78B04767F7e0075cb82,
        0x99f794629E347ac97cb78457e1096dCfBB3b6498,
        0xBAd8a212Ea950481871393147eA54c85be325e59,
        0x002403988080d56798d2D30C4Ab498Da16bB38e2,
        0xC89E9ecF1B2900656ECba77E1Da89600f187A50D,
        0xa5bbE2Cd62e275d4Ecaa9a752783823308ACc4d0,
        0x23C625789c391463997267BDD8b21e5E266014F6,
        0x860Fd5caEb3306A1bcC2bca7d05F97439Df28574
    ];

    uint256[] private _teamShares = [2, 10, 10, 10, 10, 10, 2, 2, 2, 2, 40];

    mapping(uint256 => saleParams) public sales;
    mapping(string => mapping(address => uint256)) public mintsPerWallet;
    mapping(string => uint256) public mintsPerSale;
    string public baseURI;

    bool public isPaused;

    string private name_;
    string private symbol_;

    event TokensMinted(address mintedBy, uint256 _nb, uint256 tokenId, string saleName);

    constructor(string memory _name, string memory _symbol) ERC1155("") PaymentSplitter(_team, _teamShares) {
        name_ = _name;
        symbol_ = _symbol;
    }

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }

    // ADMIN
    function _setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setSignerAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "HF: You look into the deep space only to find nothing but emptiness.");
        signerAddress = _newAddress;
    }

    function withdrawAll() external onlyOwner {
        for (uint256 i = 0; i < _team.length; i++) {
            address payable wallet = payable(_team[i]);
            release(wallet);
        }
    }

    function pause(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    function configureSale(
        string memory _name,
        bool _requireSignature,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _price,
        uint256 _claimable,
        uint256 _supply,
        uint256 _tokenId,
        uint256 _id
    ) external onlyOwner {
        require(_startTime > 0 && _endTime > 0 && _endTime > _startTime, "HF: Time range is invalid.");
        sales[_id] = saleParams(_name, _requireSignature, _startTime, _endTime, _price, _claimable, _supply, _tokenId);
    }

    // MINT
    function airdrop(
        address _to,
        uint256 _nb,
        uint256 _tokenId
    ) external onlyOwner {
        require(totalSupply(_tokenId) + _nb <= maxSupplyOf(_tokenId), "HF: Not enough tokens left.");
        _mint(_to, _tokenId, _nb, "");
    }

    function saleMint(
        uint256 _nb,
        uint256 _alloc,
        bytes calldata _signature,
        uint256 _saleId
    ) external payable nonReentrant {
        saleParams memory _sale = sales[_saleId];
        require(_sale.startTime > 0 && _sale.endTime > 0, "HF: Sale doesn't exists");

        // If a signature is required, the allocation is fetched from it
        // This allows a dynamic allocation per wallet
        uint256 alloc = _sale.requireSignature ? _alloc : _sale.claimable;

        if (_sale.requireSignature) {
            bytes32 _messageHash = hashMessage(abi.encode(_sale.name, address(this), _msgSender(), _alloc));
            require(verifyAddressSigner(_messageHash, _signature), "HF: Invalid signature.");
        }
        require(_nb > 0, "HF: Wrong amount requested");
        require(block.timestamp > _sale.startTime && block.timestamp < _sale.endTime, "HF: Sale is not active.");
        require(totalSupply(_sale.tokenId) + _nb <= maxSupplyOf(_sale.tokenId), "HF: Not enough tokens left.");
        require(mintsPerSale[_sale.name] + _nb <= _sale.supply, "HF: Not enough supply.");

        require(msg.value >= _nb * _sale.price, "HF: Insufficient amount.");
        require(mintsPerWallet[_sale.name][_msgSender()] + _nb <= alloc, "HF: Allocation exceeded.");

        mintsPerWallet[_sale.name][_msgSender()] += _nb;
        mintsPerSale[_sale.name] += _nb;
        _mint(_msgSender(), _sale.tokenId, _nb, "");
        emit TokensMinted(_msgSender(), _nb, _sale.tokenId, _sale.name);
    }

    // PUBLIC
    function maxSupplyOf(uint256 _tokenId) public pure returns (uint256) {
        if (_tokenId == 0) return 333;
        else if (_tokenId == 1) return 3333;
        else return 0;
    }

    function uri(uint256 typeId) public view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, typeId.toString())) : baseURI;
    }

    // PRIVATE
    function verifyAddressSigner(bytes32 _messageHash, bytes memory _signature) private view returns (bool) {
        return signerAddress == _messageHash.toEthSignedMessageHash().recover(_signature);
    }

    function hashMessage(bytes memory _msg) private pure returns (bytes32) {
        return keccak256(_msg);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!isPaused, "ERC1155Pausable: token transfer while paused");
    }
}
