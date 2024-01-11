// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";

 

// ██╗    ██╗██╗  ██╗ ██████╗     ██╗███████╗    ▄▄███▄▄· █████╗ ███╗   ███╗ ██████╗ ████████╗    ██████╗
// ██║    ██║██║  ██║██╔═══██╗    ██║██╔════╝    ██╔════╝██╔══██╗████╗ ████║██╔═══██╗╚══██╔══╝    ╚════██╗
// ██║ █╗ ██║███████║██║   ██║    ██║███████╗    ███████╗███████║██╔████╔██║██║   ██║   ██║         ▄███╔╝
// ██║███╗██║██╔══██║██║   ██║    ██║╚════██║    ╚════██║██╔══██║██║╚██╔╝██║██║   ██║   ██║         ▀▀══╝
// ╚███╔███╔╝██║  ██║╚██████╔╝    ██║███████║    ███████║██║  ██║██║ ╚═╝ ██║╚██████╔╝   ██║         ██╗
//  ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝╚══════╝    ╚═▀▀▀══╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝    ╚═╝         ╚═╝

/**
 * @title Don Rouch
 * WhoIsSamot - an 1155 contract for  0800 Don Rouch
 */
contract DonRouch is ERC1155Supply, Ownable , ReentrancyGuard{

    using Strings for string;

    struct itemData {
        uint256 maxSupply;
        uint256 maxToMint;
        uint256 maxPerWallet;
        uint256 initialSupply;
        uint256 price;
    }
    bool public saleIsActive = false;
    bool public claimIsActive = false;
    string public name;
    string public symbol;
    string public baseURI= "https://samotclub.mypinata.cloud/ipfs/QmQsoThoprBh6Gpbk8RiPjHxveoMBAfYPbrgLvs5DoaWvL/";

    mapping(uint256 => itemData) public idStats ; 


    constructor(
        string memory _uri,
        string memory _name,
        string memory _symbol
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
    }

    function uri(uint256 _id) override public view returns (string memory){
        require(exists(_id), "ERC1155: NONEXISTENT_TOKEN");
        return(
            string(abi.encodePacked(baseURI,Strings.toString(_id),".json"))
        );
    }

    function setBaseURI(string memory _baseURI) external onlyOwner{
        baseURI = _baseURI;
    }

    function setURI(string memory _newURI) public onlyOwner {
        _setURI(_newURI);
    }

    function setPrice(uint256 _price, uint256 _id) external onlyOwner {
        idStats[_id].price = _price;
    }
    function setMaxToMint(uint256 _maxToMint, uint256 _id) external onlyOwner {
        idStats[_id].maxToMint = _maxToMint;
    }

    function setMaxPerWallet(uint256 _maxPerWallet, uint256 _id) external onlyOwner {
        idStats[_id].maxPerWallet = _maxPerWallet;
    }

    function setMaxSupply(uint256 _maxSupply, uint256 _id) external onlyOwner {
        idStats[_id].maxSupply = _maxSupply;
    }


    function setInitialSupply(uint256 _initialSupply, uint256 _id) external onlyOwner {
        idStats[_id].initialSupply = _initialSupply;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipClaimState() public onlyOwner {
        claimIsActive = !claimIsActive;
    }

    // Price should be set up in Wei
    function createItem(uint256 _id, uint256 _maxPerWallet, uint256 _maxToMint,uint256 _price,uint256 _maxSupply) public onlyOwner{
        idStats[_id].maxPerWallet = _maxPerWallet;
        idStats[_id].maxToMint = _maxToMint;
        idStats[_id].price = _price;
        idStats[_id].maxSupply = _maxSupply;
    }

    function buyItem(uint256 _quantity,uint256 _id) external payable {
        require(saleIsActive, "Sale is not active.");
        require(
            totalSupply(_id) + _quantity <= idStats[_id].maxSupply,  
            "Minting limit reached."
        );
        require(msg.value >= idStats[_id].price * _quantity);
        require(_quantity > 0, "Quantity cannot be 0.");
        require(
                balanceOf(msg.sender,_id) + _quantity <= idStats[_id].maxPerWallet,
                "Exceeds wallet limit."
            );
        require(
                _quantity <= idStats[_id].maxToMint, 
                "Exceeds NFT per transaction limit."
            );
        _mint(msg.sender,_id,_quantity,"");
        totalSupply(_id) + _quantity;
    }

    function claimItem(uint256 _quantity,uint256 _id) external {
        require(claimIsActive, "Claim is not active.");
        require(
            totalSupply(_id) + _quantity <= idStats[_id].maxSupply,  
            "Minting limit reached."
        );
        require(_quantity > 0, "Quantity cannot be 0.");
        require(
                balanceOf(msg.sender,_id) + _quantity <= idStats[_id].maxPerWallet,
                "Exceeds wallet limit."
            );
        require(
                _quantity <= idStats[_id].maxToMint, 
                "Exceeds NFT per transaction limit."
            );
        _mint(msg.sender,_id,_quantity,"");
        totalSupply(_id) + _quantity;
    }

    function claimItems(uint256[] calldata _quantities,uint256[] calldata _ids) external {
        require(claimIsActive, "Claim is not active.");
        for(uint256 i=0;i<_ids.length;i++){
            require(totalSupply(_ids[i]) + _quantities[i] <= idStats[_ids[i]].maxSupply,   
            "Minting limit reached.");
            require(_quantities[i] > 0, "Quantity cannot be 0.");
            require(
                balanceOf(msg.sender,_ids[i]) + _quantities[i] <= idStats[_ids[i]].maxPerWallet,
                "Exceeds wallet limit."
            );
            require(
                _quantities[i] <= idStats[_ids[i]].maxToMint, 
                "Exceeds NFT per transaction limit."
            );
            totalSupply(_ids[i]) + _quantities[i];

        }
        _mintBatch(msg.sender,_ids,_quantities,"");
    }
    
    function reserveItem(uint256 _quantity,uint256 _id,address _address) external onlyOwner{
        _mint(_address,_id,_quantity,"");
    }

    function withdraw() external onlyOwner nonReentrant {
            (bool success, ) = msg.sender.call{value: address(this).balance}("");
            require(success, "Transfer failed."); 
    }
}
