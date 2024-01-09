pragma solidity ^0.6.0;

import "./Governable.sol";


contract NFTIndexer is Governable {

    mapping (address => mapping(uint256 => uint256)) public NFT721Auction;

    mapping (address => mapping(uint256 => uint256)) public NFT721Fixswap;

    mapping (address => mapping(uint256 => mapping(address => uint256))) public NFT1155Auction;

    mapping (address => mapping(uint256 => mapping(address => uint256))) public NFT1155Fixswap;

    address public auction;
    address public fixswap;

    modifier onlyAuction() {
        require(msg.sender == auction || msg.sender == governor, "only auction");
        _;
    }

    modifier onlyFixswap() {
        require(msg.sender == fixswap || msg.sender == governor, "only fixswap");
        _;
    }

    function initialize(address _governor) public override initializer {
        super.initialize(_governor);
    }

    function setAuction(address _auction) external governance returns (bool) {
        auction = _auction;
    }

    function setFixswap(address _fixswap) external governance returns (bool) {
        fixswap = _fixswap;
    }

    function new721Auction(address _token, uint256 _tokenId, uint256 _poolId) public  onlyAuction {
        NFT721Auction[_token][_tokenId] = _poolId;
    }
    
    function new1155Auction(address _token, address _creator, uint256 _tokenId, uint256 _poolId) public  onlyAuction {
        NFT1155Auction[_token][_tokenId][_creator] = _poolId;
    }

    function new721Fixswap(address _token, uint256 _tokenId, uint256 _poolId) public  onlyFixswap {
        NFT721Fixswap[_token][_tokenId] = _poolId;
    }
    
    function new1155Fixswap(address _token, address _creator, uint256 _tokenId, uint256 _poolId) public onlyFixswap{
        NFT1155Fixswap[_token][_tokenId][_creator] = _poolId;
    }

    function del721Auction(address _token, uint256 _tokenId) public  onlyAuction {
        delete NFT721Auction[_token][_tokenId];
    }
    
    function del1155Auction(address _token, address _creator, uint256 _tokenId) public  onlyAuction {
        delete NFT1155Auction[_token][_tokenId][_creator];
    }

    function del721Fixswap(address _token, uint256 _tokenId) public  onlyFixswap {
        delete NFT721Fixswap[_token][_tokenId];
    }
    
    function del1155Fixswap(address _token, address _creator, uint256 _tokenId) public onlyFixswap{
        delete NFT1155Fixswap[_token][_tokenId][_creator];
    }

    function get721Auction(address _token, uint256 _tokenId) public view returns(uint256) {
        return NFT721Auction[_token][_tokenId];
    }

    function get721Fixswap(address _token, uint256 _tokenId) public view returns(uint256) {
        return NFT721Fixswap[_token][_tokenId];
    }

    function get1155Auction(address _token, address _creator, uint256 _tokenId) public view returns(uint256) {
        return NFT1155Auction[_token][_tokenId][_creator];
    }

    function get1155Fixswap(address _token, address _creator, uint256 _tokenId) public view returns(uint256) {
        return NFT1155Fixswap[_token][_tokenId][_creator];
    }
}
