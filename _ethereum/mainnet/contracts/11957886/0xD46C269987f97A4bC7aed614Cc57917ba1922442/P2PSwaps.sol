pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC1155Holder.sol";
import "./ERC721Holder.sol";
import "./EnumerableSet.sol";

import "./IERC721.sol";
import "./IERC1155.sol";

contract P2PMarket is Ownable, ERC1155Holder, ERC721Holder {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Swap {
        address nftAddress;
        uint256 tokenId;
        address swapper;
        uint256 nftType;
    }

    uint256 public swapId = 1;
    mapping(address => EnumerableSet.UintSet) private _swap;
    mapping(uint256 => EnumerableSet.UintSet) private _acceptedIdsForSwap;
    mapping(uint256 => Swap) internal swapIdToSwap;

    constructor() public {}

    function createSwap(
        uint256[] calldata _acceptIds,
        uint256 _tokenId,
        address _nftAddress,
        uint256 _nftType
    ) external {
        if (_nftType == 721) {
            require(
                IERC721(_nftAddress).ownerOf(_tokenId) == msg.sender,
                "!owner"
            );
        } else if (_nftType == 1155) {
            require(
                IERC1155(_nftAddress).balanceOf(msg.sender, _tokenId) >= 1,
                "!owner"
            );
        }

        swapIdToSwap[swapId] = Swap(
            _nftAddress,
            _tokenId,
            msg.sender,
            _nftType
        );

        // add acceptedids
        for (uint256 i = 0; i < _acceptIds.length; i++) {
            _acceptedIdsForSwap[swapId].add(_acceptIds[i]);
        }

        _swap[msg.sender].add(swapId);

        swapId++;
    }

    // need to do further checks but this is proof of concept
    function swap(uint256 _swapId, uint256 _inId) external {
        Swap storage swap = swapIdToSwap[_swapId];

        // make sure this swap is for an id the user actually wants.
        require(_acceptedIdsForSwap[_swapId].contains(_inId), "!forbidden");

        //send nft to craetor of swapper
        transferNft(
            swap.nftAddress,
            swap.nftType,
            msg.sender,
            swap.swapper,
            _inId
        );

        //send nft to person execuing swap()
        transferNft(
            swap.nftAddress,
            swap.nftType,
            swap.swapper,
            msg.sender,
            swap.tokenId
        );

        _swap[swap.swapper].remove(_swapId);

        delete swapIdToSwap[_swapId];
    }

    // helper to do transfers
    function transferNft(
        address nftAddress,
        uint256 nftType,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        if (nftType == 721) {
            IERC721(nftAddress).safeTransferFrom(_from, _to, _tokenId);
        } else if (nftType == 1155) {
            IERC1155(nftAddress).safeTransferFrom(_from, _to, _tokenId, 1, "");
        }
    }

    // Helpers to get swaps by users
    function swapsByAddress(address _swapper) public view returns (uint256) {
        return _swap[_swapper].length();
    }

    function swapsOfAddressByIndex(address _swapper, uint256 index)
        public
        view
        returns (uint256)
    {
        return _swap[_swapper].at(index);
    }

   
}
