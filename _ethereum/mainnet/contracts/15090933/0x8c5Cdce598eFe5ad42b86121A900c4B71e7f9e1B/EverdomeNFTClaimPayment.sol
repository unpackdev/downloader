pragma solidity ^0.8.0;
import "./ProofsVerifier.sol";
import "./Ownable.sol";
import "./IERC20.sol";

interface Mintable {
    function mint(address to, uint256 tokenId) external;
    function exists(uint256 id) external view returns(bool) ;
    function transferOwnership(address newOwner) external ;
}

contract EverdomeNFTClaimPayment is ProofsVerifier {

    bytes32 public root;
    address public token; 
    address public deployer;

    uint256 public lockTime;
    uint256 public price;
    int256 public totalSlots;
    bool public overriden=false;
    uint256 public lastAllowedMoment;
    uint256 public startTime;
    mapping(int256 => address) slotOwners;


    constructor(bytes32 _root, int256 _totalSlots, uint256 _price, 
    address _token, uint256 _startTime, uint256 _timeToAuction){
        root = _root;
        deployer = msg.sender;
        totalSlots = _totalSlots;
        price = _price;
        token = _token;
        startTime = _startTime;
        lastAllowedMoment = startTime + _timeToAuction;
    }

    function buySpot() payable public{
        require(msg.value == price,"bad-price");
        require(lastAllowedMoment>block.timestamp,"too-late");
        require(startTime<block.timestamp,"too-early");
        slotOwners[totalSlots] = msg.sender;
        emit SlotReserved(msg.sender, uint256(totalSlots));
        totalSlots--;
        require(totalSlots>0,"sold");
    }

    function transferTokenOwnership(address newOwner) public onlyOwner{
        Mintable(token).transferOwnership(newOwner);
    }

    function transferLocked() public {
        payable(owner()).transfer(address(this).balance);
    }
    
    function getNode(uint256 nft_id, int slot, int seed) public pure returns(bytes32) {
        return keccak256(abi.encode(nft_id,slot,seed));
    }

    function claimNFT(uint256 nft_id, int256 slot, int seed, bytes32[] calldata proof) public {
        require(slotOwners[slot]!=address(0), "not-sold");
        require(lastAllowedMoment<block.timestamp || totalSlots == 0,"too-early");
        bytes32 leaf = getNode(nft_id, slot, seed);
        require(verify(root, proof, leaf), "proof-incorrect");
        require(Mintable(token).exists(nft_id)==false,"already-minted");
        Mintable(token).mint(slotOwners[slot], nft_id);
    }

    event SlotReserved(address owner, uint256 slot);
}