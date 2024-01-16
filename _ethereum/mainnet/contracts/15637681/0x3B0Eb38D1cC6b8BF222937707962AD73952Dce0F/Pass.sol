// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract TeleptPass is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public maxMintCount = 1;
    uint256 public totalSupply = 300;
    uint256 public price = 0;

    bool public isMintActive = false;
    bool public requireInvitation = true;

    string baseURI = "https://pass.telept.xyz/token/";

    mapping(address => uint256) mintCount;
    mapping(address => bool) invitationList;

    constructor() ERC721("TeleptPass", "TELEPT") {}

    function mintNFT() public payable returns (uint256) {

        require(isMintActive, "minting is not active");

        if (price > 0) {
            require(msg.value >= price, "paid not enough");
        }

        return mintInternal(msg.sender);
    }

    function mintInternal(address to) internal returns (uint256) {
        uint256 newItemId = _tokenIds.current();

        if (maxMintCount > 0) {
            require(mintCount[to] < maxMintCount, "exceeded max mint count");
        }

        require(newItemId < totalSupply, "no more tokens");

        if (requireInvitation) {
            require(invitationList[to], "not in the invitation list");
        }

        _tokenIds.increment();

        uint256 tokenId = getFromattedDateFrom(newItemId);

        _mint(to, tokenId);
        _setTokenURI(
            tokenId,
            string(abi.encodePacked(baseURI, Strings.toString(tokenId)))
        );

        mintCount[to] += 1;

        return tokenId;
    }

    function airdrop(address[] calldata wAddresses) public onlyOwner {
        for (uint256 i = 0; i < wAddresses.length; i++) {
            mintInternal(wAddresses[i]);
        }
    }

    function setPrice(uint256 priceUpdate) public onlyOwner {
        price = priceUpdate;
    }

    function setTotalSupply(uint256 totalSupplyUpdate) public onlyOwner {
        totalSupply = totalSupplyUpdate;
    }

    function setMaxMintCount(uint256 maxMintCountUpdate) public onlyOwner {
        maxMintCount = maxMintCountUpdate;
    }

    function setMintActive(bool mintActiveUpdate) public onlyOwner {
        isMintActive = mintActiveUpdate;
    }

    function setRequireInvitation(bool requireInvitationUpdate)
        public
        onlyOwner
    {
        requireInvitation = requireInvitationUpdate;
    }

    function addToInvitationList(address[] calldata addresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            invitationList[addresses[i]] = true;
        }
    }

    function removeFromInvitationList(address[] calldata addresses)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            invitationList[addresses[i]] = false;
        }
    }

    function getCurrentId() public view returns (uint256) {
        return _tokenIds.current();
    }

    uint256 constant START_TIMESTAMP = 1225411200;
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    int constant OFFSET19700101 = 2440588;

    function getFromattedDateFrom(uint dayPassed)
        internal
        pure
        returns (uint date)
    {
        (uint year, uint mon, uint day) = timestampToDate(
            START_TIMESTAMP + dayPassed * SECONDS_PER_DAY
        );
        return year * 10000 + mon * 100 + day;
    }

    function _daysToDate(uint _days)
        internal
        pure
        returns (
            uint year,
            uint month,
            uint day
        )
    {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int _month = (80 * L) / 2447;
        int _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampToDate(uint timestamp)
        internal
        pure
        returns (
            uint year,
            uint month,
            uint day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
}
