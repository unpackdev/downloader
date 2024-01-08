//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./ERC721.sol";

contract Pixels is ERC721 {
    uint256 public constant TOP_PRICE = 1e16;
    uint256 public constant MEDIUM_PRICE = 1e15;
    uint256 public constant LOW_PRICE = 5e14;

    uint32 public constant MAX_PROMOTIONAL_AREAS_SIZE = 100000;
    uint32[4] public MEDIUM;
    uint32[4] public TOP;

    uint32 public width = 1000;
    uint32 public height = 1000;

    //percentage with 10000 precision
    uint32 public fee;

    address creator;

    string public baseURI;

    uint32 public promotionalBought;

    struct Area {
        uint32[4] rect; //0 - X , 1- Y ,2 - width, 3 - height
        string ipfs;
        uint64 mintedAtBlock;
    }

    struct Sale {
        uint128 price;
        uint128 end; //end of sale timestamp
    }

    Area[] public areas;

    mapping(uint256 => Sale) public forSale; //tokenId -> Sale

    mapping(bytes32 => uint256) public commits; //commitment hash -> commit block

    address private vault;

    constructor(
        string memory _baseuri,
        address _vault,
        uint32 _medAreaSize,
        uint32 _topAreaSize
    ) ERC721("MillionPixelsGallery", "MPG") {
        creator = _vault;
        width = 1000;
        height = 1000;
        vault = _vault;
        fee = 375; //3.75 %
        baseURI = _baseuri;
        MEDIUM = [
            width / 2 - _medAreaSize / 2,
            height / 2 - _medAreaSize / 2,
            _medAreaSize,
            _medAreaSize
        ];
        TOP = [
            width / 2 - _topAreaSize / 2,
            height / 2 - _topAreaSize / 2,
            _topAreaSize,
            _topAreaSize
        ];
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev returns the rect of a token
     */
    function getBounds(uint256 id) public view returns (uint32[4] memory) {
        return areas[id].rect;
    }

    /**
     * @dev returns areas length
     */
    function getAreasCount() public view returns (uint256) {
        return areas.length;
    }

    /**
     * @dev given a rectangle, returns the cost in ETH
     */
    function pixelsCost(uint32[4] memory area) public view returns (uint256) {
        uint256 topArea = uint256(overlap(area, TOP));
        uint256 medArea = uint256(overlap(area, MEDIUM));
        uint256 regular = uint256(area[2] * area[3]);
        uint256 cost = topArea *
            TOP_PRICE +
            ((medArea - topArea) * MEDIUM_PRICE) +
            ((regular - medArea) * LOW_PRICE);

        return cost;
    }

    /**
     * @dev given a rectangle checks if it does not intersect with existing Areas
     */
    function isAreaAvailable(uint32[4] memory area)
        external
        view
        returns (uint256, bool)
    {
        require(area[0] + area[2] <= width && area[1] + area[3] <= height);
        for (uint256 i = 0; i < areas.length; i++) {
            if (_isIntersecting(areas[i].rect, area)) return (i, false);
        }
        return (0, true);
    }

    /**
     * @dev user must call this first before calling buyPixels
     * @param areaHash keccak256(rect:uint[4], commitNonce:uint, publickey:address)
     */
    function commitToPixels(bytes32 areaHash) external {
        require(commits[areaHash] == 0, "commit already set");
        commits[areaHash] = block.number;
    }

    /**
     * @dev generate a new NFT for unoccupied pixels
     * user must first send a commitment to buy that area (commitment=hash(area,ipfs,public address))
     * @param area rectangle to generate NFT for
     * @param ipfs the ipfs hash containing display data for the NFT
     */
    function buyPixels(
        uint32[4] memory area,
        uint256 commitNonce,
        string calldata ipfs
    ) external payable {
        require(
            area[0] + area[2] <= width && area[1] + area[3] <= height,
            "out of bounds"
        );
        _checkCommit(area, commitNonce, _msgSender());

        uint256 cost = _msgSender() == creator ? 0 : pixelsCost(area);
        require(cost <= msg.value, "Pixels: invalid payment");

        if (_msgSender() == creator) {
            promotionalBought += area[2] * area[3];
            require(
                promotionalBought <= MAX_PROMOTIONAL_AREAS_SIZE,
                "promotional areas exceeds limit"
            );
        }

        Area memory bought;
        bought.rect = area;
        bought.mintedAtBlock = uint64(block.number);
        bought.ipfs = ipfs;
        areas.push(bought);

        _mint(_msgSender(), areas.length - 1);
        payable(vault).transfer(msg.value);
    }

    /**
     * @dev owner can put his NFT for sale
     * @param id token to sell
     * @param price price in eth(wei)
     * @param duration number of days sale is open for
     */
    function sell(
        uint256 id,
        uint128 price,
        uint8 duration
    ) external {
        require(ERC721.ownerOf(id) == _msgSender(), "only owner can sell");
        Sale storage r = forSale[id];
        r.price = price;
        r.end = uint128(block.timestamp + duration * 1 days);
    }

    /**
     * @dev check if a token is for sale
     */
    function isForSale(uint256 id) public view returns (bool) {
        Sale memory r = forSale[id];
        return r.price > 0 && r.end > block.timestamp;
    }

    /**
     * @dev buy an area that is for sale
     * @param id token to buy
     * @param ipfsHash new content to attach to the bought NFT
     */
    function buy(uint256 id, string calldata ipfsHash) external payable {
        Sale memory sale = forSale[id];
        require(isForSale(id), "not for sale");
        require(msg.value >= sale.price, "payment too low");
        uint256 resellFee = (sale.price * fee) / 10000;
        areas[id].ipfs = ipfsHash;
        delete forSale[id];
        payable(ERC721.ownerOf(id)).transfer(msg.value - resellFee);
        payable(vault).transfer(resellFee);
        _transfer(ERC721.ownerOf(id), _msgSender(), id);
    }

    /**
     * @dev set a new ipfs hash for token
     */
    function setIPFSHash(uint256 id, string calldata ipfsHash) external {
        require(ERC721.ownerOf(id) == _msgSender(), "only owner can set ipfs");
        areas[id].ipfs = ipfsHash;
    }

    function _isIntersecting(uint32[4] memory obj1, uint32[4] memory obj2)
        internal
        pure
        returns (bool)
    {
        // If one rectangle is on left side of other
        if (obj1[0] >= obj2[0] + obj2[2] || obj2[0] >= obj1[0] + obj1[2]) {
            return false;
        }

        // If one rectangle is above other
        if (obj1[1] >= obj2[1] + obj2[3] || obj2[1] >= obj1[1] + obj1[3]) {
            return false;
        }

        return true;
    }

    function overlap(uint32[4] memory obj1, uint32[4] memory obj2)
        public
        pure
        returns (uint32)
    {
        int32 x_overlap = _max(
            0,
            _min(int32(obj1[0] + obj1[2]), int32(obj2[0] + obj2[2])) -
                _max(int32(obj1[0]), int32(obj2[0]))
        );
        int32 y_overlap = _max(
            0,
            _min(int32(obj1[1] + obj1[3]), int32(obj2[1] + obj2[3])) -
                _max(int32(obj1[1]), int32(obj2[1]))
        );

        return uint32(x_overlap * y_overlap);
    }

    function _max(int32 a, int32 b) internal pure returns (int32) {
        return a >= b ? a : b;
    }

    function _min(int32 a, int32 b) internal pure returns (int32) {
        return a <= b ? a : b;
    }

    function _checkCommit(
        uint32[4] memory area,
        uint256 nonce,
        address buyer
    ) internal view {
        //check that area+ipfs+nonce hash = areaHash
        bytes32 areaHash = keccak256(abi.encodePacked(area, nonce, buyer));
        uint256 atBlock = commits[areaHash];
        require(atBlock > 0, "commit not set");
        require(atBlock < block.number, "commit at current block");
        if (areas.length == 0) return;
        //check that no areas bought after commit intersect
        for (uint256 i = areas.length - 1; i >= 0; i--) {
            //no need to check further back, only areas bought after commit
            if (areas[i].mintedAtBlock < atBlock) {
                break;
            }
            require(
                _isIntersecting(areas[i].rect, area) == false,
                "buy failed. intersection found"
            );
        }
    }

    function removeFraud(
        uint256[] calldata fraudIndex,
        uint256[] calldata originalIndex
    ) external {
        for (uint256 i = 0; i < fraudIndex.length; i++) {
            require(
                areas[fraudIndex[i]].mintedAtBlock >
                    areas[originalIndex[i]].mintedAtBlock &&
                    _isIntersecting(
                        areas[fraudIndex[i]].rect,
                        areas[originalIndex[i]].rect
                    ),
                "not newer or not overlapping"
            );
            delete areas[fraudIndex[i]];
            delete forSale[fraudIndex[i]];
            _burn(fraudIndex[i]);
        }
    }

    function setCreator(address _creator) external {
        require(creator == _msgSender(), "only creator can set new creator");
        creator = _creator;
    }

    function setVault(address _vault) external {
        require(creator == _msgSender(), "only creator can set new vault");
        vault = _vault;
    }

    function setFee(uint32 _fee) external {
        require(creator == _msgSender(), "only creator can set new fee");
        require(_fee < fee, "can only lower fee");
        fee = _fee;
    }

    function setBaseURI(string memory _baseuri) external {
        require(creator == _msgSender(), "only creator can set new baseURI");
        baseURI = _baseuri;
    }
}
