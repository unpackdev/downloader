pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./MerkleProof.sol";

abstract contract IERC721 {
    function mint(address to) external virtual;
    function totalSupply() public view virtual returns(uint256);
}

contract ERC721Minter is Ownable {
    IERC721 public erc721;

    //used to verify whitelist user
    bytes32 public merkleRoot;
    uint256 public mintQuantity;
    uint256 public price;
    mapping(address => uint256) public claimed;

    constructor(IERC721 erc721_, bytes32 merkleRoot_) {
        erc721 = erc721_;

        merkleRoot = merkleRoot_;
        mintQuantity = 2500;
        price = 110000000000000000;
    }

    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function setNFT(IERC721 erc721_) public onlyOwner {
        erc721 = erc721_;
    }
    function setQuantity(uint256 newQ) public onlyOwner {
        mintQuantity = newQ;
    }


    function mint(bytes32[] calldata merkleProof_, uint256 quantity_) public payable{
        //requires that user has not already claimed
        require(msg.value >= price * quantity_,"Insuffient Funds Provided");
        require(erc721.totalSupply()+quantity_ <= 2500, "No More Pandas to be minted");

        require(claimed[msg.sender] + quantity_ <= mintQuantity, "Already claimed.");

        //requires that user is in whitelsit
        claimed[msg.sender] = claimed[msg.sender] + quantity_;

        for(uint256 i = 0; i < quantity_; i++){
            erc721.mint(msg.sender);
        }
    }

    function withdraw(address to) public onlyOwner {
        (bool sent, ) = to.call{value: address(this).balance}("");
        require(sent, "withdraw failed");
    }


}