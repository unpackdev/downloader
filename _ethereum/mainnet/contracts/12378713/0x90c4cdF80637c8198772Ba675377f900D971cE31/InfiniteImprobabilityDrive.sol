// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

contract InfiniteImprobabilityDrive is ERC721Enumerable {
    uint256 public ethPrice;
    string private _tURI;
  
    address  payable owner;
    address  public contractAddr;

    modifier restricted() {
        // only owner can change
        require(msg.sender == owner,"Sender is not the creator!");
         _;
    }

    modifier contractValidate() {
        // only owner can change
        require(msg.sender == contractAddr,"Not the right contract!");
            _;
    }
  
  constructor (string memory name_, string memory symbol_, uint256 _ethPrice, string memory _URI) public 
        ERC721(name_, symbol_)
    {
        owner =  payable(msg.sender);
        ethPrice = _ethPrice;
         _tURI = _URI;
    }

    function setContractAddr(address _cAddr)  external restricted{
        contractAddr = _cAddr;
    }

    function setOwnertAddr(address payable _owner)  external restricted{
        owner = _owner;
    }

     function setEthPrice(uint256 _ethPrice)  external restricted{
        ethPrice = _ethPrice;
    }

    function setBaseURI(string memory _URI)  external restricted{
        _tURI = _URI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tURI;
    }

    function mintWithContract(address _sender) external  contractValidate{
        _mint(_sender, totalSupply()+1);
    }

}