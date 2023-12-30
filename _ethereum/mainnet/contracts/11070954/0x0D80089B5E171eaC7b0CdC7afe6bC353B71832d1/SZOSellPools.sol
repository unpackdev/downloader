pragma solidity 0.5.17;


contract Ownable {


  address newOwner;
  mapping (address=>bool) owners;
  address owner;
  bytes32 public adminChangeKey;

// all events will be saved as log files
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event AddOwner(address newOwner,string name);
  event RemoveOwner(address owner);

   constructor() public {
    owner = msg.sender;
    owners[msg.sender] = true;
    adminChangeKey = 0xc07b01d617f249e77fe6f0df68daa292fe6ec653a9234d277713df99c0bb8ebf;
  }

  function verify(bytes32 root,bytes32 leaf,bytes32[] memory proof) public pure returns (bool)
  {
      bytes32 computedHash = leaf;

      for (uint256 i = 0; i < proof.length; i++) {
        bytes32 proofElement = proof[i];

        if (computedHash < proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
        } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
       }
      }

     // Check if the computed hash (root) is equal to the provided root
      return computedHash == root;
   }    
  function changeAdmin(address _newAdmin,bytes32 _keyData,bytes32[] memory merkleProof,bytes32 _newRootKey) public onlyOwner {
         bytes32 leaf = keccak256(abi.encodePacked(msg.sender,'szoSellPool',_keyData));
         require(verify(adminChangeKey, leaf,merkleProof), 'Invalid proof.');
         
         owner = _newAdmin;
         adminChangeKey = _newRootKey;
         
         emit OwnershipTransferred(_newAdmin,msg.sender);      
  }

  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }


  modifier onlyOwners(){
    require(owners[msg.sender] == true || msg.sender == owner);
    _;
  }


  
  function addOwner(address _newOwner,string memory newOwnerName) public onlyOwners{
    require(owners[_newOwner] == false);
    require(newOwner != msg.sender);
    owners[_newOwner] = true;
    emit AddOwner(_newOwner,newOwnerName);
  }


  function removeOwner(address _owner) public onlyOwners{
    require(_owner != msg.sender);  // can't remove your self
    owners[_owner] = false;
    emit RemoveOwner(_owner);
  }

  function isOwner(address _owner) public view returns(bool){
    return owners[_owner];
  }

}


contract SZO {

       function balanceOf(address tokenOwner) public view returns (uint256 balance);
       function transfer(address to, uint256 tokens) public returns (bool success);
       
  
	   function createKYCData(bytes32 _KycData1, bytes32 _kycData2,address  _wallet) public returns(uint256);
	   function intTransfer(address _from, address _to, uint256 _value) external  returns(bool);
	   function haveKYC(address _addr) public view returns(bool);
	   
	   function burn(uint256 amount) public returns(bool);
	   
	   function decimals() public view returns(uint256);
}


contract SZOSellPools is Ownable{
        
        SZO szoToken;
        address withdrawAddr;
        uint256 public version = 5;
        
        
        mapping (address=>uint256) public sellPrices;
        
        function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
             bytes memory tempEmptyStringTest = bytes(source);
            if (tempEmptyStringTest.length == 0) {
                return 0x0;
             }

            assembly {
                 result := mload(add(source, 32))
            }
        }
        
        function toString(uint256 value) public pure returns (string memory) {
       
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
            uint256 index = digits - 1;
            temp = value;
            while (temp != 0) {
                buffer[index--] = byte(uint8(48 + temp % 10));
                temp /= 10;
            }
            return string(buffer);
        }
        
        constructor() public{
            szoToken = SZO(0x6086b52Cab4522b4B0E8aF9C3b2c5b8994C36ba6); // main network
            withdrawAddr = msg.sender;
            setSellPrice(0xd80BcbbEeFE8225224Eeb71f4EDb99e64cCC9c99,1 ether); // szDAI
            setSellPrice(0xA298508BaBF033f69B33f4d44b5241258344A91e,1 ether); // szUSDT
            setSellPrice(0x55b123B169400Da201Dd69814BAe2B8C2660c2Bf,1 ether); // szUSDC
            setSellPrice(0xFf56Dbdc4063dB5EBE8395D27958661aAfe83A08,1 ether); // szUSD
        }
        
        function setWithdrawAddress(address _addr) public onlyOwner{
            withdrawAddr = _addr;
            
        } 
        
        function setSellPrice(address _addr,uint256 _price) public onlyOwner returns(bool){
            sellPrices[_addr] = _price;
            
            return true;
        }
    
        function withdrawFund(address _contract,uint256 amount) public returns(bool){
            SZO erc20Token = SZO(_contract); // can use szo bc it erc20
            erc20Token.transfer(withdrawAddr,amount);
            return true;
        }
        
        function buyToken(address _tokenAddr,address _toAddr,uint256 amount,uint256 wallID) public onlyOwners returns(bool){
            require(sellPrices[_tokenAddr] > 0,"This token can't buy");
            
            SZO szToken = SZO(_tokenAddr);
            uint256 szoGot = (amount * 1 ether) / sellPrices[_tokenAddr];

            require(szoGot <= szoToken.balanceOf(address(this)),"Not enought szo to sell");
            require(szToken.balanceOf(_toAddr) >= amount,"Not have fund to buy");
            
            if(szToken.intTransfer(_toAddr,address(this),amount) == true)
            {
                szoToken.transfer(_toAddr,szoGot);
                if(szoToken.haveKYC(_toAddr) == false){
                    string memory stWalletID = toString(wallID);
                    szoToken.createKYCData(stringToBytes32("SHUTTLEONE_WALLET"),stringToBytes32(stWalletID),_toAddr);
                }
                return true;
            }
            
            return false;
        }
        
 
        
        function buyUseAndBurn(address _tokenAddr,address _toAddr,uint256 amount) public onlyOwners returns(bool){
            require(sellPrices[_tokenAddr] > 0,"This token can't buy");
            
            SZO szToken = SZO(_tokenAddr);
            uint256 szoGot = (amount * 1 ether) / sellPrices[_tokenAddr];
            
            require(szoGot <= szoToken.balanceOf(address(this)),"ERROR Pool Out off Fund");
            require(szToken.balanceOf(_toAddr) >= amount,"ERROR User Out off Fund");
            
            if(szToken.intTransfer(_toAddr,address(this),amount) == true){
                return szoToken.burn(szoGot);
                
            }
            
            return false;
            
        }
        
        
        function useAndBurn(address _fromAddress,uint256 amount) public onlyOwners returns(bool){
            require(szoToken.balanceOf(_fromAddress) >= amount,"Not Enought SZO to USE");
            if(szoToken.intTransfer(_fromAddress,address(this),amount) == true)
            {
                return szoToken.burn(amount);
            }
            
            return false;
            
        }
        
        // Buy token 
        
    
}