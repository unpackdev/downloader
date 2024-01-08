pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./SafeMath.sol";


interface IWorldOfFreight {
    function ownerOf(uint256 tokenId) external view returns(address);
    function mintedcount() external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function mintItems(address to, uint256 amount) external;
}

interface IWofToken {
    function burn(address _from, uint256 _amount) external;
    function balanceOf(address _address) external view  returns (uint256);
}

contract GarageContract {
    using SafeMath for uint256;
    address private owner;
    bool public mintNew = true; 
    uint256 public junkyardPrice = 5000 ether;
    mapping(uint256 => UpgradePack) public upgrades;

    event Upgrade(address indexed _from, uint256 _upgradeId, uint256 _tokenId);
    event JunkYard(address indexed _from, uint256 _tokenId, bool mintedNew);

    struct UpgradePack {
        uint256 id;
        uint256 cost;
    }

    IWorldOfFreight public nftContract;
    IWofToken public wofToken;

    constructor (address _wof, address _token) {
        owner = msg.sender;
		nftContract = IWorldOfFreight(_wof);
        wofToken = IWofToken(_token);
    }

    function setTokenContract(address _address) public  {
        require(msg.sender == owner, 'Not the owner');
        wofToken = IWofToken(_address);
    }
    function setJunkYardPrice(uint256 _price) public {
        require(msg.sender == owner, 'Not the owner');
        junkyardPrice = _price;
    }
    function setMintNew() public {
        require(msg.sender == owner, 'Not the owner');
        mintNew = !mintNew;
    }

    function setUpgradePack(UpgradePack [] memory _array) public {
        require(msg.sender == owner, 'Not the owner');
        for(uint i=0; i < _array.length; i++){
            upgrades[_array[i].id].id = _array[i].id;            
            upgrades[_array[i].id].cost = _array[i].cost;
        }
    }


    function upgrade(uint256 _tokenId, uint256 _upgradeId) public {
        require(msg.sender == nftContract.ownerOf(_tokenId), 'You do not own this vehicle');
        require(wofToken.balanceOf(msg.sender) >= upgrades[_upgradeId].cost, 'Not enough WOF tokens');
        uint256 cost = upgrades[_upgradeId].cost;
        uint256 tokenContractAmount = cost.mul(1 ether);
        wofToken.burn(msg.sender, tokenContractAmount);
        emit Upgrade(msg.sender, _upgradeId, _tokenId);
    }

    function junkYard(uint256 _tokenId) public {
        require(msg.sender == nftContract.ownerOf(_tokenId), 'You do not own this vehicle');
        require(wofToken.balanceOf(msg.sender) >= junkyardPrice, 'Not enough WOF tokens');
        uint256 tokenContractAmount = junkyardPrice.mul(1 ether);
        bool mintedNew = false;
        wofToken.burn(msg.sender, tokenContractAmount);
        nftContract.transferFrom(msg.sender, owner , _tokenId);
        if(nftContract.mintedcount() < 10000 && mintNew == true) {
            nftContract.mintItems(msg.sender, 1);
            mintedNew = true;
        }
        emit JunkYard(msg.sender, _tokenId, mintedNew);
    }
}