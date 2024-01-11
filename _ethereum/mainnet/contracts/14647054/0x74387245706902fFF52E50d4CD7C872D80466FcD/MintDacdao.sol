pragma solidity ^0.8.1;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Initializable.sol";
import "./Permission.sol";
import "./IdacDao.sol";



/**
 * This is an Dacdao contract implementation of NFToken with metadata extension
 */
contract MintDacdao is Ownable,Initializable,Permission
{
     using Counters for Counters.Counter;
     Counters.Counter private _tokenIdTracker;
     using SafeMath for uint256; 
     bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IdacDao dacDaoToken;
   
    uint256 donateUint = 5*(10**16);
    
    address treasuryAddress;
    uint8 period = 1;
    uint256 total = 222;
    uint256 sq = 0;

    mapping(address => uint8) mintWhilte;
    address[] airdropList;
    mapping(address => uint8) addressMap;

    bool isPublicMint = false;
    bool isPublicSale = false;
    event mintEvt(address indexed,uint256 tokenId);
    event mintCardEvt(address indexed,uint256 tokenId);
    constructor(){
        _tokenIdTracker.increment();
        treasuryAddress = 0xf0f6036559Afa87214E3103e781DB47aAB7F7082;
        initWhilte();
    }

    function init(IdacDao _idacDao) public onlyOwner {
        dacDaoToken = _idacDao;

        initialized = true;
    }

    function setDonateUint(uint256 uintvalue) public onlyRole(MINTER_ROLE){
        donateUint = uintvalue;
    }

    function setTotal(uint256 _total) public onlyRole(MINTER_ROLE){
        total = _total;
    }

    function getSq() public view returns(uint256){
        return sq;
    }

    function setSq(uint256 _sq) public onlyRole(MINTER_ROLE) {
        sq = _sq;
    }

    function getPeriod() public view returns(uint256){
        return period;
    }


    function setPeriod(uint8 _period) public onlyRole(MINTER_ROLE) {
        period = _period;
    }
    
    function setIsPublicMint(bool _isPublicMint) public onlyRole(MINTER_ROLE) {
        isPublicMint = _isPublicMint;
    }
    
    function setIsPublicSale(bool _isPublicSale) public onlyRole(MINTER_ROLE) {
        isPublicSale = _isPublicSale;
    }

    function decrementId(uint256 _value) public onlyRole(MINTER_ROLE){

         for(uint256 i =0;i<_value;i++){
            _tokenIdTracker.decrement();
         }
    }

    function currentId() public  view returns(uint256){
        return _tokenIdTracker.current();
    }

    function addId(uint256 _value) public onlyRole(MINTER_ROLE){

         for(uint256 i =0;i<_value;i++){
             _tokenIdTracker.increment();
         }
    }
    
    function queryCount() public view returns(uint8){
        return mintWhilte[msg.sender] ;
    }

    function getCount(address _addr) public view returns(uint8){
        return mintWhilte[_addr] ;
    }

    function setWhilte(address[] memory addrs,uint8[] memory counts) public onlyRole(MINTER_ROLE){
        require(addrs.length == counts.length,"params error");
        for (uint256 index = 0; index < addrs.length; index++) {
            mintWhilte[addrs[index]] = counts[index];
            if(addressMap[addrs[index]]==0){
                addressMap[addrs[index]]==1;
                airdropList.push(addrs[index]);
            }
        }
    }

    function airdropToUser(address[] memory addrs,uint8[] memory counts) public  onlyRole(MINTER_ROLE){
         require(addrs.length == counts.length,"params error");
         
          for (uint256 index = 0; index < addrs.length; index++) {
              uint8 number = counts[index];

              if(number>0){
                    for (uint256 i = 0; i < uint256(number); i++) {
                        uint256 tokenId = _tokenIdTracker.current();
                        _tokenIdTracker.increment();
                        dacDaoToken.mintNFT(addrs[index], tokenId,period);
                        sq ++;
                    }
              }
          }
    }

    function initWhilte() private{
        //mintWhilte[0x6a9F14b8a95c65b65D4dff7659274Bf77D9f0A96]=2;
    }

    function airdrop() public  onlyRole(MINTER_ROLE){

        for (uint256 index = 0; index < airdropList.length; index++) {
            uint8 number = mintWhilte[airdropList[index]];
            if(number>0){

                for (uint256 i = 0; i < uint256(number); i++) {
                    uint256 tokenId = _tokenIdTracker.current();
                    _tokenIdTracker.increment();
                    dacDaoToken.mintNFT(airdropList[index], tokenId,period);
                }
                mintWhilte[airdropList[index]] = 0;
            }
            
        }
    }

    function mint() public  payable needInit{

        require(isPublicMint==true,"not start");
        require(mintWhilte[msg.sender]>0,"Not qualified");
        uint8 number = mintWhilte[msg.sender];
        uint256 totalAMount = uint256(number).mul(donateUint);
        require(msg.value>=totalAMount,"amount not enough");
        
        if(number>0){

            for (uint256 i = 0; i < uint256(number); i++) {
                uint256 tokenId = _tokenIdTracker.current();
                _tokenIdTracker.increment();
                dacDaoToken.mintNFT(msg.sender, tokenId,period);
                sq ++;
            }
            mintWhilte[msg.sender] = 0;
            
        }

         payable(treasuryAddress).transfer(msg.value);
    }

    function publicSale() public  payable needInit{

        require(isPublicSale==true,"not start");
        require(msg.value>=donateUint,"amount not enough");
        
        uint256 number = msg.value.div(donateUint);

       if(number>0){
            for (uint256 i = 0; i < number; i++) {
                uint256 tokenId = _tokenIdTracker.current();
                _tokenIdTracker.increment();
                dacDaoToken.mintNFT(msg.sender, tokenId,period);
            }
        }

         payable(treasuryAddress).transfer(msg.value);
    }
  
    receive() external payable{
        require(1==2,"can't");
    }

     function setTreasuryAddress(address _treasuryAddress) public onlyOwner{
        treasuryAddress = _treasuryAddress;
    }
}
