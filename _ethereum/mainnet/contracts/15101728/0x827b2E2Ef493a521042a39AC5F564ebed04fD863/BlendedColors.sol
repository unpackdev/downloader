// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./ERC1155Supply.sol";
import "./Ownable.sol";

contract BlendedColors is Ownable, ERC1155Supply {
    uint256 public claimInterval = 7 days;

    struct Art {
        string collectionName;
        address collectionAddress;
        string uri;
        uint256 claimTimeStart;
        mapping(address => uint256) whitelist;
    }

    mapping(uint256 => Art) public arts;

    constructor() ERC1155("") {}

    function changeClaimInterval(uint256 _interval) external onlyOwner {
        claimInterval = _interval;
    }

    function addWhitelist(
        uint256 _artId,
        address[] calldata _addrs,
        uint256[] calldata _limit
    ) external onlyOwner {
        require(_addrs.length == _limit.length, "length data not same");

        for (uint256 i; i < _addrs.length; ) {
            arts[_artId].whitelist[_addrs[i]] = _limit[i];
            unchecked {
                ++i;
            }
        }
    }

    function setArts(
        uint256[] calldata _ids,
        string[] calldata _collectionNames,
        address[] calldata _collectionAddresses,
        string[] calldata _uris
    ) external onlyOwner {
        require(_ids.length == _collectionNames.length, "length data not same");
        require(
            _ids.length == _collectionAddresses.length,
            "length data not same"
        );
        require(_ids.length == _uris.length, "length data not same");

        for (uint256 i; i < _ids.length; ) {
            Art storage art = arts[_ids[i]];
            art.collectionName = _collectionNames[i];
            art.collectionAddress = _collectionAddresses[i];
            art.uri = _uris[i];
            unchecked {
                ++i;
            }
        }
    }

    function changeUris(uint256[] calldata _ids, string[] calldata _uris)
        external
        onlyOwner
    {
        for (uint256 i; i < _ids.length; ) {
            arts[_ids[i]].uri = _uris[i];
            unchecked {
                ++i;
            }
        }
    }

    function startClaimTimeNow(uint256[] calldata _ids) external onlyOwner {
        for (uint256 i; i < _ids.length; ) {
            arts[_ids[i]].claimTimeStart = block.timestamp;
            unchecked {
                ++i;
            }
        }
    }

    function setStartClaimTime(
        uint256[] calldata _ids,
        uint256[] calldata _timestamps
    ) external onlyOwner {
        require(_ids.length == _timestamps.length, "length data not same");

        for (uint256 i; i < _ids.length; ) {
            arts[_ids[i]].claimTimeStart = _timestamps[i];
            unchecked {
                ++i;
            }
        }
    }

    function resetClaimTime(uint256[] calldata _ids) external onlyOwner {
        for (uint256 i; i < _ids.length; ) {
            arts[_ids[i]].claimTimeStart = 0;
            unchecked {
                ++i;
            }
        }
    }

    function claim(uint256 _id, uint256 _amount) external {
        Art storage art = arts[_id];

        require(art.collectionAddress != address(0), "No token for such id");

        uint256 senderLimit = art.whitelist[msg.sender];

        require(_amount <= senderLimit, "Not eligible to claim");

        require(
            art.claimTimeStart > 0 && block.timestamp > art.claimTimeStart,
            "Claim time has not started yet"
        );

        require(
            art.claimTimeStart + claimInterval > block.timestamp,
            "Claim time is over"
        );

        senderLimit -= _amount;
        art.whitelist[msg.sender] = senderLimit;
        _mint(msg.sender, _id, _amount, "");
    }

    function checkWhitelistAmount(uint256 _id, address _address)
        external
        view
        returns (uint256)
    {
        return arts[_id].whitelist[_address];
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return arts[_id].uri;
    }
}
