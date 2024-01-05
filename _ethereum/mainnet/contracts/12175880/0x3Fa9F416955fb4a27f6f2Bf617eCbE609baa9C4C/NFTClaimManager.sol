// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./Ownable.sol";
import "./IERC1155.sol";

interface ICollection is IERC1155 {
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data,
        string memory newURI
    ) external;

    function setURI(string memory newURI) external;

    function setTokenURI(uint256 id, string memory newURI) external;
}

contract NFTClaimManager is Ownable {
    mapping(address => UserData) public userPoints;
    mapping(uint256 => Nft) public nftPrices;

    struct UserData {
        uint256 points;
        uint248 pointsSpent;
        bool claimedBadge;
    }

    struct Nft {
        uint248 price;
        bool isBadge;
        string uri;
    }

    ICollection public collection;

    bool public claimsAllowed;

    event NFTClaimed(address user, uint256 id, uint256 amount);

    modifier allowed() {
        require(claimsAllowed);
        _;
    }

    constructor(ICollection _collection) {
        collection = _collection;
    }

    function setUserPoints(address[] memory users, uint256[] memory points) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            userPoints[users[i]] = UserData(points[i], 0, false);
        }
    }

    function balanceOf(address user) external view returns (uint256) {
        return userPoints[user].points - userPoints[user].pointsSpent;
    }

    function getPrice(uint256 id) external view returns (uint248) {
        return nftPrices[id].price;
    }

    function setPrices(
        uint256[] memory ids,
        uint248[] memory prices,
        string[] memory uris
    ) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            nftPrices[ids[i]] = Nft(prices[i], false, uris[i]);
        }
    }

    function setBadges(uint256[] memory ids) external onlyOwner {
        for (uint256 i = 0; i < ids.length; i++) {
            nftPrices[ids[i]].isBadge = true;
        }
    }

    function claim(uint256 id, uint256 amount) external allowed {
        UserData storage user = userPoints[msg.sender];
        Nft storage nft = nftPrices[id];
        require(!nft.isBadge, "wrong function to claim badge");
        uint256 price = uint256(nft.price);
        require(price > 0, "nft doesn't exist");
        uint256 pointsLeft = user.points - user.pointsSpent;
        require(pointsLeft >= amount * price, "not enough points");

        user.pointsSpent += uint248(price * amount);
        collection.mint(msg.sender, id, amount, bytes(""), nft.uri);

        emit NFTClaimed(msg.sender, id, amount);
    }

    function claimBadge(uint256 id) external allowed {
        UserData storage user = userPoints[msg.sender];
        Nft storage nft = nftPrices[id];
        require(nft.isBadge, "not a badge");
        require(!user.claimedBadge, "badge already claimed");
        require(user.points > nft.price, "not enough points");

        user.claimedBadge = true;
        collection.mint(msg.sender, id, 1, bytes(""), nft.uri);

        emit NFTClaimed(msg.sender, id, 1);
    }

    function setCollectionURI(string memory newURI) external onlyOwner {
        collection.setURI(newURI);
    }

    function setTokenURI(uint256 id, string memory newURI) external onlyOwner {
        collection.setTokenURI(id, newURI);
    }

    function toggleClaimsAllowed() external onlyOwner {
        claimsAllowed = !claimsAllowed;
    }
}
