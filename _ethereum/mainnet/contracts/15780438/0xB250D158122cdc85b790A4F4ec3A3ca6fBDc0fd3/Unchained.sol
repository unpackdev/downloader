// SPDX-License-Identifier: MIT

//@UnchainedAgency

/*
                                                                                                                                                                                                        
 ,ggg,         gg                                                                                         
dP""Y8a        88                          ,dPYb,                                                      8I 
Yb, `88        88                          IP'`Yb                                                      8I 
 `"  88        88                          I8  8I                  gg                                  8I 
     88        88                          I8  8'                  ""                                  8I 
     88        88   ,ggg,,ggg,     ,gggg,  I8 dPgg,     ,gggg,gg   gg    ,ggg,,ggg,    ,ggg,     ,gggg,8I 
     88        88  ,8" "8P" "8,   dP"  "Yb I8dP" "8I   dP"  "Y8I   88   ,8" "8P" "8,  i8" "8i   dP"  "Y8I 
     88        88  I8   8I   8I  i8'       I8P    I8  i8'    ,8I   88   I8   8I   8I  I8, ,8I  i8'    ,8I 
     Y8b,____,d88,,dP   8I   Yb,,d8,_    _,d8     I8,,d8,   ,d8b,_,88,_,dP   8I   Yb, `YbadP' ,d8,   ,d8b,
      "Y888888P"Y88P'   8I   `Y8P""Y8888PP88P     `Y8P"Y8888P"`Y88P""Y88P'   8I   `Y8888P"Y888P"Y8888P"`Y8
                                                                                                           
*/

pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract Unchained is ERC1155, Ownable {
    
    event Mint(address indexed to, uint256[] indexed tokenId);
    event Revoke(address indexed to, uint256[] indexed tokenId);

    bytes32 public whitelistMerkleRoot = 0x2839eddc1b8fac73603098dc4088d8b4cba36391ee82c27d1cfed1c33a57841f;
    string private tokenURI = "https://gateway.pinata.cloud/ipfs/QmQb1Av1eM6SQvCTtT7mFr5wdqtPkVuKEYm645fT85PGqt";
    uint256 public PRICE = 0.5 ether;
    
    bool public wlMintTime = false;
    bool public publicMintTime = false;

    constructor() ERC1155("Unchained Minter") { }

    function mint() public payable {
        
        require(publicMintTime, "It is not time to mint!");
        require(balanceOf(msg.sender, 0) == 0, "Already Holding Unchained Minting Pass");
        require(msg.value >= PRICE, "Not enough ether");

        _mint(msg.sender, 0, 1, "");

    }

    function whitelistMint(bytes32[] calldata _merkleProof) public payable {

            require(wlMintTime, "It is not time to mint!");
            require(balanceOf(msg.sender, 0) == 0, "Already Holding Unchained Minting Pass");
            require(msg.value >= PRICE, "Not enough ether");

            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf), "Invalid Merkle Proof");

             _mint(msg.sender, 0, 1, "");
    }

    function ownerMint(address to) public onlyOwner {
        
        require(balanceOf(to, 0) == 0, "Already Holding Unchained Minting Pass");

        _mint(to, 0, 1, "");    
    }

    function revoke(address wallet) external onlyOwner {
        _burn(wallet, 0, balanceOf(wallet, 0));
    }


    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override virtual {

    require(from == address(0) || to == address(0), "Not allowed to transfer token");

    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override virtual {

        if (from == address(0)) {
            emit Mint(to, ids);
        } else if (to == address(0)) {
            emit Revoke(to, ids);
        }

    }

    function uri(uint256 _id) override public view returns (string memory) {
        return(tokenURI);
    }

    function flipState() public onlyOwner {

        publicMintTime = !publicMintTime;

    }

     function flipStateWL() public onlyOwner {

        wlMintTime = !wlMintTime;

    }

    function setTokenURI(string memory _uri) public onlyOwner {

        tokenURI = _uri;

    }

    function setPrice(uint256 _price) public onlyOwner {

        PRICE = _price;

    }

    function withdraw() external onlyOwner {

        uint256 balance = address(this).balance;

        Address.sendValue(payable(owner()), balance);
    }


}