pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";

interface IWorldOfFreight {
	function balanceOG(address _user) external view returns(uint256);
    function ownerOf(uint256 tokenId) external view returns(address);
    function mintedcount() external view returns (uint256);
}

contract WOFToken is ERC20("WoFToken", "WOF") {
    using SafeMath for uint256;
    uint256 public BASE_RATE = 25000000000000000000;
    uint256 public buyPrice = 30000000000000;
    bool public _saleOpen = false;
    uint256 public rate = 1;
    bool public cut = false;
    address public cutAddres;
    address public contOwner;
    address public _garageContract;
    uint256 public ENDTIME = 1664582400;
    mapping(address => uint256) public rewards;
	mapping(address => uint256) public lastUpdate; 


    IWorldOfFreight public wofContract;
    constructor(address _wof) {
		wofContract = IWorldOfFreight(_wof);
        contOwner = msg.sender;
	}   

    //Set buy price for token
    function setPrice(uint256 _price) public {
        require(msg.sender == contOwner, 'Sorry, no luck for you');
        buyPrice = _price;
    }
    function setBaseRate(uint256 _price) public {
        require(msg.sender == contOwner, 'Sorry, no luck for you');
        BASE_RATE = _price;
    }
    function setCut() public {
        require(msg.sender == contOwner, 'Sorry, no luck for you');
        cut = !cut;
    }
    function setCutAddr(address _to) public {
        require(msg.sender == contOwner, 'Sorry, no luck for you');
        cutAddres = _to;
    }
    function setGarageContract(address contractAddress) public {
        require(msg.sender == contOwner, 'Sorry, no luck for you');
        _garageContract = contractAddress;
    }
    //Activate sale for token
    function toggleTokenSale() public {
        require(msg.sender == contOwner, 'Sorry, no luck for you');
        _saleOpen = !_saleOpen;
    }
    function setRate(uint256 newRate) public {
        require(msg.sender == contOwner, 'Big no-no');
        rate = newRate;
    }

    //Reward minters - Add virtual tokens
    function rewardOnMint(address _user, uint256 _amount) external {
		require(msg.sender == address(wofContract), "Can't call this");
        uint256 tokenId = wofContract.mintedcount();
        uint256 time = block.timestamp;
        if(tokenId < 2501) {
            rewards[_user] = rewards[_user].add(500 ether);
        }
        else {
            rewards[_user] = rewards[_user].add(_amount);
        }
        lastUpdate[_user] = time;
    }

    //GET BALANCE FOR SINGLE TOKEN
    function getClaimable(address _owner) public view returns(uint256){
        uint256 time = block.timestamp;
        if(lastUpdate[_owner] == 0) {
            return 0;
        }
        else if(time < ENDTIME) {
            uint256 pending = wofContract.balanceOG(_owner).mul(BASE_RATE.mul((time.sub(lastUpdate[_owner])))).div(86400);
            uint256 total = rewards[_owner].add(pending);
            return total;
        }
        else {
            return rewards[_owner];
        }
    }

    struct Rewardees {
        address owner;
        uint256 amount;
    }

    //Reward tokens to minted users
    function initialReward(Rewardees [] memory _array, uint256 time) public {
        require(msg.sender == contOwner, 'Big no-no');
        for(uint i=0; i < _array.length; i++){            
            rewards[_array[i].owner] = _array[i].amount;
            lastUpdate[_array[i].owner] = time;
        }
    }
    //SET BALANCE FOR TOKEN
    function setBalance(Rewardees [] memory _array) public {
        require(msg.sender == contOwner || msg.sender == address(_garageContract), 'Big no-no');
        for(uint i=0; i < _array.length; i++){            
            rewards[_array[i].owner] = _array[i].amount;
        }
    }

    function transferTokens(address _from, address _to) external {
		require(msg.sender == address(wofContract));
        uint256 time = block.timestamp;
        rewards[_from] = getClaimable(_from);
        lastUpdate[_from] = time;
        rewards[_to] = getClaimable(_to);
        lastUpdate[_to] = time;
	}
  
    //Buy tokens from contract
    function buyMint(address _to, uint256 _amount) public payable {
        require(msg.value >= _amount.mul(buyPrice), 'Send more eth');
        require(_saleOpen == true, 'Can not buy at the moment');
        uint256 eth = _amount.mul(1 ether);
        _mint(_to, eth);
    }

    function rewardUsers(address _to, uint256 _amount) public {
        require(msg.sender == contOwner, 'Sorry, no luck for you');
        uint256 time = block.timestamp;
        uint256 unclaimed = getClaimable(_to);
        rewards[_to] = rewards[_to].add(_amount).add(unclaimed);
        lastUpdate[_to] = time;
    }

    function claimTokens(address _to, uint256 _amount) public {
        require(_amount <= getClaimable(_to), 'You do not have this much');
        rewards[_to] = getClaimable(_to);
        uint256 time = block.timestamp;
        rewards[_to] = rewards[_to].sub(_amount);
        lastUpdate[_to] = time;
        _mint(_to, _amount );
    }
    //BURN THE TOKENS FOR NAMECHANGE
    function burn(address _from, uint256 _amount) external {
		require(msg.sender == address(wofContract) || msg.sender == address(_garageContract));
        uint256 valueInEth = _amount/(1 ether);
        if(cut) {
            uint256 percentage = rate.div(100);
            uint256 cuttable = valueInEth.div(percentage);
            uint256 burnable = valueInEth.sub(cuttable);
            _transfer(_from, cutAddres, cuttable);
            _burn(_from, burnable);
        }
        else {
		    _burn(_from, valueInEth);
        }
	}
    //GET ETH FROM CONTRACT
    function withdraw(address payable to, uint256 amount) public {
        require(msg.sender == contOwner);
        to.transfer(amount); 
    }

}