//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

//import "./console.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./utils.sol";
import "./errors.sol";
import "./IStakingContract.sol";

contract NFTContract is ERC721, ERC721Enumerable, Ownable, Utils {
    using SafeERC20 for IERC20;

    uint8 private constant RARITY_TYPE_SUPPLY = 210;
    string public metadataURI;
    string public typeImageURI;

    address private immutable proxyRegistryAddress;
    address private immutable multiSignWithdrawAddress;
    address private immutable multiSignStakingControlAddress;
    address private immutable wethTokenAddress;
    address private immutable xbtcTokenAddress;
    address private lootboxContractAddress;
    address private questsContractAddress;
    address[] private currencyList;

    uint8 private typeCounter;
    uint16 public totalPresaleRemain;
    uint16 public totalQuestsRemain;
    uint16 public totalTeamRemain;
    uint16 public totalAdvisorRemain;
    uint16 public totalLootboxRemain;
    uint64 private vestingEnd;
    uint64 private vestingStart;

    address public stakingDefaultContract;
    address[] public stakingContracts;
    mapping(uint256 => address) public nftStakingAddress;

    mapping(uint8 => RarityType) public rarityTypes;
    mapping(uint256 => uint8) public nftRarityTypes;
    mapping(RarityNFT => mapping(address => uint256)) private presalePrices;
    mapping(DistributionType => uint8) private distributionTypeSupply;

    // Quests
    mapping(uint256 => bool) public firstHandNFTs;

    // 0 - common, 1 - majestic, 2 - epic, 3 - legendary
    mapping(address => uint16[]) public teamUserMinted;
    mapping(address => uint16[]) public teamUserNftCount;

    struct RarityType {
        uint8 id;
        string title;
        RarityNFT rarity;
        uint16 hashRate;
        uint16 totalMinted;
        uint16 firstId;
        uint8[5] remains; // 0 - presale, 1 - quests, 2 - team, 3 - advisor, 4 - lootbox
    }

    struct PresalePrices {
        RarityNFT rarity;
        address[] currencyList;
        uint256[] prices;
    }

    constructor(
        address _initialOwner, string memory _name, string memory _symbol,
        string memory _metadataURI, string memory _typeImageURI,
        address _proxyRegistryAddress, address _multiSignWithdrawAddress, address _multiSignStakingControlAddress,
        address _wethTokenAddress, address _xbtcTokenAddress
    )
    ERC721(_name, _symbol)
    Ownable(_initialOwner)
    {
        metadataURI = _metadataURI;
        typeImageURI = _typeImageURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        multiSignWithdrawAddress = _multiSignWithdrawAddress;
        multiSignStakingControlAddress = _multiSignStakingControlAddress;
        wethTokenAddress = _wethTokenAddress;
        xbtcTokenAddress = _xbtcTokenAddress;

        vestingStart = uint64(block.timestamp + 1 hours);
        vestingEnd = uint64(block.timestamp + 5 * 365 days);

        distributionTypeSupply[DistributionType.Presale] = 54;
        distributionTypeSupply[DistributionType.Quests] = 89;
        distributionTypeSupply[DistributionType.Team] = 19;
        distributionTypeSupply[DistributionType.Advisor] = 6;
        distributionTypeSupply[DistributionType.Lootbox] = 42;
    }

    // ----------- Public/External ------------

    function nftHashrate(uint256 _tokenId)
    external view
    returns (uint16)
    {
        RarityType storage rarityType = rarityTypes[nftRarityTypes[_tokenId]];
        if (rarityType.id == 0) {
            revert NFT_WrongTokenId(_tokenId);
        }
        return rarityType.hashRate;
    }

    function nftLootboxRemains(uint8 _typeId)
    external view
    returns (uint8)
    {
        RarityType storage rarityType = rarityTypes[_typeId];
        if (rarityType.id == 0) {
            revert NFT_WrongTypeId(_typeId);
        }
        return rarityType.remains[uint8(DistributionType.Lootbox)];
    }

    function getAvailableTypes(DistributionType _distribution, RarityNFT _rarityId)
    public view
    returns (uint8[] memory)
    {
        uint8 _innerCounter = 0;
        uint8[] memory _allTypes = new uint8[](typeCounter);

        for (uint8 _i = 1; _i <= typeCounter; ++_i) {
            RarityType storage rarityType = rarityTypes[_i];
            if (rarityType.rarity == _rarityId && rarityType.remains[uint8(_distribution)] > 0) {
                _allTypes[_innerCounter] = rarityType.id;
                _innerCounter += 1;
            }
        }

        // remove empty elements
        uint8[] memory _result = new uint8[](_innerCounter);
        for (uint8 _i = 0; _i < _innerCounter; ++_i) {
            _result[_i] = _allTypes[_i];
        }

        return _result;
    }

    // @title Mint NFTs on PreSale
    // @param _typeIds: array rarity type id
    // @param _amounts: array how much NFT mint
    // @param _currency: token that used for payment
    function presaleMint(uint8[] calldata _typeIds, uint8[] calldata _amounts, address _currency)
    external
    {
        if (_typeIds.length == 0 || _typeIds.length != _amounts.length) {
            revert NFT_WrongArgumentsCount();
        }
        if (_currency == address(0)) {
            revert NFT_WrongInputAddress();
        }

        for (uint8 _i = 0; _i < _typeIds.length; ++_i) {
            RarityType storage rarityType = rarityTypes[_typeIds[_i]];
            if (rarityType.id == 0) {
                revert NFT_WrongTypeId(_typeIds[_i]);
            }
            if (totalPresaleRemain < _amounts[_i]) {
                revert NFT_NoSupply("Total Presale", _typeIds[_i]);
            }
            if (rarityType.remains[uint8(DistributionType.Presale)] < _amounts[_i]) {
                revert NFT_NoSupply("Presale", _typeIds[_i]);
            }
            if (presalePrices[rarityType.rarity][_currency] == 0) {
                revert NFT_WrongCurrency();
            }

            uint256 _paymentAmount = presalePrices[rarityType.rarity][_currency] * _amounts[_i];
            SafeERC20.safeTransferFrom(IERC20(_currency), msg.sender, multiSignWithdrawAddress, _paymentAmount);

            rarityType.remains[uint8(DistributionType.Presale)] -= _amounts[_i];
            totalPresaleRemain -= _amounts[_i];
            _mintBatchAndStake(msg.sender, _typeIds[_i], _amounts[_i]);
        }
    }

    // @title Mint NFTs on PreSale using ETH
    // @param _typeIds: array rarity type id
    // @param _amounts: array how much NFT mint
    function presaleMintETH(uint8[] calldata _typeIds, uint8[] calldata _amounts)
    external payable
    {
        if (_typeIds.length == 0 || _typeIds.length != _amounts.length) {
            revert NFT_WrongArgumentsCount();
        }
        if (msg.value == 0) {
            revert NFT_WrongPaymentAmount();
        }

        bool success = payable(multiSignWithdrawAddress).send(msg.value);
        require(success, "NFT: ETH transfer failed");

        uint256 _paymentAmount = 0;
        for (uint8 _i = 0; _i < _typeIds.length; ++_i) {
            RarityType storage rarityType = rarityTypes[_typeIds[_i]];
            if (rarityType.id == 0) {
                revert NFT_WrongTypeId(_typeIds[_i]);
            }
            if (totalPresaleRemain < _amounts[_i]) {
                revert NFT_NoSupply("Total Presale", _typeIds[_i]);
            }
            if (rarityType.remains[uint8(DistributionType.Presale)] < _amounts[_i]) {
                revert NFT_NoSupply("Presale", _typeIds[_i]);
            }
            if (presalePrices[rarityType.rarity][wethTokenAddress] == 0) {
                revert NFT_WrongCurrency();
            }

            _paymentAmount += presalePrices[rarityType.rarity][wethTokenAddress] * _amounts[_i];
            rarityType.remains[uint8(DistributionType.Presale)] -= _amounts[_i];
            totalPresaleRemain -= _amounts[_i];

            _mintBatchAndStake(msg.sender, _typeIds[_i], _amounts[_i]);
        }

        if (msg.value != _paymentAmount) {
            revert NFT_WrongPaymentAmount();
        }
    }

    // @title Open Lootbox
    // @param _owner: lootbox owner
    // @param _typeId: lootbox type id
    function lootboxMintNFT(address _owner, uint8 _typeId)
    external
    {
        RarityType storage rarityType = rarityTypes[_typeId];

        if (_owner == address(0)) {
            revert NFT_WrongInputAddress();
        }
        if (totalLootboxRemain == 0) {
            revert NFT_NoSupply("Total Lootbox", _typeId);
        }
        if (msg.sender != lootboxContractAddress) {
            revert NFT_NoAccessToCall();
        }
        if (rarityType.id == 0) {
            revert NFT_WrongTypeId(_typeId);
        }
        if (rarityType.remains[uint8(DistributionType.Lootbox)] == 0) {
            revert NFT_NoSupply("Lootbox", _typeId);
        }

        totalLootboxRemain -= 1;
        rarityType.remains[uint8(DistributionType.Lootbox)] -= 1;
        _mintOneAndStake(_owner, _typeId);
    }

    // @title Team mint NFT with vesting
    function teamMint(RarityNFT _rarity)
    external
    {
        if (totalTeamRemain == 0) {
            revert NFT_NoSupply("Total Team", 0);
        }
        if (teamUserNftCount[msg.sender].length == 0) {
            revert NFT_NoVestingAmount();
        }

        uint16 _unlockedNFTs = getUnlockedNFTCount(msg.sender, uint8(_rarity));
        if (_unlockedNFTs > 100) {
            _unlockedNFTs = 100;
        }

        if (_unlockedNFTs > 0) {
            teamUserMinted[msg.sender][uint8(_rarity)] += _unlockedNFTs;
            for (uint8 _j = 0; _j < _unlockedNFTs; ++_j) {
                uint8[] memory _availableTypes = getAvailableTypes(DistributionType.Team, _rarity);
                uint8 _typeId = _availableTypes[uint8(randomNum(_availableTypes.length))];
                _mintOneAndStake(msg.sender, _typeId);
            }
        }

        totalTeamRemain -= _unlockedNFTs;
    }

    // @title Community mint NFT by complete a quests
    // @param _amount: how mutch NFT mint
    function questCompleteMint(address _owner, uint8 _typeId)
    external
    {
        RarityType storage rarityType = rarityTypes[_typeId];

        if (_owner == address(0)) {
            revert NFT_WrongInputAddress();
        }
        if (totalQuestsRemain == 0) {
            revert NFT_NoSupply("Total Quests", _typeId);
        }
        if (msg.sender != questsContractAddress) {
            revert NFT_NoAccessToCall();
        }
        if (rarityType.id == 0) {
            revert NFT_WrongTypeId(_typeId);
        }
        if (rarityType.remains[uint8(DistributionType.Quests)] == 0) {
            revert NFT_NoSupply("Quests", _typeId);
        }

        totalQuestsRemain -= 1;
        rarityType.remains[uint8(DistributionType.Quests)] -= 1;
        _mintOneAndStake(_owner, _typeId);
    }

    // @title Get unlocked NFTs count for team member
    function getUnlockedNFTCount(address _member, uint8 _rarityIndex)
    public view
    returns (uint16)
    {
        if (_member == address(0)) {
            revert NFT_WrongInputAddress();
        }
        if (teamUserNftCount[_member][_rarityIndex] == 0) {
            revert NFT_NoVestingAmount();
        }
        if (block.timestamp < vestingStart || vestingEnd <= vestingStart) {
            revert NFT_NoVestingEnabled();
        }

        uint16 _unlockedNFTCount;
        if (block.timestamp >= vestingEnd) {
            _unlockedNFTCount = teamUserNftCount[_member][_rarityIndex];
        } else {
            uint64 _duration = vestingEnd - vestingStart;
            _unlockedNFTCount = uint16((teamUserNftCount[_member][_rarityIndex] * (block.timestamp - vestingStart)) / _duration);
        }

        return _unlockedNFTCount - teamUserMinted[_member][_rarityIndex];
    }

    // @title Change staking contract address for NFT
    function changeStakingContract(
        uint256[] calldata _tokenIdList, address _newStakingAddress
    )
    external
    {
        if (_newStakingAddress == address(0)) {
            revert NFT_WrongInputAddress();
        }
        if (!_isStakingContractExists(_newStakingAddress)) {
            revert NFT_WrongStakingAddress();
        }

        for (uint8 _i = 0; _i < _tokenIdList.length; ++_i) {
            uint256 _tokenId = _tokenIdList[_i];
            if (msg.sender != ownerOf(_tokenId)) {
                revert NFT_NoAccessToCall();
            }

            IStakingContract _stakingContract = IStakingContract(nftStakingAddress[_tokenId]);

            // Unstake NFT
            uint256[] memory _tokenIdArray = new uint256[](1);
            _tokenIdArray[0] = _tokenId;
            _stakingContract.unstake(_tokenIdArray);

            // Change staking contract address
            nftStakingAddress[_tokenId] = _newStakingAddress;
        }

        IStakingContract _newStakingContract = IStakingContract(_newStakingAddress);
        _newStakingContract.stake(_tokenIdList);
    }

    function tokenURI(uint256 _tokenId)
    public view override
    returns (string memory)
    {
        return string.concat("ipfs://", metadataURI, "/", Strings.toString(_tokenId), ".json");
    }

    function contractURI()
    public view
    returns (string memory)
    {
        return string.concat("ipfs://", metadataURI, "/collection.json");
    }

    function supportsInterface(bytes4 _interfaceId)
    public view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function isApprovedForAll(address _owner, address _operator)
    public view
    override(ERC721, IERC721)
    returns (bool)
    {
        if (proxyRegistryAddress == _operator) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    // @title Get all rarity types
    function getAllRarityTypes()
    external view
    returns (RarityType[] memory)
    {
        RarityType[] memory _rarityTypes = new RarityType[](typeCounter);
        for (uint8 _i = 1; _i <= typeCounter; ++_i) {
            _rarityTypes[_i - 1] = rarityTypes[_i];
        }

        return _rarityTypes;
    }

    // @title Get all presalePrices
    function getAllPresalePrices()
    external view
    returns (PresalePrices[] memory)
    {
        PresalePrices[] memory _presalePricesAll = new PresalePrices[](4);
        address[] memory _currencyList = new address[](currencyList.length);
        for (uint8 _i = 0; _i < currencyList.length; ++_i) {
            _currencyList[_i] = currencyList[_i];
        }

        for (uint8 _i = 0; _i < 4; ++_i) {
            RarityNFT _rarity = RarityNFT(_i);
            uint256[] memory _presalePrices = new uint256[](currencyList.length);

            for (uint8 _j = 0; _j < currencyList.length; ++_j) {
                _presalePrices[_j] = presalePrices[_rarity][currencyList[_j]];
            }

            _presalePricesAll[_i] = PresalePrices({
                rarity: _rarity,
                currencyList: _currencyList,
                prices: _presalePrices
            });
        }

        return _presalePricesAll;
    }

    function bulkTransfer(address[] calldata _to, uint256[] calldata _tokenId)
    external
    {
        if (_to.length != _tokenId.length) {
            revert NFT_WrongArgumentsCount();
        }

        for (uint8 _i = 0; _i < _to.length; ++_i) {
            _safeTransfer(msg.sender, _to[_i], _tokenId[_i], "");
        }
    }

    // -------------- Internal ---------------

    function _increaseBalance(address _account, uint128 _value)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(_account, _value);
    }

    // @title NFT mint and transfer
    function _update(address _to, uint256 _tokenId, address _auth)
    internal
    override(ERC721, ERC721Enumerable)
    returns (address)
    {
        if (_ownerOf(_tokenId) != address(0)) {
            firstHandNFTs[_tokenId] = false;

            // Transfer NFT: claim staking rewards and set new owner
            IStakingContract _stakingContract = IStakingContract(nftStakingAddress[_tokenId]);
            _stakingContract.restakeOnSell(_tokenId, _to);
        }

        return super._update(_to, _tokenId, _auth);
    }

    // @title Mint NFT batch
    function _mintBatchAndStake(address _owner, uint8 _typeId, uint8 _amount)
    private
    {
        if (_amount == 0) {
            revert NFT_WrongInputUint();
        }
        if (_owner == address(0)) {
            revert NFT_WrongInputAddress();
        }

        IStakingContract _stakingContract = IStakingContract(stakingDefaultContract);
        uint256[] memory _tokenIdArray = new uint256[](_amount);

        for (uint8 _i = 0; _i < _amount; ++_i) {
            _tokenIdArray[_i] = _mintOne(_owner, _typeId);
        }

        // Start staking
        _stakingContract.stake(_tokenIdArray);
    }

    // @title Mint one NFT
    function _mintOneAndStake(address _owner, uint8 _typeId)
    private
    {
        if (_owner == address(0)) {
            revert NFT_WrongInputAddress();
        }

        IStakingContract _stakingContract = IStakingContract(stakingDefaultContract);
        uint256[] memory _tokenIdArray = new uint256[](1);

        _tokenIdArray[0] = _mintOne(_owner, _typeId);

        // Start staking
        _stakingContract.stake(_tokenIdArray);
    }

    function _mintOne(address _owner, uint8 _typeId)
    private
    returns (uint256)
    {
        RarityType storage rarityType = rarityTypes[_typeId];

        if (rarityType.id == 0) {
            revert NFT_WrongTypeId(_typeId);
        }
        if (rarityType.totalMinted > RARITY_TYPE_SUPPLY) {
            revert NFT_NoSupply("Total Minted", _typeId);
        }

        uint256 _tokenId = uint256(rarityType.firstId + rarityType.totalMinted);
        rarityType.totalMinted += 1;

        _safeMint(_owner, _tokenId);
        nftRarityTypes[_tokenId] = rarityType.id;
        nftStakingAddress[_tokenId] = stakingDefaultContract;

        firstHandNFTs[_tokenId] = true;
        return _tokenId;
    }

    // @title Check if staking contract address exists
    function _isStakingContractExists(address _stakingAddress)
    internal view
    returns (bool)
    {
        for (uint8 _i = 0; _i < stakingContracts.length; ++_i) {
            if (stakingContracts[_i] == _stakingAddress) {
                return true;
            }
        }
        return false;
    }

    // ------------- Only Owner --------------

    // @title Update Lootbox & Quests contract address
    // @param _lootboxAddress: lootbox address
    // @param _questsAddress: quests address
    function updateLinkedAddress(
        address _lootboxAddress, address _questsAddress
    )
    external
    onlyOwner
    {
        if (_lootboxAddress == address(0) || _questsAddress == address(0)) {
            revert NFT_WrongInputAddress();
        }

        lootboxContractAddress = _lootboxAddress;
        questsContractAddress = _questsAddress;
    }

    // @title Add new rarity type
    // @param _rarity: rarity type
    // @param _titles: array of titles
    // @param _hashRate: array of type hashRate
    function addRarityTypes(RarityNFT _rarity, string[] calldata _titles, uint16[] calldata _hashRate)
    external
    onlyOwner
    {
        if (_titles.length == 0 || _titles.length != _hashRate.length) {
            revert NFT_WrongArgumentsCount();
        }

        uint16 _itemsCount = uint16(_titles.length);
        totalPresaleRemain += uint16(distributionTypeSupply[DistributionType.Presale]) * _itemsCount;
        totalQuestsRemain += uint16(distributionTypeSupply[DistributionType.Quests]) * _itemsCount;
        totalTeamRemain += uint16(distributionTypeSupply[DistributionType.Team]) * _itemsCount;
        totalAdvisorRemain += uint16(distributionTypeSupply[DistributionType.Advisor]) * _itemsCount;
        totalLootboxRemain += uint16(distributionTypeSupply[DistributionType.Lootbox]) * _itemsCount;

        uint8[5] memory _remains = [
                        distributionTypeSupply[DistributionType.Presale],
                        distributionTypeSupply[DistributionType.Quests],
                        distributionTypeSupply[DistributionType.Team],
                        distributionTypeSupply[DistributionType.Advisor],
                        distributionTypeSupply[DistributionType.Lootbox]
            ];

        for (uint8 _i = 0; _i < _titles.length; ++_i) {
            if (typeCounter > 100) {
                revert("NFT: Only 100 types allowed");
            }

            typeCounter++;
            uint16 _firstId = uint16(RARITY_TYPE_SUPPLY) * uint16(typeCounter - 1);
            rarityTypes[typeCounter] = RarityType({
                id: typeCounter,
                title: _titles[_i],
                rarity: _rarity,
                hashRate: _hashRate[_i],
                firstId: _firstId + 1,
                totalMinted: 0,
                remains: _remains
            });
        }
    }

    // @title Mint NFT for external marketplaces by rarity
    function advisorMint(RarityNFT _rarityId)
    public
    onlyOwner
    {
        if (totalAdvisorRemain == 0) {
            revert NFT_NoSupply("Total Advisor", uint8(_rarityId));
        }

        uint8[] memory _availableTypes = getAvailableTypes(DistributionType.Advisor, _rarityId);
        for (uint8 _i = 0; _i < _availableTypes.length; ++_i) {
            uint8 _typeId = _availableTypes[_i];
            RarityType storage rarityType = rarityTypes[_typeId];
            uint8 remains = rarityType.remains[uint8(DistributionType.Advisor)];
            if (totalAdvisorRemain < remains || remains == 0) {
                continue;
            }

            _mintBatchAndStake(msg.sender, rarityType.id, remains);
            rarityType.remains[uint8(DistributionType.Advisor)] = 0;
            totalAdvisorRemain -= remains;

            if (_i > 10) {
                break;
            }
        }
    }

    // @title Add/Edit currency list and set presale prices
    function setCurrency(
        address[] calldata _currencyList,
        uint256[] calldata _ordinaryPrices, uint256[] calldata _majesticPrices,
        uint256[] calldata _epicPrices, uint256[] calldata _legendaryPrices
    )
    external
    onlyOwner
    {
        if (_currencyList.length == 0 || _currencyList.length != _ordinaryPrices.length) {
            revert NFT_WrongArgumentsCount();
        }

        for (uint8 _i = 0; _i < _currencyList.length; ++_i) {
            address _currency = _currencyList[_i];
            if (_currency == address(0)) {
                revert NFT_WrongCurrency();
            }
            if (_ordinaryPrices[_i] == 0 || _majesticPrices[_i] == 0 || _epicPrices[_i] == 0 || _legendaryPrices[_i] == 0) {
                revert NFT_WrongInputUint();
            }

            if (!addressExists(currencyList, _currency)) {
                currencyList.push(_currency);
            }

            presalePrices[RarityNFT.Ordinary][_currency] = _ordinaryPrices[_i];
            presalePrices[RarityNFT.Majestic][_currency] = _majesticPrices[_i];
            presalePrices[RarityNFT.Epic][_currency] = _epicPrices[_i];
            presalePrices[RarityNFT.Legendary][_currency] = _legendaryPrices[_i];
        }
    }

    // @title Set team user NFTs count for vesting
    function addTeamUserNftCount(
        address _member, uint16 _ordinaryCount, uint16 _majesticCount,
        uint16 _epicCount, uint16 _legendaryCount
    )
    external
    onlyOwner
    {
        if (_member == address(0)) {
            revert NFT_WrongInputAddress();
        }
        if (vestingStart <= block.timestamp) {
            revert("NFT: Vesting started, can't change rules");
        }
        if (teamUserNftCount[_member].length > 0) {
            revert("NFT: User already added");
        }

        teamUserMinted[_member] = new uint16[](4);
        teamUserNftCount[_member] = new uint16[](4);
        teamUserNftCount[_member][uint8(RarityNFT.Ordinary)] = _ordinaryCount;
        teamUserNftCount[_member][uint8(RarityNFT.Majestic)] = _majesticCount;
        teamUserNftCount[_member][uint8(RarityNFT.Epic)] = _epicCount;
        teamUserNftCount[_member][uint8(RarityNFT.Legendary)] = _legendaryCount;
    }

    // ------------ Only multiSign contract ------------

    // @title Set new default staking contract address
    function setDefaultStaking(address _stakingAddress)
    external
    {
        if (_stakingAddress == address(0)) {
            revert NFT_WrongInputAddress();
        }
        if (stakingDefaultContract != address(0) && msg.sender != multiSignStakingControlAddress) {
            revert NFT_NoAccessToCall();
        }
        if (_isStakingContractExists(_stakingAddress)) {
            revert("NFT: Staking Contract exists");
        }

        stakingDefaultContract = _stakingAddress;
        stakingContracts.push(_stakingAddress);
    }

}
