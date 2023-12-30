pragma solidity ^0.4.26;

contract SuperRareMarketAuction {
    
    function currentBidDetailsOfToken(address _originContract, uint256 _tokenId) public view returns(uint256, address)
    {
        
    }
    
    function cancelBid(address _originContract, uint256 _tokenId) public
    {
        
    }
    
    function setRoyaltyFee(uint256 _percentage) public
    {
        
    }
    
    function setPrimarySaleFee(uint256 _percentage) public
    {
        
    }
    
    function setSalePrice(address _originContract, uint256 _tokenId, uint256 _amounta) public
    {
        
    }
    
    function renounceOwnership() public
    {
        
    }
    
    function owner() public view returns(address)
    {
        
    }
    
    function isOwner() public view returns(bool)
    {
        
    }
    
    function tokenPrice(address _originContract, uint256 _tokenId) public view returns(uint256)
    {
        
    }
    
    function setMarketplaceFee(uint256 _percentage) public
    {
        
    }
    
    function acceptBid(address _originContract, uint256 _tokenId) public
    {
        
    }
    
    function bid(uint256 _newBidAmount, address _originContract, uint256 _tokenId) public payable
    {
        
    }
    
    function buy(address _originContract, uint256 _tokenId) public payable
    {
        
    }
    
    function transferOwnership(address newOwner) public
    {
        
    }
    
    event Sold(address indexed _originContract, address indexed _buyer, address indexed _seller, uint256 _amount, uint256 _tokenId);
    event SetSalePrice(address indexed _originContract, uint256 _amount, uint256 _tokenId);
    event Bid(address indexed _originContract, address indexed _bidder, uint256 _amount, uint256 _tokenId);
    event AcceptBid(address indexed _originContract, address indexed _bidder, address indexed _seller, uint256 _amount, uint256 _tokenId);
    event CancelBid(address indexed _originContract, address indexed _bidder, uint256 _amount, uint256 _tokenId);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
}