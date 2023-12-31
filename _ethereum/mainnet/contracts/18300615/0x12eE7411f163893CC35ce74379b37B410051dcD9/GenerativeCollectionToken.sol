// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC2981.sol";
import "./IRandomizer.sol";

import "./ICollectionAirdrop.sol";
import "./ICollectionGoldList.sol";
import "./ICollectionWhiteList.sol";
import "./ICollectionProfitSplit.sol";

contract GenerativeCollectionToken is ERC721, ERC2981 {
    string private _token_uri;

    address private _owner;
    address private _platform_address;
    address private _randomizer_address;
    address private _whitelist_storage_address;
    address private _goldlist_storage_address;
    address private _airdrop_storage_address;
    address private _profit_split_storage_address;

    uint256 private _price;
    uint256 private _limit;
    uint256 private _limit_per_wallet;
    uint256 private _start_time;

    bool private _is_randomness;
    uint96 private _royalty;

    uint256 private total_supply;
    uint256 private reserved;
    uint256 private gold_list_amount_minted;

    mapping(uint256 => uint256) private _id_to_metadata__id;
    mapping(address => uint256) private _minted_amount_by_user;
    mapping(address => uint256) private _reservations;
    mapping(address => uint256) private _minted_reservations;

    event reservation(address eth_address, uint256 price, uint256 timestamp, uint256 amount, bool is_whitelist_member, bool is_goldlist_member);

    constructor(
        address[7] memory main_addresses_,
        uint256[4] memory main_data,
        string[3] memory metadata_,
        uint96 royalty_,
        bool is_randomness_
    ) ERC721(metadata_[0], metadata_[1]) {
        _token_uri = metadata_[2];

        _owner = main_addresses_[0];
        _platform_address = main_addresses_[1];
        _randomizer_address = main_addresses_[2];
        _whitelist_storage_address = main_addresses_[3];
        _goldlist_storage_address = main_addresses_[4];
        _airdrop_storage_address = main_addresses_[5];
        _profit_split_storage_address = main_addresses_[6];

        _price = main_data[0];
        _limit = main_data[1];
        _limit_per_wallet = main_data[2];
        _start_time = main_data[3];

        _is_randomness = is_randomness_;
        _royalty = royalty_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(uint256 quantity_) external payable {
        require(_reservations[msg.sender] == _minted_reservations[msg.sender]);
        require(_limit - reserved >= total_supply + quantity_);
        require(_minted_amount_by_user[msg.sender] + quantity_ <= _limit_per_wallet);

        (uint256 goldlist_start_time, uint256 goldlist_amount, uint256 goldlist_price, bool is_goldlist_custody) = ICollectionGoldList(_goldlist_storage_address).getOptions(address(this));
        (uint256 whitelist_start_time, uint256 whitelist_amount, uint256 whitelist_price, bool is_whitelist_custody) = ICollectionWhiteList(_goldlist_storage_address).getOptions(address(this));

        bool has_access_token = total_supply + quantity_ <= ICollectionAirdrop(_airdrop_storage_address).getOptions(address(this)) ? ICollectionAirdrop(_airdrop_storage_address).isMember(address(this), msg.sender) : false;
        bool has_goldlist_access = !has_access_token ? goldlist_amount >= gold_list_amount_minted + quantity_ && ICollectionGoldList(_goldlist_storage_address).isMember(address(this), msg.sender) : false;
        bool has_whitelist_access = !has_access_token ? ICollectionWhiteList(_whitelist_storage_address).isMember(address(this), msg.sender) : false;

        
        if (total_supply + quantity_ > ICollectionAirdrop(_airdrop_storage_address).getOptions(address(this)) || !has_access_token) {
            require((has_goldlist_access ? goldlist_start_time : has_whitelist_access ? whitelist_start_time : _start_time) <= block.timestamp);
            require((has_goldlist_access ? goldlist_price : has_whitelist_access ? whitelist_price : _price) * quantity_ <= msg.value);
        }
        
        if (has_goldlist_access) gold_list_amount_minted += quantity_;

        for (uint256 i = 0; i < quantity_; i++) {
            uint256 tokenId = _is_randomness ? IRandomizer(_randomizer_address).requestRandomWords() : total_supply + i + 1;
            _mint(msg.sender, tokenId);
            _id_to_metadata__id[tokenId] = total_supply + i + 1;
            _setTokenRoyalty(tokenId, msg.sender, _royalty);
        }

        if (msg.value > 0) {
            (address[] memory profit_split_addresses, uint256[] memory profit_split_values, uint256 total) = ICollectionProfitSplit(_profit_split_storage_address).getProfitSplit(address(this));
            uint256 profit_spit = (msg.value * total) / 1000;
            uint256 owner_fee = ((msg.value * 975) / 1000) - profit_spit;
            payable(_owner).send(owner_fee);
            payable(_platform_address).send(msg.value - profit_spit - owner_fee);
            for (uint256 i = 0; i < profit_split_values.length; i++) {
                payable(profit_split_addresses[i]).send((msg.value * profit_split_values[i]) / 1000);
            }
        }

        _minted_amount_by_user[msg.sender] += quantity_;
        total_supply += quantity_;
    }

    function claim() public {
        (uint256 goldlist_start_time, uint256 goldlist_amount, uint256 goldlist_price, bool is_goldlist_custody) = ICollectionGoldList(_goldlist_storage_address).getOptions(address(this));
        (uint256 whitelist_start_time, uint256 whitelist_amount, uint256 whitelist_price, bool is_whitelist_custody) = ICollectionWhiteList(_goldlist_storage_address).getOptions(address(this));
        bool has_goldlist_access = ICollectionGoldList(_goldlist_storage_address).isMember(address(this), msg.sender);
        bool has_whitelist_access = ICollectionWhiteList(_whitelist_storage_address).isMember(address(this), msg.sender);

        require(has_goldlist_access || has_whitelist_access);
        if (has_goldlist_access) require(goldlist_start_time <= block.timestamp);
        if (has_whitelist_access) require(whitelist_start_time <= block.timestamp);

        require(_reservations[msg.sender] - _minted_reservations[msg.sender] > 0);
        for (uint256 i = 0; i < _reservations[msg.sender] - _minted_reservations[msg.sender]; i++) {
            uint256 tokenId = _is_randomness ? IRandomizer(_randomizer_address).requestRandomWords() : total_supply + i + 1;
            _mint(msg.sender, tokenId);
            _id_to_metadata__id[tokenId] = total_supply + i + 1;
            _setTokenRoyalty(tokenId, msg.sender, _royalty);
        }
        total_supply += _reservations[msg.sender] - _minted_reservations[msg.sender];
        _minted_amount_by_user[msg.sender] += _reservations[msg.sender] - _minted_reservations[msg.sender];
        reserved = reserved - (_reservations[msg.sender] - _minted_reservations[msg.sender]);
        _minted_reservations[msg.sender] = _reservations[msg.sender];
    }

    function reserve(uint256 quantity_) public payable {
        (uint256 goldlist_start_time, uint256 goldlist_amount, uint256 goldlist_price, bool is_goldlist_custody) = ICollectionGoldList(_goldlist_storage_address).getOptions(address(this));
        (uint256 whitelist_start_time, uint256 whitelist_amount, uint256 whitelist_price, bool is_whitelist_custody) = ICollectionWhiteList(_whitelist_storage_address).getOptions(address(this));
        bool is_goldlist_member = goldlist_amount >= gold_list_amount_minted + quantity_ && ICollectionGoldList(_goldlist_storage_address).isMember(address(this), msg.sender);
        bool is_whitelist_member = ICollectionWhiteList(_whitelist_storage_address).isMember(address(this), msg.sender);
        require((is_goldlist_custody && is_goldlist_member) || (is_whitelist_custody && is_whitelist_member), "PD");
        uint256 price = is_goldlist_member ? goldlist_price : whitelist_price;
        require(price * quantity_ <= msg.value, "NF");
        require(_limit >= reserved + total_supply + quantity_);
        require(_reservations[msg.sender] + _minted_amount_by_user[msg.sender] + quantity_  <= _limit_per_wallet);
        reserved += quantity_;
        _reservations[msg.sender] += quantity_;
        if (is_goldlist_member) gold_list_amount_minted += quantity_;
        if (price > 0) {
            (address[] memory profit_split_addresses, uint256[] memory profit_split_values, uint256 total) = ICollectionProfitSplit(_profit_split_storage_address).getProfitSplit(address(this));
            uint256 profit_spit = (msg.value * total) / 1000;
            uint256 owner_fee = ((msg.value * 975) / 1000) - profit_spit;
            payable(_owner).send(owner_fee);
            payable(_platform_address).send(msg.value - profit_spit - owner_fee);
            for (uint256 i = 0; i < profit_split_values.length; i++) {
                payable(profit_split_addresses[i]).send((msg.value * profit_split_values[i]) / 1000);
            }
        }
        emit reservation(msg.sender, price, block.timestamp, quantity_, is_whitelist_member, is_goldlist_member);
    }

    function getReservation(address eth_address_) public view returns (uint256) {
        return _reservations[eth_address_] - _minted_reservations[eth_address_];
    }

    function concatenate(string memory a, string memory b) private pure returns (string memory) {
        return string(abi.encodePacked(a, "", b));
    }

    function tokenURI(uint256 token_id) public view override returns (string memory) {
        require(_exists(token_id));
        return concatenate(_token_uri, concatenate(Strings.toString(_id_to_metadata__id[token_id]), ".json"));
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function edit(uint256 start_time_, uint256 price_, uint256 limit_per_wallet_, uint96 royalty_) public {
        require(owner() == msg.sender);
        _start_time = start_time_;
        _price = price_;
        _limit_per_wallet = limit_per_wallet_;
        _royalty = royalty_;
    }

    function info() public view returns (uint256, uint256, uint256, uint96) {
        return (_start_time, _price, _limit_per_wallet, _royalty);
    }

    function terminate() public {
        require(owner() == msg.sender);
        selfdestruct(payable(msg.sender));
    }
}
