pragma solidity ^0.8.0;

import "./ERC1155Upgradeable.sol";
import "./SafeMath.sol";

contract Ac55IDOnDemand is Initializable, ERC1155Upgradeable { 

    struct NFT {
        uint256 NftId;
        address payable artist;
        uint256 price;
        uint256 no_of_tracks;
        uint256 tracks_sold;
    } 

    uint256 public nftId; 
    uint256 public platformFee; 

    mapping (uint256 => NFT) public nfts;
    mapping (uint256 => string) private track_link;
    mapping (uint256 => mapping(address => uint256)) public buyers;
    using SafeMath for uint;

    function initialize(string memory _baseurl, uint256 fee) public virtual initializer {
        __ERC1155_init(_baseurl);
        platformFee = fee;
    }
    
    function mintToken(uint256 price, uint256 _noOfTracks, string memory _tracklink, string memory newuri) external {
        address payable _artist = payable(msg.sender);  
        NFT memory newNFT = NFT(nftId,_artist,price,_noOfTracks, 0);
        track_link[nftId] = _tracklink;
        nfts[nftId] = newNFT;
        _mint(msg.sender, nftId, _noOfTracks, "");
        nftId++;
        _setURI(newuri);
    }

    function payment(uint256 _NftId) external payable {
        uint256 _amt = msg.value;
        NFT memory nft = nfts[_NftId]; 
        require(_amt >= nft.price, "Amount mismatched");
        require(nft.no_of_tracks > nft.tracks_sold, 'Sold out');
        address payable admin = payable(0x821fC28a7f932fCeDACd44627810379bA49D1356);
        admin.transfer(_amt);
        address _buyer_address = msg.sender; 
        nft.tracks_sold += 1;
        nfts[_NftId] = nft;
        buyers[_NftId][_buyer_address] = nft.tracks_sold;
    }

    function getTrackLink(uint256 _NftId, address buyer_addr) external view returns(string memory) {
        require(buyers[_NftId][buyer_addr]>0, "User didnt bought this track");
        return track_link[_NftId];
    }
}