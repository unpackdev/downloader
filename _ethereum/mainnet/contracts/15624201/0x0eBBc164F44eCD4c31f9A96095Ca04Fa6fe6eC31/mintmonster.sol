// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// Todo
// - Update Merkle Root - done
// - Update token image URL (and animation URL) - done
// - Update subscription tiers and references to [1]
// - Format expiry metadata has a real date - Done, need to test

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC1155.sol";
import "./MerkleProof.sol";

contract MintMonster is ERC721, ERC721Enumerable, Ownable {
    struct SubscriptionPlan {
        uint256 price;
        uint256 renewalFee;
        uint256 duration;
        uint256 maxSubscribers;
    }

    struct ActiveSubscriptions {
        uint256 tier;
        uint256 Expiration;
    }

    mapping(uint256 => SubscriptionPlan) subscriptionPlans; // tier => plan
    mapping(uint256 => ActiveSubscriptions) subscriptionExpiration; //token => subscription
    mapping(uint256 => uint256) mintedTokens; //token index

    string public tokenImage =
        "ipfs://bafybeidwj3vqu2yxkbyd63hmbw34qmk5grdsck3ieqrrrsw6cma3dya7z4";
    string public animationURL =
        "ipfs://bafybeid75ggqe7y7x34f747azfcjovcvozsdbfcllskd3i3jchtf2fzcoa";

    bytes32 public merkleRoot =
        0x1dbead77f94505340ff1b4a6ae6e7f248899941f0f1a741672e27c2256bc5509;

    enum SALE_STATE {
        CLOSED,
        WHITELIST,
        PUBLIC
    }

    SALE_STATE public sale_state;

    constructor() ERC721("MintMonster", "MM") {
        // WL 1 month: 0.1 eth to buy, 0.08 eth to renew - Double duration for WL
        subscriptionPlans[0] = SubscriptionPlan(
            0.1 ether,
            0.08 ether,
            30 * DateTimeLibrary.SECONDS_PER_DAY,
            100
        );
        // 1 month: 0.1 eth to buy, 0.08 eth to renew - Double duration for WL
        subscriptionPlans[1] = SubscriptionPlan(
            0.1 ether,
            0.08 ether,
            30 * DateTimeLibrary.SECONDS_PER_DAY,
            300
        );
        // 3 months: 0.25 eth to buy, 0.2 eth to renew
        subscriptionPlans[2] = SubscriptionPlan(
            0.25 ether,
            0.2 ether,
            90 * DateTimeLibrary.SECONDS_PER_DAY,
            150
        );
        // 6 months: 0.45 eth to buy, 0.36 eth to renew
        subscriptionPlans[3] = SubscriptionPlan(
            0.45 ether,
            0.36 ether,
            180 * DateTimeLibrary.SECONDS_PER_DAY,
            75
        );
        // 12 months: 0.75 eth to buy, 0.6 eth to renew
        subscriptionPlans[4] = SubscriptionPlan(
            0.75 ether,
            0.6 ether,
            360 * DateTimeLibrary.SECONDS_PER_DAY,
            50
        );
    }

    // Create a new plan
    function newSubscriptionPlan(
        uint256 _tier,
        uint256 _price,
        uint256 _renewalFee,
        uint256 _duration,
        uint256 _maxSubscribers
    ) public onlyOwner {
        require(subscriptionPlans[_tier].duration < 1, "Plan already exists");
        subscriptionPlans[_tier] = SubscriptionPlan(
            _price,
            _renewalFee,
            _duration,
            _maxSubscribers
        );
    }

    // Edit a existing plan
    function editSubscriptionPlan(
        uint256 _tier,
        uint256 _price,
        uint256 _renewalFee,
        uint256 _duration,
        uint256 _maxSubscribers
    ) public onlyOwner {
        SubscriptionPlan storage plan = subscriptionPlans[_tier];
        require(plan.duration > 0, "Plan doesn't exist");

        if (_price != plan.price) {
            subscriptionPlans[_tier].price = _price;
        }

        if (_renewalFee != plan.renewalFee) {
            subscriptionPlans[_tier].renewalFee = _renewalFee;
        }

        if (_duration != plan.duration) {
            subscriptionPlans[_tier].duration = _duration;
        }

        if (_maxSubscribers != plan.maxSubscribers) {
            subscriptionPlans[_tier].maxSubscribers = _maxSubscribers;
        }
    }

    function getSubscriptionExpiration(uint256 _tokenId)
        public
        view
        returns (ActiveSubscriptions memory)
    {
        ActiveSubscriptions memory plan = subscriptionExpiration[_tokenId];
        return plan;
    }

    function checkUserSub(address _user, uint256 _tier)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < balanceOf(_user); i++) {
            if (checkSubscription(tokenOfOwnerByIndex(_user, i))) {
                if (
                    subscriptionExpiration[tokenOfOwnerByIndex(_user, i)]
                        .tier == _tier
                ) {
                    return
                        subscriptionExpiration[tokenOfOwnerByIndex(_user, i)]
                            .Expiration;
                }
            }
        }
        return 0;
    }

    function getSubscriptionPlan(uint256 _tier)
        public
        view
        onlyOwner
        returns (SubscriptionPlan memory)
    {
        SubscriptionPlan memory plan = subscriptionPlans[_tier];
        require(plan.duration > 0, "Plan doesn't exist");
        return plan;
    }

    function renew(uint256 _tokenId) public payable {
        uint256 _tier = subscriptionExpiration[_tokenId].tier;
        SubscriptionPlan memory plan = subscriptionPlans[_tier];
        require(plan.duration > 0, "Plan doesn't exist");
        require(
            msg.value >= plan.renewalFee,
            "Incorrect value sent for renewal"
        );
        require(ownerOf(_tokenId) == msg.sender, "You do not own token.");

        uint256 startTimestamp = block.timestamp;

        if (subscriptionExpiration[_tokenId].Expiration < startTimestamp) {
            uint256 expiresTimestamp = startTimestamp + plan.duration;
            subscriptionExpiration[_tokenId] = ActiveSubscriptions(
                _tier,
                expiresTimestamp
            );
        } else {
            uint256 expiresTimestamp = subscriptionExpiration[_tokenId]
                .Expiration + plan.duration;
            subscriptionExpiration[_tokenId] = ActiveSubscriptions(
                _tier,
                expiresTimestamp
            );
        }
    }

    // Check if token is expired.  Returns true if valid
    function checkSubscription(uint256 _tokenId) public view returns (bool) {
        ActiveSubscriptions memory plan = getSubscriptionExpiration(_tokenId);
        return plan.Expiration > block.timestamp;
    }

    function getMintedCount(uint256 _tier) internal view returns (uint256) {
        return mintedTokens[_tier];
    }

    function setSaleState(SALE_STATE _state) public onlyOwner {
        sale_state = _state;
    }

    // WL Mint is plan 0
    function whiteListMint(bytes32[] calldata _proof) public payable {
        SubscriptionPlan memory plan = subscriptionPlans[0];
        uint256 mintedCount = getMintedCount(0);
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof");
        require(sale_state == SALE_STATE.WHITELIST, "not WL sale");

        require(plan.maxSubscribers > mintedCount, "Out of stock");
        require(msg.value >= plan.price, "Incorrect value");

        uint256 offset = 0;
        uint256 tokenId = offset + mintedCount + 1;
        uint256 expiresTimestamp = block.timestamp + (plan.duration * 2); // double duration at start only
        subscriptionExpiration[tokenId] = ActiveSubscriptions(
            1,
            expiresTimestamp
        );
        _safeMint(msg.sender, tokenId);
        mintedTokens[1] += 1;
    }

    function mintNewToken(uint256 _tier) public payable {
        SubscriptionPlan memory plan = subscriptionPlans[_tier];
        uint256 mintedCount = getMintedCount(_tier);

        require(plan.duration > 0, "Plan doesn't exist");
        require(plan.maxSubscribers > mintedCount, "Out of stock");
        if (msg.sender != owner()) {
            require(msg.value >= plan.price, "Incorrect value");
        }
        require(sale_state == SALE_STATE.PUBLIC, "Not Public sale");
        require(_tier > 0, "WL Mint Over");

        uint256 offset = 1000000 * _tier;
        uint256 tokenId = offset + mintedCount + 1;
        uint256 expiresTimestamp = block.timestamp + plan.duration;
        subscriptionExpiration[tokenId] = ActiveSubscriptions(
            _tier,
            expiresTimestamp
        );
        _safeMint(msg.sender, tokenId);
        mintedTokens[_tier] += 1;
    }

    function adminMint(
        address[] memory tos_,
        uint256 _tier,
        uint256 _bonusTime
    ) public payable onlyOwner {
        SubscriptionPlan memory plan = subscriptionPlans[_tier];
        uint256 mintedCount = getMintedCount(_tier);

        require(plan.duration > 0, "Plan does not exist");
        require(
            plan.maxSubscribers >= mintedCount + tos_.length,
            "Out of stock"
        );

        for (uint256 i = 0; i < tos_.length; i++) {
            uint256 offset = 1000000 * _tier;
            uint256 tokenId = offset + mintedCount + 1;
            uint256 expiresTimestamp = block.timestamp +
                (plan.duration * _bonusTime);
            subscriptionExpiration[tokenId + i] = ActiveSubscriptions(
                _tier,
                expiresTimestamp
            );
            _safeMint(tos_[i], tokenId + i);
            mintedTokens[_tier] += 1;
        }
    }

    function setmerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function updateTokenImage(string memory _url) public onlyOwner {
        tokenImage = _url;
    }

    function updateTokenAnimation(string memory _url) public onlyOwner {
        animationURL = _url;
    }

    function getMetadata(uint256 _tokenId)
        internal
        view
        returns (string memory)
    {
        ActiveSubscriptions memory plan = subscriptionExpiration[_tokenId];
        string[7] memory parts;
        parts[0] = ', "attributes": [{"trait_type": "Tier","value": "';
        parts[1] = toString(plan.tier);
        parts[2] = '"}, {"trait_type": "Expiration","value": "';
        parts[3] = timestampToUTCDate(plan.Expiration);
        parts[4] = '"}, {"trait_type": "Expired","value": "';
        parts[5] = plan.Expiration < block.timestamp ? "true" : "false";
        parts[6] = '"}], ';

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6]
            )
        );
        return output;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token."
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "MintMonster Access Token", "description": "Access to MintMonster private community and tools."',
                        getMetadata(tokenId),
                        '"image": "',
                        tokenImage,
                        '",'
                        '"animation_url": "',
                        animationURL,
                        '"}'
                    )
                )
            )
        );
        json = string(abi.encodePacked("data:application/json;base64,", json));
        return json;
    }

    //required by Solidity
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    //required by Solidity
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Create a 2 digit string from a string that could be 1 character
    function toPadString(uint256 value) internal pure returns (string memory) {
        string memory str = toString(value);
        uint strlen = bytes(str).length;
        string memory output = strlen == 1
            ? string(abi.encodePacked("0", str))
            : str;
        return output;
    }

    function timestampToUTCDate(uint timestamp)
        internal
        pure
        returns (string memory)
    {
        (uint year, uint month, uint day) = DateTimeLibrary.timestampToDate(
            timestamp
        );
        string memory output = string(
            abi.encodePacked(
                toString(year),
                "-",
                toPadString(day),
                "-",
                toPadString(month)
            )
        );
        return output;
    }
}

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// Short version of the BokkyPooBahsDateTimeLibrary Library
library DateTimeLibrary {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    int constant OFFSET19700101 = 2440588;

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
