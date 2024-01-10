pragma solidity >=0.7.0 <0.9.0;

import "./diverse.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract secondary is Ownable{
    diverse public Diverse;
    bytes32 root;
    mapping(address => uint256) public addressMintedBalance;

    uint256 public maxMintAmount = 1;

    function claim(uint256 _MintAmount,bytes32[]memory proof)public {
        require(Diverse.Totalminted() + _MintAmount <= supply(), "Max premint supply exceeded!");
        require(_verify(_leaf(msg.sender), proof) != false, "Invalid merkle proof");

        uint256 ownerMintedCount = addressMintedBalance[msg.sender];
        require(ownerMintedCount + _MintAmount <= maxMintAmount, "max NFT per address exceeded");

        mintloop(_MintAmount,msg.sender);
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

    function supply()public view returns(uint256){
        return Diverse.premintSupply();
    }


    function setmaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
    }


    function _verify(bytes32 leaf, bytes32[] memory proof)
    public view returns (bool)
    {
        return MerkleProof.verify(proof,root, leaf);
    }

    function addroot(bytes32 _root)public onlyOwner{
      root = _root;
    }

    function reveal(bool _state)public onlyOwner{
        Diverse.setRevealed(_state);
    }

    function mintloop(uint256 _maxMintAmount,address _reciver)internal {
        addressMintedBalance[msg.sender]++;
        Diverse.mintForAddress(_maxMintAmount,_reciver);
    }

    function SetUriPrefix(string memory _uriPrefix) public onlyOwner {
     Diverse.setUriPrefix(_uriPrefix);
    }

    function SetPaused(bool _state) public onlyOwner {
     Diverse.setPaused(_state);
    }

     function SetpreMintsupply(uint256 _MaxMintAmount) public onlyOwner {
     Diverse.setpreMintsupply(_MaxMintAmount);
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