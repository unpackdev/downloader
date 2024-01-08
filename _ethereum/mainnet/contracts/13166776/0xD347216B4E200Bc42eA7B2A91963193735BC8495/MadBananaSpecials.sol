pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";


contract MadBananaSpecials is ERC721, Ownable {
    
    using SafeMath for uint256;

    bool public saleIsActive = false;

    bool public snapshotTaken = false;
    
    uint256 public baby_offset = 0;
    uint256 public baby_counter = 0;

    uint256 public peeled_offset = 500;
    uint256 public peeled_counter = 0;

    uint256 public golden_offset = 1000;
    uint256 public golden_counter = 0;

    uint256 public custom_offset = 1500;
    uint256 public custom_counter = 0;

    uint256 public extra_offset = 2000;
    uint256 public extra_counter = 0;

    IERC721Enumerable MBUtoken = IERC721Enumerable(0xC2a7167D321E194f6DB6b0Bf49162Da8B2B7eA36);

    address public extraCollectionContract;

    mapping(address => uint256) balances;
    mapping(address => bool) public rewardTaken;

    constructor() ERC721("Mad Banana Specials", "MBS") { }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setBalance(address _address, uint256 balance) public onlyOwner {
        balances[_address] = balance;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI) public onlyOwner {
            (tokenId, tokenURI);
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }
    
    function snapshot() public onlyOwner {
        for(uint256 i = 0; i < MBUtoken.totalSupply(); i++) {
            balances[MBUtoken.ownerOf(i)] += 1;
        }
        snapshotTaken = true;
    }

    function balanceOfAtSnapshot(address owner) public view virtual returns (uint256){
        require(owner != address(0), "ERC721: balance query for the zero address");
        require(snapshotTaken, "No Snapshot was taken");

        return balances[owner];
    }

    function mintReward() public {
        require(saleIsActive, "Sale must be active to mint Mad Bananas");
        require(snapshotTaken, "No Snapshot was taken");
        require(!rewardTaken[msg.sender], "Your reward was already minted");

        if(balances[msg.sender] >= 5){
            _safeMint(msg.sender, baby_offset + baby_counter);
            baby_counter += 1;
        }
        if(balances[msg.sender] >= 10){
            _safeMint(msg.sender, peeled_offset + peeled_counter);
            peeled_counter += 1;
        }
        if(balances[msg.sender] >= 20){
            _safeMint(msg.sender, golden_offset + golden_counter);
            golden_counter += 1;
        }
        if(balances[msg.sender] >= 50){
            _safeMint(msg.sender, custom_offset + custom_counter);
            custom_counter += 1;
        }

        rewardTaken[msg.sender] = true;
    }
    
    function setExtraCollectionContractAddress(address contractAddress) public onlyOwner {
        extraCollectionContract = contractAddress;
    }

    function mintExtraCollection() public {
        require(extraCollectionContract != address(0), "Extra Collection contract address need be set");

        ExtraCollection extraCollection = ExtraCollection(extraCollectionContract);

        require(extraCollection.isEligible(msg.sender), "You're not eligible to mint the extra collection");
        _safeMint(msg.sender, extra_offset + extra_counter);
        extra_counter += 1;
    }

    function burn(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(owner == msg.sender, "You must own the token in order to burn it");
        _burn(tokenId);
    }

}

interface ExtraCollection {
    function isEligible(address sender) external returns (bool);
}   
