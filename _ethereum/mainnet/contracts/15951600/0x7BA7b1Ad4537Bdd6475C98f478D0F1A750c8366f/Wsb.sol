// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ECDSA.sol";
import "./ERC1155Supply.sol";

contract Wsb is ERC1155Supply, Ownable{
    uint256 public WSB_SUPPLY = 50;

    uint256 public constant WSB = 0;

    uint256 public WSB_PRICE = 0.035 ether;

    uint256 public WSB_LIMIT = 1;

    //Create Setters for status
    bool public IS_MINT_ACTIVE = false;

    mapping(address => uint256) addressBlockBought;
    mapping (address => uint256) public mintedWSB;

    string private _baseUri;

    address public constant ADDRESS_2 = 0xc9b5553910bA47719e0202fF9F617B8BE06b3A09; //ROYAL LABS

    constructor() ERC1155("https://api.w3bmint.xyz/api/tokens/636d2273f92342a07ab3cfb7") {
        _mint(msg.sender, WSB, 5, "");
    }

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(IS_MINT_ACTIVE, "RUBY_MINT_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseUri, Strings.toString(_id)));
    }

    // Function for winter
    function mintPublic(address _owner) external isSecured(2) payable{
        require(1 + totalSupply(WSB) <= WSB_SUPPLY,"NOT_ENOUGH_PRESALE_SUPPLY");
        require(mintedWSB[msg.sender] + 1 <= WSB_LIMIT,"MINTED_RUBY_ALREADY");

        require(msg.value == WSB_PRICE * 1, "WRONG_ETH_VALUE");
        addressBlockBought[msg.sender] = block.timestamp;
        mintedWSB[msg.sender] += 1;

        _mint(_owner, WSB, 1, "");
    }

    // Function for crypto mint
    function mintCrypto() external isSecured(2) payable{
        require(1 + totalSupply(WSB) <= WSB_SUPPLY,"NOT_ENOUGH_PRESALE_SUPPLY");
        require(mintedWSB[msg.sender] + 1 <= WSB_LIMIT,"MINTED_RUBY_ALREADY");

        require(msg.value == WSB_PRICE * 1, "WRONG_ETH_VALUE");
        addressBlockBought[msg.sender] = block.timestamp;
        mintedWSB[msg.sender] += 1;

        _mint(msg.sender, WSB, 1, "");
    }

    // Base URI
    function setBaseURI(string calldata URI) external onlyOwner {
        _baseUri = URI;
    }

    // Ruby's WL status
    function setSaleStatus() external onlyOwner {
        IS_MINT_ACTIVE = !IS_MINT_ACTIVE;
    }

    function setPrice(uint256 _price) external onlyOwner {
      WSB_PRICE = _price;
    }

    function setSupply(uint256 _supply) external onlyOwner {
      WSB_SUPPLY = _supply;
    }

    function setLimit(uint256 _limit) external onlyOwner {
      WSB_LIMIT = _limit;
    }
    //Essential

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(ADDRESS_2).transfer((balance * 1500) / 10000);
        payable(msg.sender).transfer(address(this).balance);
    }
}