pragma solidity ^0.8.0;

import "./IRedlionStudios.sol";
import "./Ownable.sol";
import "./BitMaps.sol";
import "./MerkleProof.sol";


interface ERC1155 {
    function burn(address _owner, uint256 _id, uint256 _value) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}

contract RedlionStudiosMinter is Ownable {

    using BitMaps for BitMaps.BitMap;

    struct Sale {
        uint128 onSale;
        uint128 price;
        bytes32 merkleRoot;
    }

    IRedlionStudios public studios;

    uint public limitPerBuy = 5;

    mapping (uint => Sale) public sales; // publication => sale mapping
    mapping (address => BitMaps.BitMap) private _claimedAirdrop;

    constructor(address _studios) {
        studios = IRedlionStudios(_studios);
    }

    function withdraw(address recipient) onlyOwner public {
        uint amount = address(this).balance;
        payable(recipient).transfer(amount);
    }

    function setOnSale(uint256 publication, uint128 onSale) onlyOwner public {
        sales[publication].onSale = onSale;
    }

    function setMintingPrice(uint256 publication, uint128 price) onlyOwner public {
        sales[publication].price = price;
    }

    function setMerkleAirdrop(uint256 publication, bytes32 root) onlyOwner public {
        sales[publication].merkleRoot = root;
    }

    function createNewSale(uint256 publication, uint128 onSale, uint128 price, bytes32 root) onlyOwner public {
        sales[publication] = Sale(onSale, price, root);
    }

    function setLimitPerBuy(uint limit) onlyOwner public {
        limitPerBuy = limit;
    }

    function claim(uint256 publication, bytes32[] calldata proof, uint256 amount) public {
        require(!_claimedAirdrop[msg.sender].get(publication), "ALREADY CLAIMED FOR PUBLICATION");
        _claimedAirdrop[msg.sender].set(publication);
        require(MerkleProof.verify(proof, sales[publication].merkleRoot, keccak256(abi.encodePacked(msg.sender, amount))), "INVALID PROOF");
        studios.mint(publication, uint128(amount), msg.sender);
    }
    
    function purchase(uint publication, uint128 amount) public payable {
        require(msg.value == sales[publication].price * amount, "INCORRECT MSG.VALUE");
        require(amount <= limitPerBuy, "OVER LIMIT");
        sales[publication].onSale -= amount;
        studios.mint(publication, amount, msg.sender);
    }

    function mintGenesis() public {
        ERC1155 rewards = ERC1155(0x0Aa3850C4e084402D68F47b0209f222041093915);
        uint256 balance0 = rewards.balanceOf(msg.sender, 10003);
        uint256 balance1 = rewards.balanceOf(msg.sender, 10002);
        require(balance0 > 0 || balance1 > 0, "Nothing to burn");
        //burn token in user's stead
        if (balance0 > 0) rewards.burn(msg.sender, 10003, balance0);
        if (balance1 > 0) rewards.burn(msg.sender, 10002, balance1);
        studios.mint(0, uint128(balance0+balance1), msg.sender);

    }

    function isAirdropClaimed(address user, uint publication) public view returns (bool) {
        return _claimedAirdrop[user].get(publication);
    }
}