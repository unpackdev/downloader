// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

pragma experimental ABIEncoderV2;
import "./ERC721.sol";


contract CardNFT is ERC721 {


    mapping(uint256 =>  string) internal idUriMap;
    uint256 fee;
    address owner;
    address payable receiver;

    event SendFee(
        address fromAddress,
        uint256 value
    );

    modifier onlyOwner() {
        require(msg.sender == owner,"must be owner");
        _;
    }

    constructor (string memory _name, string memory _symbol) 
    ERC721(_name, _symbol)
    {
        owner = msg.sender;
        receiver = payable(msg.sender);
    }

    /**
    * Custom accessor to create a unique token
    */
    function mint(
        address _to,
        uint256 _tokenId,
        string memory _tokenURI
    ) payable external
    {
        require(msg.value >= fee,"fee is not enough");

        receiver.transfer(msg.value);

        super._mint(_to, _tokenId);
        idUriMap[_tokenId] = _tokenURI;

        emit SendFee(msg.sender,msg.value);
    }


    /**
     * @dev tokenURI
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {

        return idUriMap[_tokenId];
    }

    /**
     * @dev setFee
     */
    function setFee(uint256 _fee) external  onlyOwner {

        fee = _fee;
    }

    /**
     * @dev getFee
     */
    function getFee() external view returns(uint256){

       return fee;
    }
  

    /**
     * @dev setReceiver
     */
    function setReceiver(address payable _receiver) external onlyOwner {

        receiver = _receiver;
    }

    /**
     * @dev getReceiver
     */
    function getReceiver() external view returns(address payable){

       return receiver;
    }

    function setOwner(address onwerAddress) external onlyOwner{

        owner = onwerAddress;
    }

    function getOwner()external view returns(address){
       return owner;
    }

}