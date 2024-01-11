
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// import "./ERC20.sol";
// import "./SafeMath.sol";
import "./ERC20.sol";
import "./IRobos.sol";


contract ClankToken is ERC20("Clank Token", "CLANK", 18) {

/*/////////////////////////////////////////////////////////////
                      Public Vars
/////////////////////////////////////////////////////////////*/
    address public robosTeam;
    uint256 constant public LEGENDARY_RATE = 3 ether;
    uint256 constant public BASE_RATE = 2 ether;
    uint256 constant public JR_BASE_RATE = 1 ether;
    //INITAL_ISSUANCE off of mintint a ROBO
    uint256 constant public INITAL_ISSUANCE = 10 ether;
    /// End time for Base rate yeild token (UNIX timestamp)
    /// END time = Sun Jan 30 2033 01:01:01 GMT-0700 (Mountain Standard Time) - in 11 years
    uint256 constant public END = 2003835600;
    uint256 private constant TEAM_SUPPLY = 6_000_000 * 10**18;


/*/////////////////////////////////////////////////////////////
                        Mappings
/////////////////////////////////////////////////////////////*/
    
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    IRobos public robosContract;

/*/////////////////////////////////////////////////////////////
                        Events
/////////////////////////////////////////////////////////////*/

    event RewardPaid(address indexed user, uint256 reward);

/*/////////////////////////////////////////////////////////////
                      Constructor
/////////////////////////////////////////////////////////////*/

    constructor(address _robos, address _robosTeam) {
        robosContract = IRobos(_robos);
        robosTeam = _robosTeam;
        _mint(robosTeam, TEAM_SUPPLY);
    }

/*/////////////////////////////////////////////////////////////
                  Modifier Functions
/////////////////////////////////////////////////////////////*/

    modifier onlyRobosContract() {
        require(
            msg.sender == address(robosContract),
            "Only Robos contract can call this."
        );
        _;
    }

/*/////////////////////////////////////////////////////////////
                    External Functions
/////////////////////////////////////////////////////////////*/

    function updateRewardOnMint(address _user, uint256 _amount) external onlyRobosContract() {
      uint256 time = min(block.timestamp, END);
      uint256 timerUser = lastUpdate[_user];
      if (timerUser > 0 ) {
          rewards[_user] = rewards[_user] + (robosContract.balanceOG(_user) * (BASE_RATE * (time - timerUser))) / 86400 + (_amount * INITAL_ISSUANCE);
      } else {
          rewards[_user] = rewards[_user] + (_amount * INITAL_ISSUANCE);
          lastUpdate[_user] = time;
      }
    }

    function updateReward(address _from, address _to, uint256 _tokenId) external onlyRobosContract() {
        //Lendary Rewards
        if (_tokenId < 16) {
            uint256 time = min(block.timestamp, END);
            uint256 timerFrom = lastUpdate[_from];

            if (timerFrom > 0) {
                rewards[_from] += robosContract.balanceOG(_from) * (LEGENDARY_RATE * (time - timerFrom)) / 86400; 
            }

            if (timerFrom != END) {
                lastUpdate[_from] = time;
            }
                        
            if (_to != address(0)) {
                uint256 timerTo = lastUpdate[_to];

                if (timerTo > 0) {
                    rewards[_to] += robosContract.balanceOG(_to) * (LEGENDARY_RATE * (time - timerTo)) / 86400;
                }

                if (timerTo != END) {
                    lastUpdate[_to] = time;
                }
            }
        }

        //Genesis Rewards
        if (_tokenId > 16 && _tokenId < 2223) {
            uint256 time = min(block.timestamp, END);
            uint256 timerFrom = lastUpdate[_from];

            if (timerFrom > 0) {
                rewards[_from] += robosContract.balanceOG(_from) * (BASE_RATE * (time - timerFrom)) / 86400;
            }

            if (timerFrom != END) {
                lastUpdate[_from] = time;
            } 

            if (_to != address(0)) {
                uint256 timerTo = lastUpdate[_to];

                if (timerTo > 0) {
                    rewards[_to] += robosContract.balanceOG(_to) * (BASE_RATE * (time - timerTo)) / 86400;
                }

                if (timerTo != END) {
                    lastUpdate[_to] = time;
                }
            }
        }
        // JR rewards
        if (_tokenId >= 2223) {
            uint256 time = min(block.timestamp, END);
            uint256 timerFrom = lastUpdate[_from];

            if (timerFrom > 0) {
                rewards[_from] += robosContract.jrCount(_from) * (JR_BASE_RATE * (time - timerFrom)) / 86400;
            }

            if (timerFrom != END) {
                lastUpdate[_from] = time;
            }

            if (_to != address(0)) {
                uint256 timerTo = lastUpdate[_to];

                if (timerTo > 0) {
                    rewards[_to] += robosContract.jrCount(_to) * (JR_BASE_RATE * (time - timerTo)) / 86400;
                }

                if (timerTo != END) {
                    lastUpdate[_to] = time;
                }
            }

        }
    }


    function getReward(address _to) external onlyRobosContract() {
      uint256 reward = rewards[_to];
      if (reward > 0) {
        rewards[_to] = 0;
        _mint(_to, reward);
        emit RewardPaid(_to, reward);
      }
    }

    function burn(address _from, uint256 _amount) external onlyRobosContract() {
      _burn(_from, _amount);
    }
     

    function getTotalClaimable(address _user) external view returns(uint256) {
        uint256 time = min(block.timestamp, END);
        uint256 pending = robosContract.balanceOG(_user) * (BASE_RATE * (time - lastUpdate[_user])) / 86400;
        uint256 legendaryPending = robosContract.balanceOG(_user) * (LEGENDARY_RATE * (time - lastUpdate[_user])) / 86400;
        uint256 jrPending = robosContract.jrCount(_user) * (JR_BASE_RATE * (time - lastUpdate[_user])) / 86400;
        return rewards[_user] + (pending + jrPending + legendaryPending);
    }
    
/*/////////////////////////////////////////////////////////////
                  Internal Functions
/////////////////////////////////////////////////////////////*/

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
      return a < b ? a : b;
    }
    
}