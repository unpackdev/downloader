// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./StringsUpgradeable.sol";

import "./structs.sol";
import "./IQNFT.sol";
import "./IQNFTGov.sol";
import "./IQNFTSettings.sol";
import "./IQSettings.sol";
import "./IQAirdrop.sol";

/**
 * @author fantasy
 */
contract QNFT is
    IQNFT,
    ContextUpgradeable,
    ERC721EnumerableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using StringsUpgradeable for uint256;

    // events
    event AddFreeAllocation(address indexed user, uint256 amount);
    event RemoveFreeAllocation(address indexed user, uint256 amount);
    event DepositQstk(uint256 amount);
    event WithdrawQstk(uint256 amount);
    event SetMaxSupply(uint256 maxSupply);
    event MintNFT(
        address indexed user,
        uint256 indexed nftId,
        uint32 characterId,
        uint32 favCoinId,
        uint32 metaId,
        uint32 lockDuration,
        uint256 mintAmount
    );
    event UpgradeNftCoin(
        address indexed user,
        uint256 indexed nftId,
        uint32 newFavCoinId
    );
    event UnlockQstkFromNft(
        address indexed user,
        uint256 indexed nftId,
        uint256 amount
    );

    // qstk
    uint256 public override totalAssignedQstk; // total qstk balance assigned to nfts
    mapping(address => uint256) public override qstkBalances; // locked qstk balances per user

    // nft
    uint256 public maxSupply; // maximum supply of NFTs
    string private _baseTokenURI;
    mapping(uint256 => NFTData) private _nftData;
    mapping(uint256 => uint256) public nftCountByCharacter; // mapping from character id to number of minted nft for the given character
    mapping(uint256 => bool) private _withdrawn;
    mapping(uint32 => bool) public metaIdInUse; // mapping from metaId to a flag - if the given metaId is in use.

    // contract addresses
    IQSettings public settings;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyManager() {
        require(
            settings.getManager() == msg.sender,
            "QNFT: caller is not the manager"
        );
        _;
    }

    /**
     * @dev Throws if it's not mint duration
     */
    modifier canMint() {
        IQNFTSettings nftSettings = IQNFTSettings(settings.getQNftSettings());

        require(nftSettings.mintStarted(), "QNFT: mint not started");
        require(!nftSettings.mintPaused(), "QNFT: mint paused");
        require(!nftSettings.mintFinished(), "QNFT: mint finished");

        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function initialize(
        address _settings,
        string memory _quiverBaseUrl,
        uint256 _maxSupply
    ) external initializer {
        __Context_init();
        __ERC721_init("Quiver NFT", "QNFT");
        __ReentrancyGuard_init();

        settings = IQSettings(_settings);
        _baseTokenURI = _quiverBaseUrl;

        maxSupply = _maxSupply;
    }

    // qstk

    /**
     * @dev returns the total qstk balance locked on the contract
     */
    function totalQstkBalance() public view returns (uint256) {
        return IERC20Upgradeable(settings.getQStk()).balanceOf(address(this));
    }

    /**
     * @dev returns remaining qstk balance of the contract
     */
    function remainingQstk() public view returns (uint256) {
        return totalQstkBalance() - totalAssignedQstk;
    }

    /**
     * @dev updates baseURL
     */
    function updateBaseUrl(string memory _quiverBaseUrl) external onlyManager {
        _baseTokenURI = _quiverBaseUrl;
    }

    /**
     * @dev deposits qstk tokens to the contract
     */
    function depositQstk(uint256 _amount) external onlyManager {
        IERC20Upgradeable(settings.getQStk()).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        emit DepositQstk(_amount);
    }

    /**
     * @dev withdraws qstk token from the contract - only remaining balance available
     */
    function withdrawQstk(uint256 _amount) external onlyManager {
        require(remainingQstk() >= _amount, "QNFT: not enough balance");
        IERC20Upgradeable(settings.getQStk()).safeTransfer(msg.sender, _amount);

        emit WithdrawQstk(_amount);
    }

    // NFT

    /**
     * @dev sets the maximum mintable count
     */
    function setMaxSupply(uint256 _maxSupply) external onlyManager {
        require(totalSupply() <= _maxSupply, "QNFT: invalid max supply");

        maxSupply = _maxSupply;
        emit SetMaxSupply(maxSupply);
    }

    function nftData(uint256 _tokenId)
        external
        view
        returns (
            uint32 characterId,
            uint32 favCoinId,
            uint32 metaId,
            uint32 unlockTime,
            uint256 lockAmount,
            bool withdrawn
        )
    {
        require(_exists(_tokenId), "QNFT: invalid token Id");

        characterId = _nftData[_tokenId].characterId;
        favCoinId = _nftData[_tokenId].favCoinId;
        metaId = _nftData[_tokenId].metaId;
        unlockTime = _nftData[_tokenId].unlockTime;
        lockAmount = _nftData[_tokenId].lockAmount;
        withdrawn = _withdrawn[_tokenId];
    }

    /**
     * @dev mint nft with given mint options
     */
    function mintNft(
        uint32 _characterId,
        uint32 _favCoinId,
        uint32 _lockOptionId,
        uint32 _metaId,
        uint256 _lockAmount
    ) external payable {
        require(
            !IQNFTSettings(settings.getQNftSettings()).onlyAirdropUsers(),
            "QNFT: not available"
        );

        _mintNft(
            _characterId,
            _favCoinId,
            _lockOptionId,
            _metaId,
            _lockAmount,
            0
        );
    }

    function mintNftForAirdropUser(
        uint32 _characterId,
        uint32 _favCoinId,
        uint32 _lockOptionId,
        uint32 _metaId,
        uint256 _lockAmount,
        uint256 _airdropAmount,
        bytes memory _signature
    ) external payable {
        _airdropAmount = IQAirdrop(settings.getQAirdrop()).withdrawLockedQStk(
            msg.sender,
            _airdropAmount,
            _signature
        );

        _mintNft(
            _characterId,
            _favCoinId,
            _lockOptionId,
            _metaId,
            _lockAmount,
            _airdropAmount
        );
    }

    function bulkMintNfts(
        uint32 _characterId,
        uint32 _favCoinId,
        uint32 _lockOptionId,
        uint32[] memory _metaIds,
        uint256 _lockAmount
    ) external onlyManager {
        _bulkMintNfts(
            _characterId,
            _favCoinId,
            _lockOptionId,
            _metaIds,
            _lockAmount
        );
    }

    /**
     * @dev updates favorite coin of a given nft
     */
    function upgradeNftCoin(uint256 _nftId, uint32 _favCoinId)
        external
        payable
    {
        require(ownerOf(_nftId) == msg.sender, "QNFT: invalid owner");

        IQNFTSettings nftSettings = IQNFTSettings(settings.getQNftSettings());
        require(
            nftSettings.favCoinsCount() >= _favCoinId,
            "QNFT: invalid favCoin id"
        );

        NFTData storage data = _nftData[_nftId];

        uint256 mintPrice =
            (nftSettings.favCoinPrices(_favCoinId) *
                nftSettings.upgradePriceMultiplier()) / 100;
        require(
            msg.value >= mintPrice,
            "QNFT: insufficient coin upgrade price"
        );

        // transfer remaining to user
        (bool sent, ) =
            payable(msg.sender).call{value: msg.value - mintPrice}("");
        require(sent, "QNFT: failed to transfer remaining eth");

        data.favCoinId = _favCoinId;

        // transfer to foundation wallet
        _transferToFoundation(mintPrice);

        emit UpgradeNftCoin(msg.sender, _nftId, _favCoinId);
    }

    /**
     * @dev unlocks/withdraws qstk from contract
     */
    function unlockQstkFromNft(uint256 _nftId) external nonReentrant {
        require(ownerOf(_nftId) == msg.sender, "QNFT: invalid owner");

        NFTData storage item = _nftData[_nftId];

        require(_withdrawn[_nftId] == false, "QNFT: already withdrawn");
        require(item.unlockTime <= block.timestamp, "QNFT: not able to unlock");

        uint256 unlockAmount = item.lockAmount;
        IERC20Upgradeable(settings.getQStk()).safeTransfer(
            msg.sender,
            unlockAmount
        );

        _updateQStkBalance(msg.sender, unlockAmount, 0);

        _withdrawn[_nftId] = true;

        emit UnlockQstkFromNft(msg.sender, _nftId, unlockAmount);
    }

    /**
     * @dev sets QSettings contract address
     */
    function setSettings(IQSettings _settings) external onlyManager {
        settings = _settings;
    }

    /**
     * @dev transfers given amount of ETH to governance
     */
    function withdrawETH(address payable _multisig)
        external
        override
        nonReentrant
    {
        require(
            settings.getQNftGov() == msg.sender,
            "QNFT: caller is the QNFTGov"
        );
        // transfer to multisig
        (bool sent, ) = _multisig.call{value: address(this).balance}("");
        require(sent, "QNFT: transfer failed");
    }

    // internal functions

    function _mintNft(
        uint32 _characterId,
        uint32 _favCoinId,
        uint32 _lockOptionId,
        uint32 _metaId,
        uint256 _lockAmount,
        uint256 _freeAllocation
    ) internal canMint nonReentrant {
        require(
            totalSupply() < maxSupply,
            "QNFT: nft count reached the total supply"
        );

        IQNFTSettings nftSettings = IQNFTSettings(settings.getQNftSettings());
        (uint256 totalPrice, , uint256 nonTokenPrice) =
            nftSettings.calcMintPrice(
                _characterId,
                _favCoinId,
                _lockOptionId,
                _lockAmount,
                _freeAllocation
            );
        require(msg.value >= totalPrice, "QNFT: insufficient mint price");

        require(!metaIdInUse[_metaId], "QNFT: metaId is already in use");

        require(
            nftCountByCharacter[_characterId] <
                nftSettings.characterMaxSupply(_characterId),
            "QNFT: character count reached at max supply"
        );

        uint256 qstkAmount = _lockAmount + _freeAllocation;

        require(
            totalAssignedQstk + qstkAmount <= totalQstkBalance(),
            "QNFT: insufficient qstk balance"
        );

        // transfer remaining to user
        (bool sent, ) =
            payable(msg.sender).call{value: msg.value - totalPrice}("");
        require(sent, "QNFT: failed to transfer remaining eth");

        uint32 lockDuration = nftSettings.lockOptionLockDuration(_lockOptionId);

        _mint(_characterId, _favCoinId, _metaId, lockDuration, qstkAmount);

        nftCountByCharacter[_characterId]++;
        metaIdInUse[_metaId] = true;

        _updateQStkBalance(msg.sender, 0, qstkAmount);

        // transfer to foundation wallet
        _transferToFoundation(nonTokenPrice);
    }

    function _bulkMintNfts(
        uint32 _characterId,
        uint32 _favCoinId,
        uint32 _lockOptionId,
        uint32[] memory _metaIds,
        uint256 _lockAmount
    ) internal canMint nonReentrant {
        require(
            totalSupply() + _metaIds.length <= maxSupply,
            "QNFT: nft count reached the total supply"
        );

        uint256 totalQstkAmount = _lockAmount * _metaIds.length;

        require(
            totalAssignedQstk + totalQstkAmount <= totalQstkBalance(),
            "QNFT: insufficient qstk balance"
        );

        IQNFTSettings nftSettings = IQNFTSettings(settings.getQNftSettings());
        uint32 lockDuration = nftSettings.lockOptionLockDuration(_lockOptionId);

        require(
            nftCountByCharacter[_characterId] + _metaIds.length <=
                nftSettings.characterMaxSupply(_characterId),
            "QNFT: character count reached at max supply"
        );

        for (uint256 j = 0; j < _metaIds.length; j++) {
            uint32 metaId = _metaIds[j];
            require(!metaIdInUse[metaId], "QNFT: metaId is already in use");

            _mint(_characterId, _favCoinId, metaId, lockDuration, _lockAmount);
        }

        nftCountByCharacter[_characterId] += _metaIds.length;

        _updateQStkBalance(msg.sender, 0, totalQstkAmount);
    }

    function _mint(
        uint32 _characterId,
        uint32 _favCoinId,
        uint32 _metaId,
        uint32 _lockDuration,
        uint256 _lockAmount
    ) internal returns (uint256 newId) {
        newId = totalSupply() + 1;

        _nftData[newId] = NFTData(
            _characterId,
            _favCoinId,
            _metaId,
            uint32(block.timestamp + _lockDuration),
            _lockAmount
        );

        super._mint(msg.sender, newId);

        metaIdInUse[_metaId] = true;

        emit MintNFT(
            msg.sender,
            newId,
            _characterId,
            _favCoinId,
            _metaId,
            _lockDuration,
            _lockAmount
        );
    }

    /**
     * @dev transfers given amount of ETH to foundation wallet
     */
    function _transferToFoundation(uint256 _amount) internal {
        // transfer to foundation wallet
        address payable foundationWallet =
            payable(settings.getFoundationWallet());
        (bool sent, ) = foundationWallet.call{value: _amount}("");
        require(sent, "QNFT: transfer failed");
    }

    /**
     * @dev returns base URL
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev transfer nft
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override nonReentrant {
        require(
            !_withdrawn[tokenId] ||
                IQNFTSettings(settings.getQNftSettings())
                    .transferAllowedAfterRedeem(),
            "QNFT: transfer not allowed for redeemed token"
        );

        super._transfer(from, to, tokenId);

        uint256 qstkAmount = _nftData[tokenId].lockAmount;

        // Update QstkBalance
        _updateQStkBalance(from, qstkAmount, 0);
        _updateQStkBalance(to, 0, qstkAmount);
    }

    function _updateQStkBalance(
        address user,
        uint256 minusAmount,
        uint256 plusAmount
    ) internal {
        uint256 originAmount = qstkBalances[user];
        qstkBalances[user] = qstkBalances[user] + plusAmount - minusAmount;
        totalAssignedQstk = totalAssignedQstk + plusAmount - minusAmount;

        IQNFTGov(settings.getQNftGov()).updateVote(
            user,
            originAmount,
            qstkBalances[user]
        );
    }
}
