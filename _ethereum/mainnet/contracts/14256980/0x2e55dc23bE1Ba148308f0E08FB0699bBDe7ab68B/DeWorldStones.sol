import "./StonesUtils.sol";
import "./IStoneChef.sol";

pragma solidity ^0.6.12;

contract DeWorldStones is ERC721, Ownable {

    //NFTs are movable? useful during distribution period (off by default)
    uint public transfersUnlockedAt;
    //governance chef location
    address public chefLoc;

    function claimedInfo() public view returns (uint[] memory) {
        return claimed;
    }

    constructor(address _chefLoc) public ERC721("DeWorldStones", "DEWORLDSTONES") {
        _setBaseURI("https://nft.deworld.org/describe/");
        chefLoc = _chefLoc;
    }

    function migrateNFTMetaData(string memory _base) public onlyOwner {
        _setBaseURI(_base);
    }

    function setTransfersUnlockedAt(uint _at) public onlyOwner {
        transfersUnlockedAt = _at;
    }

    function setChefLoc(address _chefLoc) public onlyOwner {
        chefLoc = _chefLoc;
    }

    uint[] public claimed;
    mapping(uint => bool) public isClaimed;

    function claimStone(uint _Id) public payable returns (uint256)
    {
        IStoneChef chef = IStoneChef(chefLoc);
        require(_Id < chef.maxId(), "id");
        require(isClaimed[_Id] == false, "claimed");

        uint requiredValue = chef.calcPrice(_Id);
        require(msg.value == requiredValue, "mispriced");

        _mint(msg.sender, _Id);
        claimed.push(_Id);
        isClaimed[_Id] = true;
        return _Id;
    }

    function calcPrice(uint256 _Id) public view returns (uint256) {
        IStoneChef chef = IStoneChef(chefLoc);
        return chef.calcPrice(_Id);
    }

    function claimETH() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    //lock transfers for 2 weeks from the moment of deployment
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override {
        require(transfersUnlockedAt < block.timestamp || _from == address(0), "distribution");
    }
}
