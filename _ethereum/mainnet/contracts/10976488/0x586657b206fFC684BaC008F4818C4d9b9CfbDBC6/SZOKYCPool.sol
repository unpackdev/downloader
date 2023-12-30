pragma solidity 0.5.17;

contract Permissions {

  mapping (address=>bool) public permits;

// all events will be saved as log files
  event AddPermit(address _addr);
  event RemovePermit(address _addr);

  constructor() public {
    permits[msg.sender] = true;
  }

  
  modifier onlyPermits(){
    require(permits[msg.sender] == true);
    _;
  }

  function isPermit(address _addr) public view returns(bool){
    return permits[_addr];
  }

  function addPermit(address _addr) public onlyPermits{
    require(permits[_addr] == false);
    permits[_addr] = true;
    emit AddPermit(_addr);
  }



  function removePermit(address _addr) public onlyPermits{
    require(_addr != msg.sender);
    permits[_addr] = false;
    emit RemovePermit(_addr);
  }
  


}

contract SZO {
	   
       function haveKYC(address _addr) public view returns(bool);
	   function createKYCData(bytes32 _KycData1, bytes32 _kycData2,address  _wallet) public returns(uint256);
	   function getKYCData(address _wallet) public view returns(bytes32 _data1,bytes32 _data2);
}




// for end user that already kyc and want to kyc more address
contract SZOKYCPool is Permissions {
    
    event MakeKYC(address indexed _addr);
    event MakePartnerKYC(address indexed _addr);

    bytes32 data2NoKYC;
    bytes32 data2Pools;
//    bytes32 public merkleRoot;
    
    
    SZO szoToken;
    // Onwer can kyc more address. but more address can't kyc to other address
    mapping(address=>bool) public extendedKYC;
    mapping(address=>bytes32) partnerData1s;
    mapping(address=>bool) public partnerAllows;
    mapping(bytes32=>bool) public merkleRoot;
    
    constructor() public {
        szoToken = SZO(0x6086b52Cab4522b4B0E8aF9C3b2c5b8994C36ba6); // MAINNET
        data2NoKYC = stringToBytes32("NOFULLKYC");
        data2Pools = stringToBytes32("NO ENCODE");
    }
    
     function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
             bytes memory tempEmptyStringTest = bytes(source);
            if (tempEmptyStringTest.length == 0) {
                return 0x0;
             }

            assembly {
                 result := mload(add(source, 32))
            }
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
    
    function addMerkleRoot(bytes32 _newRoot) public onlyPermits{
        merkleRoot[_newRoot] = true;
    }
    
    function updatePartnerKYC(bytes32 _data1,address _addr) public onlyPermits{
        require(checkKYC(_addr) == true,"This Partner Not KYC");
        
        partnerData1s[_addr] = _data1;
        partnerAllows[_addr] = true;
        
        emit MakePartnerKYC(_addr);
        
    }
    
    function disablePartnerKYC(address _addr) public onlyPermits{
        partnerAllows[_addr] = false;
    }
    
    function checkKYC(address _addr) public view returns(bool){
        return szoToken.haveKYC(_addr);
    }
    
    // 1 End User Call this function by them self
    
    function kycData(address _addr,bytes32 _data1,bytes32 _data2,bytes32[] memory merkleProof,bytes32 root) public{
        require(checkKYC(_addr) == false,"This Address Already KYC");
        require(merkleRoot[root] == true,"This is not ROOT KEY");
        bytes32 leaf = keccak256(abi.encodePacked(_addr, _data1, _data2));
        
        require(verify(root, leaf,merkleProof), 'Invalid proof.');
        
        szoToken.createKYCData(_data1,_data2,_addr);
        
        emit MakeKYC(_addr);
        
    }
    
    // 2 End user kyc other address by them self
    
    function addMoreKYCAddress(address _newAddress) public returns(bool){
        require(szoToken.haveKYC(_newAddress) == false,"This address already KYC");
        require(szoToken.haveKYC(msg.sender) == true,"Owner Address Not KYC");
        require(extendedKYC[msg.sender] == false,"This Addres KYC with extendedFunction can't KYC");
        
        bytes32 data1;
        bytes32 data2;
       
        
        (data1,data2) = szoToken.getKYCData(msg.sender);
        require(data2 != data2NoKYC,"YOUR ADDRESS NOT FULL KYC FOR KYC OTHER");
        require(data2 != data2Pools,"REWARD ADDRESS CAN NOT KYC");
        extendedKYC[_newAddress] = true;
        
        
        szoToken.createKYCData(data1,data2,_newAddress);

        return true;
        
    }
    
    // 3 Partner KYC member by them self
    function partnerKYC(address _kycAddr,bytes32 _data2) public returns(bool){
        require(checkKYC(_kycAddr) == false,"This Address Already KYC");
        require(partnerAllows[msg.sender] == true,"This Partner not allow to KYC");
        
        szoToken.createKYCData(partnerData1s[msg.sender],_data2,_kycAddr);
        emit MakeKYC(_kycAddr);
        return true;
    }
    
}