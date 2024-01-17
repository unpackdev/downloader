// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

import "./ECDSA.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC721TradableUpgradeable.sol";
import "./ACellRepository.sol";
import "./IMetaCellCreator.sol";

contract MetaCell is
    IMetaCellCreator,
    ERC721TradableUpgradeable,
    ERC2981Upgradeable,
    PausableUpgradeable,
    ACellRepository,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    Counters.Counter private tokenIdCount;
    string public baseTokenURI;
    string public contractURI;
    bytes32 public stagesID;
    uint256 public price;
    uint256 public maxClaimed;
    uint256 public mintableAmount;
    uint256 public remainingAmount;
    uint96 public feeNumerator;
    address private proxyRegistryAddress;
    mapping(bytes32 => uint256) private claimedTimes;
    bool public isCanTransfer;
    address public signer;
    mapping(bytes => uint256) public claimedTime;

    event SetNewTranche(
        address newSigner,
        bytes32 stageID,
        uint256 newPrice,
        uint256 newAmount,
        uint256 newMaxClaimed,
        uint256 timestamp
    );

    event MintForGift(
        address caller,
        address to,
        uint256 tokenId,
        uint256 timestamp
    );

    event SetBaseTokenURI(string uri, uint256 timestamp);
    event SetContractURI(string uri, uint256 timestamp);
    event SetProxyRegistry(address proxy, uint256 timestamp);

    /**
     * @dev validates signature
     */
    modifier isValidSign(bytes calldata sig, uint256 index) {
        bytes32 dataHash = keccak256(
            abi.encodePacked(msg.sender, stagesID, index)
        );
        bytes32 ethSigHash = dataHash.toEthSignedMessageHash();
        require(_verifySig(ethSigHash, sig), "This wallet is not in whitelist");
        require(
            claimedTime[sig] < maxClaimed,
            "This wallet reached claimed times to mint MetaCell"
        );
        claimedTime[sig]++;
        _;
    }

    function _verifySig(bytes32 ethSigHash, bytes calldata sig)
        internal
        view
        returns (bool)
    {
        address _signer = ethSigHash.recover(sig);
        require(_signer != address(0), "ECDSA: invalid signature");
        return _signer == signer;
    }

    function claimable(
        address account,
        bytes calldata sig,
        uint256 index
    ) external view returns (bool) {
        bytes32 dataHash = keccak256(
            abi.encodePacked(account, stagesID, index)
        );
        bytes32 ethSigHash = dataHash.toEthSignedMessageHash();
        return _verifySig(ethSigHash, sig) && claimedTime[sig] < maxClaimed;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress,
        address _timelock
    ) external initializer {
        require(_proxyRegistryAddress != address(0), "Empty address");
        proxyRegistryAddress = _proxyRegistryAddress;
        timelock = _timelock;
        __ERC721_init(_name, _symbol);
        _initializeEIP712(_name);
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();
        baseTokenURI = "";
        contractURI = "";
        maxClaimed = 1;
    }

    function getProxyRegistryAddress()
        public
        view
        virtual
        override
        returns (address)
    {
        return proxyRegistryAddress;
    }

    function setProxyRegistryAddress(address newProxyRegistryAddress)
        external
        onlyTimelock
    {
        require(newProxyRegistryAddress != address(0), "Empty address");
        proxyRegistryAddress = newProxyRegistryAddress;
        emit SetProxyRegistry(newProxyRegistryAddress, block.timestamp);
    }

    function setNewTranche(
        address newSigner,
        bytes32 stageID,
        uint256 newPrice,
        uint256 newAmount,
        uint256 newMaxClaimed
    ) external onlyTimelock {
        require(newSigner != address(0), "Empty address");
        require(newMaxClaimed > 0, "Invalid value");
        signer = newSigner;
        stagesID = stageID;
        maxClaimed = newMaxClaimed;
        price = newPrice;
        remainingAmount = mintableAmount = newAmount;
        emit SetNewTranche(
            newSigner,
            stagesID,
            newPrice,
            newAmount,
            newMaxClaimed,
            block.timestamp
        );
    }

    function _create(address _to) internal returns (uint256 _tokenId) {
        tokenIdCount.increment();
        _tokenId = tokenIdCount.current();
        _mint(_to, _tokenId);

        CellData.Cell memory _newCell = CellData.Cell(
            _tokenId,
            _to,
            CellData.Class.INIT,
            0,
            0,
            0,
            false,
            0
        );
        _addMetaCell(_newCell);
        _setTokenRoyalty(_tokenId, msg.sender, feeNumerator);
    }

    function create(address to)
        external
        override
        isOperator
        returns (uint256 tokenId)
    {
        return _create(to);
    }

    function createMultiple(address to, uint256 amount) external isOperator {
        for (uint256 i = 0; i < amount; i++) {
            _create(to);
        }
    }

    function mint(address to)
        external
        payable
        isOperator
        returns (uint256 tokenId)
    {
        require(msg.value == price, "Invalid price");
        return _create(to);
    }

    function mintForGift(
        address to,
        bytes calldata sig,
        uint256 index
    ) external payable isValidSign(sig, index) nonReentrant whenNotPaused {
        require(msg.value == price, "Invalid price");
        require(remainingAmount >= 1, "Sold out");
        remainingAmount--;
        _create(to);
        uint256 tokenId = tokenIdCount.current();
        emit MintForGift(msg.sender, to, tokenId, block.timestamp);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(isCanTransfer == true, "Can not transfer at this time");
        CellData.Cell memory cell = _getMetaCell(tokenId);
        _removeMetaCell(from, tokenId);
        super._transfer(from, to, tokenId);
        cell.user = to;
        _addMetaCell(cell);
    }

    function _customBurn(uint256 tokenId) internal {
        CellData.Cell memory cell = _getMetaCell(tokenId);
        require(cell.onSale == false, "MetaCell is on sale");
        _removeMetaCell(msg.sender, tokenId);
        super._burn(tokenId);
    }

    function burn(uint256 tokenId) external override {
        require(
            msg.sender == ownerOf(tokenId),
            "Caller is not owner of token id"
        );
        _customBurn(tokenId);
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Upgradeable, ACellRepository)
        returns (address)
    {
        return ERC721Upgradeable.ownerOf(tokenId);
    }

    function addMetaCell(CellData.Cell memory _cell)
        external
        override
        isOperator
    {
        _addMetaCell(_cell);
    }

    function removeMetaCell(uint256 _tokenId, address _owner)
        external
        override
        isOperator
    {
        _removeMetaCell(_owner, _tokenId);
    }

    function updateMetaCell(CellData.Cell memory _cell, address _owner)
        external
        override
        isOperator
    {
        _updateMetaCell(_cell, _owner);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setBaseTokenURI(string memory uri) external onlyTimelock {
        baseTokenURI = uri;
        emit SetBaseTokenURI(uri, block.timestamp);
    }

    function setContractURI(string memory uri) external onlyTimelock {
        contractURI = uri;
        emit SetContractURI(uri, block.timestamp);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    Strings.toString(_tokenId),
                    ".json"
                )
            );
    }

    function withdrawETH(address payable to) external onlyTimelock {
        uint256 balance = address(this).balance;
        to.transfer(balance);
    }

    function setFeeNumerator(uint96 value) external onlyTimelock {
        feeNumerator = value;
    }

    function setIsCanTransfer(bool value) external onlyTimelock {
        isCanTransfer = value;
    }
}
