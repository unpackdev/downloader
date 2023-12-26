// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Strings.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "./DefaultOperatorFilterer.sol";

import "./PumpStaker.sol";

contract PumpNft is Ownable, ERC2981, ERC721A, ERC721AQueryable, ERC721ABurnable, DefaultOperatorFilterer, Pausable {
    using Strings for uint256;

    error InvalidMintAmount();
    error InvalidMintType();
    error InvalidMerkle();
    error SaleNotActive();
    error NotAllowed();
    error InvalidTokenId();
    error MaxMintExceeded();
    error MaxSupplyExceeded();
    error InsufficientFunds();
    error NotTransferable();

    enum MintType {
        MINT,
        MINT_STAKE
    }

    struct MintRecord {
        address account;
        uint96 id;
    }

    enum AccountType {
        GA,
        GB,
        FCFS,
        PUBLIC
    }

    uint256 public constant MAX_ID = 8888;
    uint256 public constant MAX_MINT = 3;
    uint256 public constant PRICE_WHITE = 0.01 ether;
    uint256 public constant PRICE_PUBLIC = 0.012 ether;

    PumpStaker public staker;
    string private _baseTokenURI;

    bytes32 public rootGa;
    bytes32 public rootGb;
    bytes32 public rootFcfs;

    uint256 public gStartsAt;
    uint256 public gEndsAt;
    uint256 public fcfsStartsAt;
    uint256 public fcfsEndsAt;
    uint256 public publicStartsAt;
    uint256 public publicEndsAt = type(uint256).max;

    MintRecord[] public totalMints;
    mapping(address => MintRecord[]) public accountMints;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory __baseTokenURI,
        address _defaultRoyalty,
        uint256 _gStartsAt,
        uint256 _gEndsAt,
        uint256 _fcfsStartsAt,
        uint256 _fcfsEndsAt,
        uint256 _publicStartsAt
    ) ERC721A(_name, _symbol) {
        _baseTokenURI = __baseTokenURI;
        _setDefaultRoyalty(_defaultRoyalty, 750);

        gStartsAt = _gStartsAt;
        gEndsAt = _gEndsAt;
        fcfsStartsAt = _fcfsStartsAt;
        fcfsEndsAt = _fcfsEndsAt;
        publicStartsAt = _publicStartsAt;
    }

    // Mint Sale Functions

    function currentStage() public view returns (uint256 stage) {
        if (block.timestamp >= gStartsAt && block.timestamp <= gEndsAt) {
            return 1;
        }

        if (block.timestamp >= fcfsStartsAt && block.timestamp <= fcfsEndsAt) {
            return 2;
        }

        if (block.timestamp >= publicStartsAt && block.timestamp <= publicEndsAt) {
            return 3;
        }

        return 0;
    }

    function priceOf(AccountType accountType, uint256 _mints) public view returns (uint256 price) {
        uint stage = currentStage();

        if (stage == 1) {
            if (accountType == AccountType.GA) {
                return (_mints - 1) * PRICE_WHITE;
            }

            if (accountType == AccountType.GB) {
                return _mints * PRICE_WHITE;
            }

            revert NotAllowed();
        }

        if (stage == 2) {
            if (accountType == AccountType.FCFS) {
                return _mints * PRICE_WHITE;
            }

            revert NotAllowed();
        }

        if (stage == 3) {
            return _mints * PRICE_PUBLIC;
        }

        revert SaleNotActive();
    }

    function gaMint(uint256 _mints, MintType _type, uint256 _period, bytes32[] calldata _proof) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_proof, rootGa, leaf)) revert InvalidMerkle();

        _mintRecord(_mints, _type, _period, AccountType.GA);
    }

    function gbMint(uint256 _mints, MintType _type, uint256 _period, bytes32[] calldata _proof) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_proof, rootGb, leaf)) revert InvalidMerkle();

        _mintRecord(_mints, _type, _period, AccountType.GB);
    }

    function fcfsMint(uint256 _mints, MintType _type, uint256 _period, bytes32[] calldata _proof) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_proof, rootFcfs, leaf)) revert InvalidMerkle();

        _mintRecord(_mints, _type, _period, AccountType.FCFS);
    }

    function publicMint(uint256 _mints, MintType _type, uint256 _period) external payable {
        _mintRecord(_mints, _type, _period, AccountType.PUBLIC);
    }

    function _mintRecord(uint256 _mints, MintType _type, uint256 _period, AccountType _accountType) private whenNotPaused {
        if (_mints == 0) revert InvalidMintAmount();

        if ((_totalMinted() + _mints) > MAX_ID) revert MaxSupplyExceeded();

        (, uint256 remaing) = remainingMintLimits(_msgSenderERC721A());
        if (remaing == 0 || _mints > remaing) revert InvalidMintAmount();

        uint256 price = priceOf(_accountType, _mints);
        if (msg.value < price) revert InsufficientFunds();

        _saveRecord(_msgSenderERC721A(), _mints, _type, _period);
    }

    function _saveRecord(address account, uint256 _mints, MintType _type, uint256 _period) private {
        for (uint i = 0; i < _mints; i++) {
            if (_type == MintType.MINT) {
                MintRecord memory record = MintRecord({account: account, id: uint96(_nextTokenId())});
                totalMints.push(record);
                accountMints[account].push(record);

                _mint(owner(), 1);
                continue;
            }

            if (_type == MintType.MINT_STAKE) {
                uint256[] memory tokenIds = new uint256[](1);
                tokenIds[0] = _nextTokenId();

                _mint(address(staker), 1);
                staker.stakeTo(account, tokenIds, _period);
                continue;
            }

            revert InvalidMintType();
        }
    }

    function remainingMintLimits(address account) public view returns (uint256 used, uint256 remaing) {
        MintRecord[] memory records = accountMints[account];
        used = records.length;
        if (used > MAX_MINT) revert InvalidMintAmount();
        remaing = MAX_MINT - used;
    }

    function transferToRecord(uint256 start, uint256 end) external onlyOwner {
        for (uint256 i = start; i <= end; i++) {
            MintRecord memory record = totalMints[i];
            if (ownerOf(record.id) == msg.sender) {
                safeTransferFrom(msg.sender, record.account, record.id);
            }
        }
    }

    function mintsOf(address account) external view returns (MintRecord[] memory mints) {
        return accountMints[account];
    }

    function getAirdropRecordsLength() external view returns (uint256) {
        return totalMints.length;
    }

    function getAllAirdropRecords() external view returns (MintRecord[] memory) {
        return getAirdropRecords(0, totalMints.length - 1);
    }

    function getAirdropRecords(uint256 start, uint256 end) public view returns (MintRecord[] memory airdrops) {
        airdrops = new MintRecord[](end - start + 1);
        for (uint256 i = 0; i < (end - start + 1); i++) {
            airdrops[i] = totalMints[start + i];
        }
    }

    // Blind Box

    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert InvalidTokenId();
        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // Sale Functions

    function withdrawAll() external onlyOwner {
        payable(_withdrawReceiver()).transfer(address(this).balance);
    }

    function _withdrawReceiver() internal view virtual returns (address) {
        return owner();
    }

    // Admin functions

    function mint(uint256 _mints, address _to) external onlyOwner {
        _mint(_to, _mints);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setStaker(address _staker) external onlyOwner {
        staker = PumpStaker(_staker);
    }

    function setRootGa(bytes32 root) external onlyOwner {
        rootGa = root;
    }

    function setRootGb(bytes32 root) external onlyOwner {
        rootGb = root;
    }

    function setRootFcfs(bytes32 root) external onlyOwner {
        rootFcfs = root;
    }

    function setGStartsAt(uint256 time) external onlyOwner {
        gStartsAt = time;
    }

    function setGEndsAt(uint256 time) external onlyOwner {
        gEndsAt = time;
    }

    function setFcfsStartsAt(uint256 time) external onlyOwner {
        fcfsStartsAt = time;
    }

    function setFcfsEndsAt(uint256 time) external onlyOwner {
        fcfsEndsAt = time;
    }

    function setPublicStartsAt(uint256 time) external onlyOwner {
        publicStartsAt = time;
    }

    function setPublicEndsAt(uint256 time) external onlyOwner {
        publicEndsAt = time;
    }

    // Extension

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    // EIP-165

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    // EIP-2981

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    // OperatorFilterer overrides (overrides, values etc.)

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
