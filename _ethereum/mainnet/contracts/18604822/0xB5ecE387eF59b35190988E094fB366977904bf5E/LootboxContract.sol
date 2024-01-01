//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

//import "./console.sol";
import "./ERC1155.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./utils.sol";
import "./NFTContract.sol";

contract LootboxContract is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply, Utils {
    using SafeERC20 for IERC20;

    string public name;
    string public symbol;
    string private metadataURI;
    uint16 private totalTypesReserved;

    NFTContract private immutable nftContractRef;
    address private immutable multiSignWithdrawAddress;
    address private immutable wethTokenAddress;
    address[] private currencyList;

    mapping(RarityLootbox => uint8[]) public nftRarityTypes;
    mapping(RarityLootbox => uint16) public lootboxRemains;
    mapping(address => uint32) public userOpenedLootboxes;
    mapping(uint8 => uint8) private typesReservedAmount;
    mapping(address => mapping(RarityLootbox => uint64)) private userLastBlock;
    mapping(address => mapping(RarityLootbox => uint8[])) private userTypesReserved;
    mapping(address => mapping(RarityLootbox => bool)) public userOpenInProgress;
    mapping(RarityLootbox => mapping(address => uint256)) private presalePrices;

    struct PresalePrices {
        RarityLootbox rarity;
        address[] currencyList;
        uint256[] prices;
    }

    event LootboxBurned(address indexed _owner, RarityLootbox indexed _rarityId, uint16 _amount);
    event LootboxResult(address indexed _owner, RarityLootbox indexed _rarityId, uint8 _typeId);
    event LootboxNFTCount(address indexed _owner, uint16 _amount);

    constructor(
        address _initialOwner, string memory _name, string memory _symbol, string memory _metadataURI,
        address _nftContractRef, address _multiSignWithdrawAddress, address _wethTokenAddress
    )
    ERC1155(string.concat("ipfs://", _metadataURI, "/{id}.json"))
    Ownable(_initialOwner)
    {
        name = _name;
        symbol = _symbol;
        metadataURI = _metadataURI;
        nftContractRef = NFTContract(_nftContractRef);
        multiSignWithdrawAddress = _multiSignWithdrawAddress;
        wethTokenAddress = _wethTokenAddress;

        lootboxRemains[RarityLootbox.Common] = 2400;
        lootboxRemains[RarityLootbox.Rare] = 1600;
        lootboxRemains[RarityLootbox.Epic] = 1200;
        lootboxRemains[RarityLootbox.Legendary] = 400;

        // Set lootbox rarity chances for NFT: Legendary, Epic, Majestic, Ordinary
        nftRarityTypes[RarityLootbox.Common] = [2, 10, 30, 100]; // 2, 8, 20, 70
        nftRarityTypes[RarityLootbox.Rare] = [5, 30, 60, 100]; // 5, 25, 30, 40
        nftRarityTypes[RarityLootbox.Epic] = [10, 10, 50, 100]; // 10, 0, 40, 50
        nftRarityTypes[RarityLootbox.Legendary] = [40, 70, 100, 100]; // 40, 30, 30, 0
    }

    // ----------- Public/External ------------

    function contractURI()
    public view
    returns (string memory)
    {
        return string.concat("ipfs://", metadataURI, "/collection.json");
    }

    function uri(uint256 _tokenId)
    public view override
    returns (string memory)
    {
        return string.concat("ipfs://", metadataURI, "/", Strings.toString(_tokenId), ".json");
    }

    function allLootboxRemains() public view returns (uint16, uint16, uint16, uint16) {
        return (
            lootboxRemains[RarityLootbox.Common],
            lootboxRemains[RarityLootbox.Rare],
            lootboxRemains[RarityLootbox.Epic],
            lootboxRemains[RarityLootbox.Legendary]
        );
    }

    // @title Mint lootbox using ERC20
    // @param _rarityIds: array of lootbox rarity id
    // @param _amounts: array how much NFT mint
    // @param _currency: token that used for payment
    function mintERC20(RarityLootbox[] calldata _rarityIds, uint16[] calldata _amounts, address _currency)
    external
    {
        if (_rarityIds.length == 0 || _rarityIds.length != _amounts.length) {
            revert Lootbox_WrongArgumentsCount();
        }
        if (_currency == address(0)) {
            revert Lootbox_WrongInputAddress();
        }

        for (uint8 _i = 0; _i < _rarityIds.length; ++_i) {
            RarityLootbox _rarity = _rarityIds[_i];

            if (lootboxRemains[_rarity] < _amounts[_i]) {
                revert Lootbox_NoSupply(_rarity);
            }
            if (presalePrices[_rarity][_currency] == 0) {
                revert Lootbox_WrongCurrency();
            }

            uint256 _paymentAmount = presalePrices[_rarity][_currency] * _amounts[_i];
            SafeERC20.safeTransferFrom(IERC20(_currency), msg.sender, multiSignWithdrawAddress, _paymentAmount);

            lootboxRemains[_rarity] -= _amounts[_i];
            _mint(msg.sender, uint256(_rarity), _amounts[_i], "");
        }
    }

    // @title Mint lootboxes using ETH
    // @param _rarityIds: array lootbox rarity id
    // @param _amounts: array how much NFT mint
    function mintETH(RarityLootbox[] calldata _rarityIds, uint16[] calldata _amounts)
    external payable
    {
        if (_rarityIds.length == 0 || _rarityIds.length != _amounts.length) {
            revert Lootbox_WrongArgumentsCount();
        }
        if (msg.value == 0) {
            revert NFT_WrongPaymentAmount();
        }

        bool success = payable(multiSignWithdrawAddress).send(msg.value);
        require(success, "Lootbox: ETH transfer failed");

        uint256 _paymentAmount = 0;
        for (uint8 _i = 0; _i < _rarityIds.length; ++_i) {
            RarityLootbox _rarity = _rarityIds[_i];

            if (lootboxRemains[_rarity] < _amounts[_i]) {
                revert Lootbox_NoSupply(_rarity);
            }
            if (presalePrices[_rarity][wethTokenAddress] == 0) {
                revert NFT_WrongCurrency();
            }

            _paymentAmount += presalePrices[_rarity][wethTokenAddress] * _amounts[_i];
            lootboxRemains[_rarity] -= _amounts[_i];

            _mint(msg.sender, uint256(_rarity), _amounts[_i], "");
        }

        if (msg.value != _paymentAmount) {
            revert NFT_WrongPaymentAmount();
        }
    }

    // @title Open Lootbox - Step 1
    // @param _rarityId: lootbox id
    // @param _amount: _lootboxAmount of lootboxes to open
    function openLootboxStep1(RarityLootbox _rarityId, uint16 _lootboxAmount)
    external
    {
        if (_lootboxAmount == 0) {
            revert("LB: Wrong amount input");
        }
        if (balanceOf(msg.sender, uint256(_rarityId)) < _lootboxAmount) {
            revert("LB: Not enough lootboxes in your balance");
        }

        _burn(msg.sender, uint256(_rarityId), _lootboxAmount);
        userLastBlock[msg.sender][_rarityId] = uint64(block.number);
        uint16 _totalRemain = nftContractRef.totalLootboxRemain();

        for (uint16 _i = 0; _i < _lootboxAmount; ++_i) {
            uint8 _mintAmount = getNftAmountByRarity(_rarityId);
            if (_mintAmount > 0 && _totalRemain >= _mintAmount + totalTypesReserved) {
                if (_mintAmount > _totalRemain - totalTypesReserved) {
                    _mintAmount = uint8(_totalRemain - totalTypesReserved);
                }

                _totalRemain -= _mintAmount;
                totalTypesReserved += uint16(_mintAmount);

                for (uint8 _j = 0; _j < _mintAmount; ++_j) {
                    uint8 _mintType = getRandomAvailableType(_rarityId);
                    typesReservedAmount[_mintType] += 1;
                    userTypesReserved[msg.sender][_rarityId].push(_mintType);
                }
            }
        }

        userOpenedLootboxes[msg.sender] += _lootboxAmount;
        userOpenInProgress[msg.sender][_rarityId] = true;

        emit LootboxBurned(msg.sender, _rarityId, _lootboxAmount);
    }

    // @title Open Lootbox - Step 2, mint result NFTs
    // @param _rarityId: lootbox id
    function openLootboxStep2(RarityLootbox _rarityId)
    external
    {
        if (userLastBlock[msg.sender][_rarityId] >= block.number) {
            revert("LB: Can't open lootbox in the same block");
        }

        uint16 _reservedAmount = uint16(userTypesReserved[msg.sender][_rarityId].length);

        for (uint16 _i = 0; _i < _reservedAmount; ++_i) {
            uint8 _typeId = userTypesReserved[msg.sender][_rarityId][_i];
            typesReservedAmount[_typeId] -= 1;
            nftContractRef.lootboxMintNFT(msg.sender, _typeId);

            emit LootboxResult(msg.sender, _rarityId, _typeId);
        }

        totalTypesReserved -= _reservedAmount;
        userTypesReserved[msg.sender][_rarityId] = new uint8[](0);
        userOpenInProgress[msg.sender][_rarityId] = false;

        emit LootboxNFTCount(msg.sender, _reservedAmount);
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
            RarityLootbox _rarity = RarityLootbox(_i);
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

    // --------------- Internal ----------------

    function _update(address _from, address _to, uint256[] memory _ids, uint256[] memory _values)
    internal
    override(ERC1155, ERC1155Supply)
    {
        super._update(_from, _to, _ids, _values);
    }

    // -------------- Private --------------

    function getNftAmountByRarity(RarityLootbox _rarityId)
    private
    returns (uint8)
    {
        if (_rarityId == RarityLootbox.Common || _rarityId == RarityLootbox.Rare) {
            return uint8(randomNum(3)); // 0-2
        }
        return uint8(randomNum(4)); // 0-3
    }

    // @title Get random available type by rarity
    function getRandomAvailableType(RarityLootbox _rarityId)
    private
    returns (uint8)
    {
        uint8 _randNftRarity = uint8(randomNum(100) + 1); // 1-100

        RarityNFT _rarityNFT;
        if (_randNftRarity <= nftRarityTypes[_rarityId][0]) {
            _rarityNFT = RarityNFT.Legendary;
        } else if (_randNftRarity <= nftRarityTypes[_rarityId][1]) {
            _rarityNFT = RarityNFT.Epic;
        } else if (_randNftRarity <= nftRarityTypes[_rarityId][2]) {
            _rarityNFT = RarityNFT.Majestic;
        } else {
            _rarityNFT = RarityNFT.Ordinary;
        }

        uint8[] memory _types = nftContractRef.getAvailableTypes(DistributionType.Lootbox, _rarityNFT);

        // retry - no available types
        if (_types.length == 0) {
            return getRandomAvailableType(_rarityId);
        }

        // Return random type from list
        uint8 _resultType = _types[randomNum(_types.length)];
        if (nftContractRef.nftLootboxRemains(_resultType) > typesReservedAmount[_resultType]) {
            return _resultType;
        } else {
            // retry - type not available (all reserved)
            return getRandomAvailableType(_rarityId);
        }
    }

    // ------------- Only Owner --------------

    // @title Add/Edit currency list and set presale prices
    function setCurrency(
        address[] calldata _currencyList,
        uint256[] calldata _commonPrices, uint256[] calldata _rarePrices,
        uint256[] calldata _epicPrices, uint256[] calldata _legendaryPrices
    )
    external
    onlyOwner
    {
        if (_currencyList.length == 0 || _currencyList.length != _commonPrices.length) {
            revert Lootbox_WrongArgumentsCount();
        }

        for (uint8 _i = 0; _i < _currencyList.length; ++_i) {
            address _currency = _currencyList[_i];
            if (_currency == address(0)) {
                revert Lootbox_WrongCurrency();
            }
            if (_commonPrices[_i] == 0 || _rarePrices[_i] == 0 || _epicPrices[_i] == 0 || _legendaryPrices[_i] == 0) {
                revert Lootbox_WrongInputUint();
            }

            if (!addressExists(currencyList, _currency)) {
                currencyList.push(_currency);
            }

            presalePrices[RarityLootbox.Common][_currency] = _commonPrices[_i];
            presalePrices[RarityLootbox.Rare][_currency] = _rarePrices[_i];
            presalePrices[RarityLootbox.Epic][_currency] = _epicPrices[_i];
            presalePrices[RarityLootbox.Legendary][_currency] = _legendaryPrices[_i];
        }
    }

    function mintOwner(RarityLootbox _rarityId, uint16 _amount)
    external
    onlyOwner
    {
        if (lootboxRemains[_rarityId] < _amount) {
            revert Lootbox_NoSupply(_rarityId);
        }

        lootboxRemains[_rarityId] -= _amount;
        _mint(msg.sender, uint256(_rarityId), _amount, "");
    }

}