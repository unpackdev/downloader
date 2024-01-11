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

    function setArt(
        uint256 _id,
        string calldata _collectionName,
        address _collectionAddress,
        string calldata _uri
    ) external onlyOwner {
        Art storage art = arts[_id];
        art.collectionName = _collectionName;
        art.collectionAddress = _collectionAddress;
        art.uri = _uri;
    }

    function changeUri(uint256 _id, string calldata _uri) external onlyOwner {
        arts[_id].uri = _uri;
    }

    function startClaimTimeNow(uint256 _id) external onlyOwner {
        arts[_id].claimTimeStart = block.timestamp;
    }

    function setStartClaimTime(uint256 _id, uint256 _timestamp)
        external
        onlyOwner
    {
        arts[_id].claimTimeStart = _timestamp;
    }

    function resetClaimTime(uint256 _id) external onlyOwner {
        arts[_id].claimTimeStart = 0;
    }

    function claim(uint256 _id, uint256 _amount) external {
        Art storage art = arts[_id];

        require(art.collectionAddress != address(0), "No token for such id");

        uint256 senderLimit = art.whitelist[msg.sender];

        require(_amount <= senderLimit, "Not eligible to claim");

        require(art.claimTimeStart > 0, "Claim time has not started yet");

        require(
            block.timestamp < art.claimTimeStart + claimInterval,
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
