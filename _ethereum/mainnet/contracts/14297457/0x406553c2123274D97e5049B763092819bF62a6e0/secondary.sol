pragma solidity >=0.7.0 <0.9.0;

import "./diverse.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract secondary is Ownable{
    diverse public Diverse;
    bytes32 root;
    mapping (address => bool) isclaimed;

    function mint(uint256 _maxMintAmount,bytes32[]memory proof)public {
        require(isclaimed[msg.sender] != true);
        require(_verify(_leaf(msg.sender), proof) != false, "Invalid merkle proof");
        Diverse.mintForAddress(_maxMintAmount,msg.sender);
        isclaimed[msg.sender]= true;
    }

    function WithDraw(address payable _Address)public payable onlyOwner{
         Diverse.withdraw(_Address);
     }

      function TransferOwnership(address _NewOwner)public onlyOwner{
       Diverse.transferOwnership(_NewOwner);
     }

     function addaddress(diverse _address)public onlyOwner{
         Diverse = _address;
     }

     function _leaf(address account)
    public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }

    function changeclaim(address _address,bool _state)public onlyOwner{
        isclaimed[_address]=_state;
    }

    function checkstate(address _address) public view returns(bool){
        return isclaimed[_address];
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    public view returns (bool)
    {
        return MerkleProof.verify(proof,root, leaf);
    }

    function addroot(bytes32 _root)public onlyOwner{
      root = _root;
    }

    function withdraw(address _address ) public onlyOwner {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(_address).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }


}