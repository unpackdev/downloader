// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./Ownable.sol";
import "./AccessControl.sol";

import "./console.sol";

struct Listing {
    string name;
    string linkUrl;
    string imgUrl;
    uint256 stock;
    uint256 initialAllocation;
    string description;
    uint256 limitPerAddress;
    string other;
}

struct FullListing {
    string name;
    string linkUrl;
    string imgUrl;
    uint256 stock;
    uint256 initialAllocation;
    string description;
    uint256 limitPerAddress;
    string other;
    uint256 price;
}

struct Spot {
    address addy;
    string discordId;
}

interface xBandit {
    function balanceOf(address account) external view returns (uint256);
}

interface BanditStaking {
    function earned(uint256 tokenId) external view returns (uint256);

    function stakedTokensBy(address maybeOwner)
        external
        view
        returns (int256[] memory);
}

contract Marketplace is Ownable, AccessControl {
    mapping(address => uint256) public AddressToSpent;
    string[] public ListingNames;
    mapping(string => Listing) public NameToListing;
    mapping(string => uint256) public NameToPrice;
    mapping(string => Spot[]) public NameToList;
    mapping(string => mapping(address => uint256)) public BoughtSpots;

    xBandit public xb;
    BanditStaking public staking;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function addOperator(address alice) public onlyOwner {
        grantRole(DEFAULT_ADMIN_ROLE, alice);
    }

    function setXBandit(address newAddy) public onlyOwner {
        xb = xBandit(newAddy);
    }

    function getListFor(string memory name)
        public
        view
        returns (Spot[] memory)
    {
        return NameToList[name];
    }

    function setBanditStaking(address newAddy) public onlyOwner {
        staking = BanditStaking(newAddy);
    }

    function addListing(
        string memory name,
        string memory linkUrl,
        string memory imgUrl,
        uint256 initialAllocation,
        string memory description,
        uint256 limitPerAddress,
        string memory other,
        uint256 price
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(NameToPrice[name] == 0, "This listing is already created");

        ListingNames.push(name);
        NameToListing[name] = Listing(
            name,
            linkUrl,
            imgUrl,
            initialAllocation,
            initialAllocation,
            description,
            limitPerAddress,
            other
        );
        NameToPrice[name] = price;
    }

    function removeListing(string memory name)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 i = 0;
        uint256 len = ListingNames.length;

        for (i; i < len; i++) {
            if (equal(ListingNames[i], name)) {
                ListingNames[i] = ListingNames[len - 1];
                ListingNames.pop();
            }
        }

        delete NameToPrice[name];
        delete NameToListing[name];
    }

    function getListings() public view returns (FullListing[] memory) {
        FullListing[] memory fin = new FullListing[](ListingNames.length);

        for (uint256 i = 0; i < ListingNames.length; i++) {
            string memory name = ListingNames[i];
            Listing memory listing = NameToListing[name];

            fin[i] = FullListing(
                name,
                listing.linkUrl,
                listing.imgUrl,
                listing.stock,
                listing.initialAllocation,
                listing.description,
                listing.limitPerAddress,
                listing.other,
                NameToPrice[name]
            );
        }

        return fin;
    }

    function setListingPrice(string memory name, uint256 price)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        NameToPrice[name] = price;
    }

    function buyListing(
        string memory name,
        address alice,
        string memory discordId
    ) public {
        uint256 currentBalance = balanceOf(msg.sender);
        uint256 price = NameToPrice[name];

        require(
            ((currentBalance / (10**18)) - AddressToSpent[msg.sender]) >= price,
            "Insufficient funds"
        );

        Listing memory listing = NameToListing[name];

        require(price > 0, "This listing does not exist yet");
        require(listing.stock > 0, "This list is already full");
        require(
            BoughtSpots[name][alice] < listing.limitPerAddress,
            "You have bought the maximum number of spots on this list"
        );

        NameToListing[name].stock -= 1;
        BoughtSpots[name][alice] += 1;
        AddressToSpent[msg.sender] += NameToPrice[name];
        NameToList[name].push(Spot(alice, discordId));
    }

    function balanceOf(address alice) public view returns (uint256) {
        int256[] memory ownedTokens = staking.stakedTokensBy(alice);
        uint256 sum = 0;
        uint256 length = ownedTokens.length;
        for (uint256 i = 0; i < length; i++) {
            int256 id = ownedTokens[i];

            if (id != -1) {
                sum += staking.earned(uint256(id));
            } else {
                break;
            }
        }

        return xb.balanceOf(alice) + sum;
    }

    function simpleBuyListing(
        string memory name,
        address alice,
        string memory discordId
    ) public {
        uint256 currentBalance = xb.balanceOf(msg.sender);
        uint256 price = NameToPrice[name];

        require(
            ((currentBalance / (10**18)) - AddressToSpent[msg.sender]) >= price,
            "Insufficient funds"
        );

        Listing memory listing = NameToListing[name];

        require(price > 0, "This listing does not exist yet");
        require(listing.stock > 0, "This list is already full");
        require(
            BoughtSpots[name][alice] < listing.limitPerAddress,
            "You have bought the maximum number of spots on this list"
        );

        NameToListing[name].stock -= 1;
        BoughtSpots[name][alice] += 1;
        AddressToSpent[msg.sender] += NameToPrice[name];
        NameToList[name].push(Spot(alice, discordId));
    }

    function addAddressToList(
        string memory name,
        address alice,
        string memory discordId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        NameToList[name].push(Spot(alice, discordId));
    }

    function setListingData(string memory name, string memory data)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        NameToListing[name].other = data;
    }

    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string storage _a, string memory _b)
        internal
        pure
        returns (int256)
    {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint256 minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint256 i = 0; i < minLength; i++)
            if (a[i] < b[i]) return -1;
            else if (a[i] > b[i]) return 1;
        if (a.length < b.length) return -1;
        else if (a.length > b.length) return 1;
        else return 0;
    }

    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string storage _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return compare(_a, _b) == 0;
    }
}
