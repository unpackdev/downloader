// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
   88b          d88   888888888888      d888888b             d8b          88b          d88          d8b          88b        888
   888b       d8888   888             d88P    Y88b          d888b         888b       d8888         d888b         8888b      888
   8888b     d88888   888            d88P      Y88         d8P Y8b        8888b     d88888        d8P Y8b        888Y8b     888
   888 Y8b d8P  888   88888888888    888                  d8P   Y8b       888 Y8b d8P  888       d8P   Y8b       888  Y8b   888
   888   Y8P    888   888            Y88b    888888      d888888888b      888   Y8P    888      d888888888b      888    Y8b 888
   888          888   888             Y88b    d8888     d8P       Y8b     888          888     d8P       Y8b     888      Y8888
   888          888   888888888888      Y88888P  88   88888       88888   888          888   88888       88888   888        Y88
  

                     8888888   8888888           8888888888b      8888888   8888888     8888888   888888888888
                        Y8b     d8P              888     Y88b       888        Y8b       d8P      888
                          Y8b d8P                888      Y88b      888         Y8b     d8P       888
                            888                  888       8888     888          Y8b   d8P        88888888888
                          d8P Y8b                888      d88P      888           Y8b d8P         888
                        d8P     Y8b              888     d88P       888            Y888P          888
                     8888888   8888888           8888888888P      8888888           Y8P           888888888888
  
  
                                          88b        888   8888888888888   888888888888888
                                          8888b      888   888                   888
                                          888Y8b     888   888                   888
                                          888  Y8b   888   888888888             888
                                          888    Y8b 888   888                   888
                                          888      Y8888   888                   888
                                          888        Y88   888                   888
*/

import "./MerkleProofUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC2981Upgradeable.sol";

// General Errors
error InvalidAddress();
error InvalidNumber();
error InvalidMerkleRoot();
error InvalidURI();
error Unauthorized();
error ValidateMintPrice();
error WithdrawFailed();
// Stage Error
error InvalidTimestamp();
error InvalidPrice();
// Supply Error
error ExceedsMaxSupply();
error InvalidMaxSupply();
// Minting Errors
error OutOfPeriod();
error MintLimitReached();
// Airdrop Errors
error PrevStageNotEnded();
error InvalidReserveError();
error InvalidAmount();
error AirdropStageExeeded();
// Withdraw Error
error NoTokenToWithdraw();

/// @title Megaman X Dive NFT
contract Megaman is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721Upgradeable,
    ERC2981Upgradeable
{
    uint256 public mintLimitPerAddress;

    uint256 public totalSupply;
    uint256 public maxSupply;
    address public proxyOperator;

    // Token URI
    string private _baseTokenURI;
    string public newBaseURI;
    uint256 public metadataUpdateReservationTS;

    // Minting
    uint256 private _nextID;
    bytes32 public ALRoot;
    mapping(address => uint256) public userMinted;
    mapping(address => uint256) public userLastALMinted;
    struct MintStage {
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 priceWei;
    }

    MintStage public ALStage;
    MintStage public publicStage;

    // Airdrop
    struct AirdropStage {
        uint256 firstId;
        uint256 lastId;
    }
    AirdropStage public airdropStage;
    uint256 public lastAirdropId;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 _maxSupply,
        string memory baseTokenURI,
        address _financialManager
    ) external initializer {
        if (_maxSupply == 0) revert InvalidNumber();
        if (bytes(baseTokenURI).length == 0) revert InvalidURI();
        __Ownable_init();
        __ERC721_init('MEGA MAN X DiVE NFT', 'MMXD');
        __ReentrancyGuard_init();

        maxSupply = _maxSupply;

        _baseTokenURI = baseTokenURI;
        _nextID = 1;

        mintLimitPerAddress = 5;

        _setDefaultRoyalty(_financialManager, 1000);
    }

    //===============================================================
    //                        SET FUNCTIONS
    //===============================================================

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        if (_maxSupply < totalSupply) revert InvalidMaxSupply();
        maxSupply = _maxSupply;
    }

    function setProxyOperator(address _proxyOperator) external onlyOwner {
        if (address(0) == _proxyOperator) revert InvalidAddress();
        proxyOperator = _proxyOperator;
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        if (_root.length == 0) revert InvalidMerkleRoot();
        ALRoot = _root;
    }

    function setMintLimitPerAddress(
        uint256 _mintLimitPerAddress
    ) external onlyOwner {
        if (_mintLimitPerAddress == 0) revert InvalidNumber();
        mintLimitPerAddress = _mintLimitPerAddress;
    }

    function setALStage(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _priceWei
    ) external onlyOwner {
        if (_startTimestamp >= _endTimestamp) revert InvalidTimestamp();
        if (_overlapPublic(_startTimestamp, _endTimestamp))
            revert InvalidTimestamp();
        if (_endTimestamp <= block.timestamp) revert InvalidTimestamp();
        if (_priceWei == 0) revert InvalidPrice();

        ALStage.startTimestamp = _startTimestamp;
        ALStage.endTimestamp = _endTimestamp;
        ALStage.priceWei = _priceWei;
    }

    function setPublicStage(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _priceWei
    ) external onlyOwner {
        if (_startTimestamp >= _endTimestamp) revert InvalidTimestamp();
        if (_overlapAL(_startTimestamp, _endTimestamp))
            revert InvalidTimestamp();
        if (_endTimestamp <= block.timestamp) revert InvalidTimestamp();
        if (_priceWei == 0) revert InvalidPrice();

        publicStage.startTimestamp = _startTimestamp;
        publicStage.endTimestamp = _endTimestamp;
        publicStage.priceWei = _priceWei;
    }

    function reserveMetadataUpdate(
        string memory _newBaseURI,
        uint256 _timestamp
    ) external onlyOwner {
        if (bytes(_newBaseURI).length == 0) revert InvalidURI();
        if (_timestamp < block.timestamp) revert InvalidTimestamp();
        if (
            metadataUpdateReservationTS != 0 &&
            block.timestamp >= metadataUpdateReservationTS
        ) _baseTokenURI = newBaseURI;
        newBaseURI = _newBaseURI;
        metadataUpdateReservationTS = _timestamp;
    }

    // =============================================================
    //                        VIEW FUNCTIONS
    // =============================================================

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC2981Upgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function verifyAL(
        bytes32[] calldata _proof,
        address _account
    ) public view returns (uint256) {
        if (!_verify(_proof, _account) || _hasReachedMintLimit(_account)) {
            return 0;
        }

        return mintLimitPerAddress - userMinted[_account];
    }

    //===============================================================
    //                        MINT FUNCTIONS
    //===============================================================

    /// @dev Mints tokens for the presale.
    function ALMint(
        bytes32[] calldata _merkleProof,
        uint256 _quantity
    ) external payable nonReentrant {
        if (userLastALMinted[msg.sender] < ALStage.startTimestamp)
            delete userMinted[msg.sender];

        if (!_ALOnGoing(block.timestamp)) revert OutOfPeriod();
        if (msg.value != ALStage.priceWei * _quantity)
            revert ValidateMintPrice();
        if (verifyAL(_merkleProof, msg.sender) < _quantity)
            revert MintLimitReached();
        if (totalSupply + _quantity > maxSupply) revert ExceedsMaxSupply();

        _bulkMint(msg.sender, _quantity);

        totalSupply += _quantity;
        userMinted[msg.sender] += _quantity;
        userLastALMinted[msg.sender] = block.timestamp;
    }

    function proxyALMint(
        bytes32[] calldata _merkleProof,
        uint256 _quantity,
        address _to
    ) external payable nonReentrant {
        if (userLastALMinted[_to] < ALStage.startTimestamp)
            delete userMinted[_to];

        if (!_ALOnGoing(block.timestamp)) revert OutOfPeriod();
        if (msg.value != ALStage.priceWei * _quantity)
            revert ValidateMintPrice();
        if (verifyAL(_merkleProof, _to) < _quantity) revert MintLimitReached();
        if (totalSupply + _quantity > maxSupply) revert ExceedsMaxSupply();
        if (msg.sender != proxyOperator) revert Unauthorized();

        _bulkMint(_to, _quantity);

        totalSupply += _quantity;
        userMinted[_to] += _quantity;
        userLastALMinted[_to] = block.timestamp;
    }

    /// @dev Mints tokens for the public sale.
    function publicMint(uint256 _quantity) external payable nonReentrant {
        if (!_publicOnGoing(block.timestamp)) revert OutOfPeriod();
        if (msg.value != publicStage.priceWei * _quantity)
            revert ValidateMintPrice();
        if (totalSupply + _quantity > maxSupply) revert ExceedsMaxSupply();

        _bulkMint(msg.sender, _quantity);

        totalSupply += _quantity;
    }

    function proxyPublicMint(
        uint256 _quantity,
        address _to
    ) external payable nonReentrant {
        if (msg.sender != proxyOperator) revert Unauthorized();
        if (!_publicOnGoing(block.timestamp)) revert OutOfPeriod();
        if (msg.value != publicStage.priceWei * _quantity)
            revert ValidateMintPrice();
        if (totalSupply + _quantity > maxSupply) revert ExceedsMaxSupply();

        _bulkMint(_to, _quantity);

        totalSupply += _quantity;
    }

    // =============================================================
    //                       AIRDROP FUNCTIONS
    // =============================================================

    function reserveAirdropTokens(
        uint256 _start,
        uint256 _end
    ) external onlyOwner {
        if (lastAirdropId < airdropStage.lastId) revert PrevStageNotEnded();
        if (_start > _end) revert InvalidReserveError();
        if (_start < _nextID) revert InvalidReserveError();
        if (_end > maxSupply) revert InvalidReserveError();

        if (_start == _nextID) _nextID = _end + 1;
        airdropStage.firstId = _start;
        airdropStage.lastId = _end;
    }

    /// @dev Mints tokens for airdrops
    function airdrop(
        address _to,
        uint256 _quantity
    ) external onlyOwner nonReentrant {
        /// @dev Openseaにリストするために、tokenId=0を一時的に発行する
        /// @dev mintが進んでくると0を発行できない
        if (totalSupply == 0 && airdropStage.lastId == 0)
            return _safeMint(msg.sender, 0);
        uint256 startAirdropId = lastAirdropId + 1;
        if (startAirdropId < airdropStage.firstId)
            startAirdropId = airdropStage.firstId;
        if (startAirdropId - 1 + _quantity > airdropStage.lastId)
            revert AirdropStageExeeded();
        if (_quantity == 0) revert InvalidAmount();

        for (uint8 i = 0; i < _quantity; i++) {
            uint256 tokenId = startAirdropId + i;
            _safeMint(_to, tokenId);
        }

        lastAirdropId = startAirdropId - 1 + _quantity;
        totalSupply += _quantity;
    }

    //===============================================================
    //                        WITHDRAW FUNCTIONS
    //===============================================================

    /// @dev Allows the owner to withdraw the balance of the contract.
    function withdraw() external nonReentrant {
        uint256 currentBalance = address(this).balance;
        (address _financialManager, ) = royaltyInfo(1, 100);

        if (msg.sender != _financialManager) revert Unauthorized();
        if (currentBalance == 0) revert NoTokenToWithdraw();

        (bool success, ) = payable(_financialManager).call{
            value: currentBalance
        }('');
        if (!success) revert WithdrawFailed();
    }

    /// @dev owner can burn his own NFT
    function burn(uint256 _id) external onlyOwner {
        if (msg.sender != ownerOf(_id)) revert Unauthorized();
        _burn(_id);
    }

    //===============================================================
    //                        INTERNAL FUNCTIONS
    //===============================================================

    function _baseURI() internal view override returns (string memory) {
        if (
            metadataUpdateReservationTS >= block.timestamp ||
            metadataUpdateReservationTS == 0
        ) {
            return _baseTokenURI;
        } else {
            return newBaseURI;
        }
    }

    function _verify(
        bytes32[] calldata _proof,
        address _account
    ) private view returns (bool) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_account))));
        // bytes32 leaf = keccak256(abi.encodePacked(_account));
        return MerkleProofUpgradeable.verifyCalldata(_proof, ALRoot, leaf);
    }

    function _hasReachedMintLimit(
        address _account
    ) private view returns (bool) {
        uint256 _alMintedCount = userMinted[_account];
        if (userLastALMinted[_account] < ALStage.startTimestamp)
            _alMintedCount = 0;
        return _alMintedCount >= mintLimitPerAddress;
    }

    function _ALOnGoing(uint256 _timestamp) private view returns (bool) {
        bool tooEarly = _timestamp < ALStage.startTimestamp;
        bool tooLate = _timestamp > ALStage.endTimestamp;

        return !tooEarly && !tooLate;
    }

    function _publicOnGoing(uint256 _timestamp) private view returns (bool) {
        bool tooEarly = _timestamp < publicStage.startTimestamp;
        bool tooLate = _timestamp > publicStage.endTimestamp;

        return !tooEarly && !tooLate;
    }

    function _overlapAL(
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) private view returns (bool) {
        if (
            _startTimestamp < ALStage.startTimestamp &&
            _endTimestamp > ALStage.endTimestamp
        ) return true;
        if (_ALOnGoing(_startTimestamp) || _ALOnGoing(_endTimestamp))
            return true;

        return false;
    }

    function _overlapPublic(
        uint256 _startTimestamp,
        uint256 _endTimestamp
    ) private view returns (bool) {
        if (
            _startTimestamp < publicStage.startTimestamp &&
            _endTimestamp > publicStage.endTimestamp
        ) return true;
        if (_publicOnGoing(_startTimestamp) || _publicOnGoing(_endTimestamp))
            return true;

        return false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _bulkMint(address _to, uint256 _quantity) internal {
        uint256 lastID;
        bool skipReservedIds;
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = _nextID + i;
            if (
                tokenId >= airdropStage.firstId &&
                tokenId <= airdropStage.lastId
            ) skipReservedIds = true;
            if (skipReservedIds)
                tokenId += airdropStage.lastId - airdropStage.firstId + 1;
            if (tokenId > maxSupply) revert ExceedsMaxSupply();
            _safeMint(_to, tokenId);
            lastID = tokenId;
        }
        _nextID = lastID + 1;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
