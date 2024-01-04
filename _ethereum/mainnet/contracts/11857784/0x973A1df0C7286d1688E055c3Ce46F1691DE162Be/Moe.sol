pragma solidity 0.7.1;
import "./Stooge.sol";

contract Moe is Stooge {
    using SafeMath for uint256;
    event Participation(address indexed participant, uint256 ethAmount, uint256 moeAmount);
    event Dropkicked(address indexed victim, uint256 larryAmount, uint256 moeBalance);

    uint256 public moePerEth;
    address public larryPair;

    address[] public participants;

  function setLarry(address payable addr) external onlyOwner {
    require(address(larry) == address(0), 'only once');
    larry = ILarry(addr);
    larry.mint(address(this), (1e24) + 3);
    larry.approve(address(uniswapRouter), 1e24);    
  }
    constructor(uint256 moePerEth_, uint256 startTime_, uint256 duration_)
    Stooge('MOE', 'MOE') {
      moePerEth = moePerEth_;
      startTime = startTime_;
      endTime = startTime + duration_;
      _mint(msg.sender, 800000*(1 ether));
    }

    receive() external payable nonReentrant {
        require(startTime <= block.timestamp, "It aint started yet");
        require(endTime >= block.timestamp, "It aint on anymore.");
        _mint(msg.sender, msg.value.mul(moePerEth));
        participants.push(msg.sender);
        emit Participation(msg.sender, msg.value, msg.value.mul(moePerEth));
    }

    //We will have to keep slapping until everyone is dumped on.
    function slap() external override nonReentrant {
      require(endTime < block.timestamp, "It aint on yet.");
      require(slapped == false, "Already done.");
      slapped = true;

      if(address(this).balance > 0) {
        treasury.transfer(address(this).balance.div(10).mul(3));
        uniswapRouter.addLiquidityETH{value:address(this).balance}(
          address(larry),
          (1e24) / 5 * 4,
          0,
          0,
          address(larry),
          block.timestamp
        );
        _mint(address(this), totalSupply());
      }
    }

    function bonk() external nonReentrant {
      require(endTime < block.timestamp, "It aint on yet.");
      require(bonked == false, "Already done.");
      require(slapped == true, "Not yet");

      bonked = true;
      uint256 liquify = (1e24) / 10;
        _approve(address(this), address(uniswapRouter), totalSupply());
        uniswapRouter.addLiquidity(
           address(this),
           address(larry),
           totalSupply().div(2),          
           liquify,
           0,
           0,
           address(this),
           block.timestamp
         );        
    }

    function dropkick(uint64 recipients) external nonReentrant {
      require(slapped == true, "Not yet");
      require(bonked == true, "Not yet");
      require(endTime < block.timestamp, "It aint on yet.");

      uint256 drop = (1e24) / 10;
      if(participants.length > 0) {
        uint64 count;
        uint256 supply = totalSupply().div(2);
        for(uint256 i = participants.length; i > 0 ; i--)
        { address participant = participants[i-1];
          uint256 balance = balanceOf(participant);
          uint256 amount = drop.mul(balance).div(supply);
          participants.pop();
          larry.mint(participant, amount);
          emit Dropkicked(participant, amount, balance);
          count++;
          if(count >= recipients) break;
        }
      }        
    }
}
