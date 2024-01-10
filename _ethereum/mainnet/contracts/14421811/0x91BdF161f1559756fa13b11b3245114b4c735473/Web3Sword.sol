// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./Web3SwordMetadata.sol";

// [
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0],
// [0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
// [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
// [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
// [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
// [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0],
// [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
// [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
// [0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0],
// [0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0],
// [0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0],
// [0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0]]
contract Web3Sword is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    struct SwordBlock {
        uint256 tokenId;
        address ownerAddress;
        string imgURL;
        uint256 number;
    }

    mapping(uint256 => SwordBlock) public blockById;

    // mint = 1
    // marketing = 2
    // lucky = 3
    // thirdparty = 4
    // airdrop = 5
    // twitter = 6
    uint8 private constant mint = 1;
    uint8 private constant marketing = 2;
    uint8 private constant lucky = 3;
    uint8 private constant thirdparty = 4;
    uint8 private constant airdrop = 5;
    uint8 private constant tweets = 6;

    bool fullyMint;

    uint256 public currentPrice;

    uint8[][] public swordMatrix;

    IMetadata private metadataGenerator;

    event BuySuccess(address indexed buyer, uint256 tokenId, uint256 value);
    event SocialClaimSuccess(address indexed claimer, uint256 tokenId, uint8 t);
    event Withdrawal(address indexed, uint256 value);
    event ResetPrice(uint256 newPrice);
    event SelledCountUpdate(uint256 value);

    uint256 public selledCount;

    function initialize(IMetadata _metadataGenertaor) public initializer {
        __ERC1155_init("");
        __Ownable_init();
        __UUPSUpgradeable_init();
        fullyMint = false;
        selledCount = 0;
        metadataGenerator = _metadataGenertaor;
        currentPrice = 15 * 10**16;
        swordMatrix.push([0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 0, 0, 6, 6, 0, 0, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 0, 0, 6, 6, 0, 0, 0, 0, 0, 0, 0]);
        swordMatrix.push([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]);
        swordMatrix.push([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]);
        swordMatrix.push([0, 1, 1, 1, 1, 4, 4, 4, 4, 4, 4, 1, 1, 1, 1, 0]);
        swordMatrix.push([0, 0, 0, 1, 1, 4, 4, 4, 4, 4, 4, 1, 1, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 6, 6, 1, 1, 6, 6, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 3, 3, 3, 3, 3, 3, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 1, 1, 1, 3, 1, 1, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 4, 4, 4, 4, 6, 6, 1, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 4, 4, 4, 4, 6, 6, 1, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 4, 4, 4, 4, 4, 4, 1, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 4, 4, 4, 4, 4, 4, 1, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 1, 6, 6, 5, 5, 5, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 1, 6, 6, 5, 5, 5, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 1, 4, 4, 5, 5, 5, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 1, 4, 4, 5, 5, 5, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 5, 5, 5, 6, 6, 1, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 1, 5, 5, 6, 6, 1, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 1, 5, 5, 4, 4, 1, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 1, 5, 5, 4, 4, 1, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 1, 6, 6, 4, 4, 4, 4, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 1, 6, 6, 4, 4, 4, 4, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 1, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 1, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 1, 1, 1, 6, 6, 1, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 1, 1, 1, 6, 6, 1, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 2, 2, 2, 2, 2, 2, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 1, 6, 6, 2, 1, 1, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 1, 6, 6, 2, 1, 1, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 1, 1, 4, 4, 1, 1, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 1, 1, 1, 4, 6, 1, 1, 1, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 1, 1, 6, 6, 1, 1, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0]);
        swordMatrix.push([0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0]);
    }

    function buy(uint256 tokenId) public payable {
        require(msg.value >= currentPrice, "Price has expired, please try again");
        _mint(_msgSender(), tokenId, mint);
        currentPrice = currentPrice + ((currentPrice * 2) / 100);
        emit BuySuccess(_msgSender(), tokenId, msg.value);
    }

    function setMetadataGenerator(IMetadata _metadataGenerator) public onlyOwner {
        metadataGenerator = _metadataGenerator;
    }

    // reset current price
    function resetCurrentPrice(uint256 price) public onlyOwner {
        currentPrice = price;
        emit ResetPrice(currentPrice);
    }

    // claim
    function socialClaim(
        address to,
        uint256 tokenId,
        uint8 t
    ) public onlyOwner {
        _mint(to, tokenId, t);
        emit SocialClaimSuccess(to, tokenId, t);
    }

    // Get the number of tokenId that social can claim
    // Airdrop: 9-100, step: 4
    // Tweets: 0-99, step: 3
    // Lucky: 1-90, step: 12
    function socialCanClaimTokenIds(uint8 t)
        public
        view
        returns (uint256[] memory)
    {
        uint256 start = 0;
        uint256 end = 0;
        uint256 step = 0;
        uint256 totalToSell = 210;
        if (t == airdrop) {
            start = (totalToSell * 9) / 100;
            end = (totalToSell * 100) / 100;
            step = (totalToSell * 4) / 100;
        } else if (t == tweets) {
            start = 0;
            end = (totalToSell * 99) / 100;
            step = (totalToSell * 3) / 100;
        } else if (t == lucky) {
            start = (totalToSell * 1) / 100;
            end = (totalToSell * 90) / 100;
            step = (totalToSell * 12) / 100;
        }
        uint256 unlockCount = (selledCount - start) / step;
        uint256 resultIndex = 0;
        uint256[] memory result = new uint256[](unlockCount);
        if (selledCount < start) {
            return result;
        }
        if (unlockCount == 0) {
            return result;
        }
        for (uint256 i = 0; i < swordMatrix.length; i++) {
            uint8[] memory row = swordMatrix[i];
            for (uint256 j = 0; j < row.length; j++) {
                if (swordMatrix[i][j] != t) {
                    continue;
                }
                if (unlockCount == 0) {
                    return result;
                }
                uint256 tokenId = _computeTokenId(j + 1, i + 1);
                if (blockById[tokenId].ownerAddress != address(0)) {
                    unlockCount = unlockCount - 1;
                    continue;
                }
                result[resultIndex] = tokenId;
                resultIndex++;
                unlockCount = unlockCount - 1;
            }
        }
        return result;
    }

    function _checktokenId(uint256 tokenId, uint8 t)
        internal
        view
        returns (bool)
    {
        (uint256 x, uint256 y) = _getXYPointFromTokenId(tokenId);
        return swordMatrix[y - 1][x - 1] == t;
    }

    function _getXYPointFromTokenId(uint256 tokenId)
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 y = tokenId % 10000;
        uint256 x = (tokenId - y) / 10000;
        return (x, y);
    }

    function _computeTokenId(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return x * 10000 + y;
    }

    function _mint(
        address to,
        uint256 id,
        uint8 t
    ) internal {
        require(
            blockById[id].ownerAddress == address(0),
            "This block is already owned"
        );
        require(_checktokenId(id, t), "This block is not of this type");
        _tokenIdCounter.increment();
        SwordBlock memory b = SwordBlock(id, to, "", _tokenIdCounter.current());
        blockById[id] = b;
        ERC1155Upgradeable._mint(to, id, 1, abi.encodePacked(t));

        if (t == mint) {
            selledCount++;
            emit SelledCountUpdate(selledCount);
        }
    }

    // Upload new imguri
    function upload(uint256 tokenId, string memory _uri) public {
        SwordBlock memory b = blockById[tokenId];
        require(
            b.ownerAddress == _msgSender(),
            "You are not the owner of this block"
        );
        b.imgURL = _uri;
        blockById[tokenId] = b;
        string memory metadataURI = generateMetadataURI(tokenId);
        emit URI(metadataURI, tokenId);
    }

    // Extract eth and send events so that everyone can know
    function withdraw(uint256 value) public onlyOwner {
        require(value > 0);
        require(value <= address(this).balance);
        payable(msg.sender).transfer(value);
        emit Withdrawal(msg.sender, value);
    }

    function name(uint256) public view returns (string memory) {
        return metadataGenerator.name();
    }

    function generateMetadataURI(uint256 id)
        internal
        view
        returns (string memory)
    {
        SwordBlock memory b = blockById[id];
        require(b.tokenId > 0, "This block is not owned");
        return metadataGenerator.tokenMetadata(b.tokenId, b.number, b.imgURL);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return generateMetadataURI(id);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}
