// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155.sol";

contract ERC1155Contract is ERC1155, ReentrancyGuard, Ownable {

    struct InitialParameters {
        uint256 id;
        uint256 launchpassId;
        string name;
        string symbol;
        string uri;
        uint24 maxSupply;
        uint24 maxPerWallet;
        uint24 maxPerTransaction;
        uint72 preSalePrice;
        uint72 pubSalePrice;
        address payable multisigAddress;
    }

    struct TokenParameters {
        bytes32 merkleRoot;
        string uri;
        uint24 maxSupply;
        uint24 maxPerWallet;
        uint24 maxPerTransaction;
        uint72 preSalePrice;
        uint72 pubSalePrice;
        bool preSaleIsActive;
        bool saleIsActive;
        bool supplyLock;
        address creator;
        uint256 totalSupply;
    }

    mapping(uint256 => TokenParameters) public tokenParameters;
    mapping (uint256 => mapping(address => uint256)) public hasMinted;
    address payable public multisigAddress;
    address payable public wentMintAddress;
    uint8 public wenmintShare;
    uint256 public launchpassId;
    string public name;
    string public symbol;

    modifier onlyMultisig() {
        require(msg.sender == multisigAddress, "Only multisig wallet can perfrom this action");
        _;
    }

    constructor(
        address payable _wentMintAddress,
        uint8 _wenmintShare,
        address _owner,
        InitialParameters memory initialParameters
      ) ERC1155() {
        name = initialParameters.name;
        symbol = initialParameters.symbol;
        uint256 _id = initialParameters.id;
        launchpassId = initialParameters.launchpassId;
        tokenParameters[_id].creator = msg.sender;
        tokenParameters[_id].uri = initialParameters.uri;
        tokenParameters[_id].maxSupply = initialParameters.maxSupply;
        tokenParameters[_id].maxPerWallet = initialParameters.maxPerWallet;
        tokenParameters[_id].maxPerTransaction = initialParameters.maxPerTransaction;
        tokenParameters[_id].preSalePrice = initialParameters.preSalePrice;
        tokenParameters[_id].pubSalePrice = initialParameters.pubSalePrice;
        tokenParameters[_id].preSaleIsActive = false;
        tokenParameters[_id].saleIsActive = false;
        tokenParameters[_id].supplyLock = false;
        tokenParameters[_id].totalSupply = 0;
        multisigAddress = initialParameters.multisigAddress;
        wenmintShare = _wenmintShare;
        wentMintAddress = _wentMintAddress;
        transferOwnership(_owner);
    }

    function uri(
        uint256 _id
    ) override public view returns (string memory) {
        require(tokenParameters[_id].creator != address(0), "Token does not exists");
        return tokenParameters[_id].uri;
    }

    function totalSupply(
        uint256 _id
    ) public view returns (uint256) {
        return tokenParameters[_id].totalSupply;
    }

    function maxSupply(
        uint256 _id
    ) public view returns (uint24) {
        return tokenParameters[_id].maxSupply;
    }

    function preSalePrice(
        uint256 _id
    ) public view returns (uint72) {
        return tokenParameters[_id].preSalePrice;
    }

    function pubSalePrice(
        uint256 _id
    ) public view returns (uint72) {
        return tokenParameters[_id].pubSalePrice;
    }

    function maxPerWallet(
        uint256 _id
    ) public view returns (uint24) {
        return tokenParameters[_id].maxPerWallet;
    }

    function maxPerTransaction(
        uint256 _id
    ) public view returns (uint24) {
        return tokenParameters[_id].maxPerTransaction;
    }

    function preSaleIsActive(
        uint256 _id
    ) public view returns (bool) {
        return tokenParameters[_id].preSaleIsActive;
    }

    function supplyLock(
        uint256 _id
    ) public view returns (bool) {
        return tokenParameters[_id].supplyLock;
    }

    function saleIsActive(
        uint256 _id
    ) public view returns (bool) {
        return tokenParameters[_id].saleIsActive;
    }

    function setMaxSupply(uint256 _id, uint24 _supply) public onlyOwner {
        require(!tokenParameters[_id].supplyLock, "Supply is locked.");
       tokenParameters[_id].maxSupply = _supply;
    }

    function lockSupply(uint256 _id) public onlyOwner {
        tokenParameters[_id].supplyLock = true;
    }

    function setURI(uint256 _id, string memory _uri) public onlyOwner {
        tokenParameters[_id].uri = _uri;
    }

    function setPreSalePrice(uint256 _id, uint72 _price) public onlyOwner {
        tokenParameters[_id].preSalePrice = _price;
    }

    function setPublicSalePrice(uint256 _id, uint72 _price) public onlyOwner {
        tokenParameters[_id].pubSalePrice = _price;
    }

    function setMaxPerWallet(uint256 _id, uint24 _quantity) public onlyOwner {
        tokenParameters[_id].maxPerWallet = _quantity;
    }

    function setMaxPerTransaction(uint256 _id, uint24 _quantity) public onlyOwner {
        tokenParameters[_id].maxPerTransaction = _quantity;
    }

    function setRoot(uint256 _id, bytes32 _root) public onlyOwner {
        tokenParameters[_id].merkleRoot = _root;
    }

    function setPubSaleState(uint256 _id, bool _isActive) public onlyOwner {
        tokenParameters[_id].saleIsActive = _isActive;
    }

    function setPreSaleState(uint256 _id, bool _isActive) public onlyOwner {
        require(tokenParameters[_id].merkleRoot != "", "Merkle root is undefined.");
        tokenParameters[_id].preSaleIsActive = _isActive;
    }

    function verify(uint256 _id, bytes32 leaf, bytes32[] memory proof) public view returns (bool) {
        bytes32 computedHash = leaf;
        for (uint i = 0; i < proof.length; i++) {
          bytes32 proofElement = proof[i];
          if (computedHash <= proofElement) {
            computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
          } else {
            computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
          }
        }
        return computedHash == tokenParameters[_id].merkleRoot;
    }

    function create(
        uint256 _id,
        TokenParameters memory initialParameters
    ) public onlyOwner {
        require(tokenParameters[_id].creator == address(0), "token _id already exists");
        tokenParameters[_id] = initialParameters;
    }

    function mint(
        uint256 _id,
        bytes memory _data,
        uint256 _quantity,
        bytes32[] memory proof
    ) public payable {
        uint _maxSupply = tokenParameters[_id].maxSupply;
        uint _maxPerWallet = tokenParameters[_id].maxPerWallet;
        uint _maxPerTransaction = tokenParameters[_id].maxPerTransaction;
        uint _preSalePrice = tokenParameters[_id].preSalePrice;
        uint _pubSalePrice = tokenParameters[_id].pubSalePrice;
        bool _saleIsActive = tokenParameters[_id].saleIsActive;
        bool _preSaleIsActive = tokenParameters[_id].preSaleIsActive;
        uint256 _currentSupply = tokenParameters[_id].totalSupply;

        require(_saleIsActive, "Sale is not active.");
        require(_currentSupply <= _maxSupply, "Sold out.");
        require(_currentSupply + _quantity <= _maxSupply, "Requested quantity would exceed total supply.");
        if(_preSaleIsActive) {
            require(_preSalePrice * _quantity <= msg.value, "ETH sent is incorrect.");
            require(_quantity <= _maxPerWallet, "Exceeds wallet presale limit.");
            uint mintedAmount = hasMinted[_id][msg.sender] + _quantity;
            require(mintedAmount <= _maxPerWallet, "Exceeds per wallet presale limit.");
            hasMinted[_id][msg.sender] = mintedAmount;
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(verify(_id, leaf, proof), "You are not whitelisted.");
        } else {
            require(_pubSalePrice * _quantity <= msg.value, "ETH sent is incorrect.");
            require(_quantity <= _maxPerTransaction, "Exceeds per transaction limit for public sale.");
        }
        _mint(msg.sender, _id, _quantity, _data);
        tokenParameters[_id].totalSupply = _currentSupply + _quantity;
    }

    function airdrop(address[] memory _addrs, uint256[] memory _quantities, uint256 _id) public onlyMultisig {
        for (uint256 i = 0; i < _addrs.length; i++) {
            _mint(_addrs[i], _id, _quantities[i], "");
            tokenParameters[_id].totalSupply = tokenParameters[_id].totalSupply + _quantities[i];
        }
    }

    function setMultiSig(address payable _address) public onlyMultisig {
        multisigAddress = _address;
    }

    function reserve(uint256 _id, bytes memory _data, address _address, uint256 _quantity) public onlyMultisig {
        _mint(_address, _id, _quantity, _data);
        tokenParameters[_id].totalSupply = tokenParameters[_id].totalSupply + _quantity;
    }

    function withdraw() external nonReentrant onlyMultisig {
        uint balance = address(this).balance;
        uint wenMintAmount = balance * wenmintShare / 100;
        (bool sentWenMint, ) = wentMintAddress.call{ value: wenMintAmount }("");
        require(sentWenMint, "Failed to send ETH to WenMint.");
        uint multiSigAmount = balance - wenMintAmount;
        (bool sentMultiSig, ) = multisigAddress.call{ value: multiSigAmount }("");
        require(sentMultiSig, "Failed to send ETH to Gnosis Safe.");
    }
}
