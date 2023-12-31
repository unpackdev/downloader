// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function latestAnswer() external view returns(int256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: convertor.sol


pragma solidity ^0.8.0;


interface IAMPH{
    function mint(address, uint256) external;
    function totalSupply() external view returns(uint256);
}

interface IERC20{
    function transferFrom(address, address, uint256) external returns (bool);
    function balanceOf(address) external view returns(uint256);
    function transfer(address, uint256) external returns(bool);
}

interface IAmphClaimer{
    function claimable(address _sender, uint96 _vaultID, uint256 _cvxTotalRewards, uint256 _crvTotalRewards) external view returns (uint256, uint256, uint256);

}

contract MultiTokenPriceFeed {
    mapping(address => address) public aggregators;
    address public constant USDA_ADDRESS = 0xD842D9651F69cEBc0b2Cffc291fC3D3Fe7b5D226;
    address public constant CRV_ADDRESS = 0xD533a949740bb3306d119CC777fa900bA034cd52; 
    address public constant cvxCRV_ADDRESS = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
    address public constant SNX_ADDRESS = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    address public constant BAL_ADDRESS = 0xba100000625a3754423978a60c9317c58a424e3D;
    mapping(address=>bool) public isApproved;
    address public AMPH = 0x943c5F4F54509d1e78B1fCD93B92c43ce83d3141;
    address public owner;
    address public governance = 0xA905f9f0b525420d4E5214E73d70dfFe8438D8C8;
    address public amphClaimer = 0x8B66d70953Ad233976812f4B5B92bBAfeBA90A75;
    mapping(address=>uint256) caps;
    mapping(address=>uint256) current;
    uint256 public minted;
    bool public paused;

    constructor() {
        // Initialize the mapping with Chainlink aggregator contract addresses
        // for each token contract address (replace these addresses with the actual ones)
        aggregators[SNX_ADDRESS] = 0xDC3EA94CD0AC27d9A86C180091e7f78C683d3699; // SNX
        aggregators[cvxCRV_ADDRESS] = 0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f; // cvxCRV
        aggregators[BAL_ADDRESS] = 0xdF2917806E30300537aEB49A7663062F4d1F2b5F; // BAL
        aggregators[CRV_ADDRESS] = 0xCd627aA160A6fA45Eb793D19Ef54f5062F20f33f; // CRV
        // USDA does not have an oracle, so we set it to address(0)
        aggregators[USDA_ADDRESS] = address(0);
        isApproved[SNX_ADDRESS] = true;
        isApproved[cvxCRV_ADDRESS] = true;
        isApproved[BAL_ADDRESS] = true;
        isApproved[CRV_ADDRESS] = true;
        isApproved[USDA_ADDRESS] = true;
        owner = msg.sender;
        paused = true;
    }

    function initialize() public {
        require(caps[SNX_ADDRESS] == 0);
        caps[SNX_ADDRESS] = (250_000 * 1e18);
        caps[cvxCRV_ADDRESS] = (1_000_000 * 1e18);
        caps[BAL_ADDRESS] = (25_000 * 1e18);
        caps[CRV_ADDRESS] = (25_000 * 1e18);
        caps[USDA_ADDRESS] = (1_000_000 * 1e18);
    }
    
        function getCRVEquivalent(address tokenAddress, uint256 tokenAmount) public pure returns (uint256) {
                uint256 crvEquivalent = 0;
                if(tokenAddress == SNX_ADDRESS){
                    crvEquivalent = (7000000000000000000 * tokenAmount) / 1e18;
                }

                if(tokenAddress == cvxCRV_ADDRESS){
                    crvEquivalent = (680000000000000000 * tokenAmount) / 1e18;
                }

                if(tokenAddress == BAL_ADDRESS){
                    crvEquivalent = (7200000000000000000 * tokenAmount) / 1e18;
                }

                if(tokenAddress == USDA_ADDRESS){
                    crvEquivalent = (2310000000000000000 * tokenAmount) / 1e18;
                }

                if(tokenAddress == CRV_ADDRESS){
                    crvEquivalent = (990000000000000000 * tokenAmount) / 1e18;
                }
            return crvEquivalent;
        }

    function purchaseAMPH(address _token, uint256 _amount) public {
        require(!paused);
        require(isApproved[_token] == true);
        require(IERC20(_token).transferFrom(msg.sender, governance, _amount));
        require(current[_token] + _amount <= caps[_token], "This mint would exceed the cap for this token type");
        uint256 crvEq = getCRVEquivalent(_token, _amount);
        (,,uint256 amt) = IAmphClaimer(amphClaimer).claimable(address(0), uint96(0), uint256(0), crvEq);
        amt = (amt * 70) / 100; //purchases take place at 70% the rate of earned.
        require(amt + minted <= (((IAMPH(AMPH).totalSupply() - (3_800_000_000 * 1e18)) * 60) / 100), "Purchased tokens cannot make up more than 60% of supply");
        require(amt < (1_000_000 * 1e18), "No single purchase can exceed 1M AMPH");
        minted += amt;
        current[_token] += _amount;
        if(IERC20(AMPH).balanceOf(address(this)) >= amt){
           require(IERC20(AMPH).transfer(msg.sender, amt));
        } else {
            IAMPH(AMPH).mint(address(this), amt);
            require(IERC20(AMPH).transfer(msg.sender, amt));
        }
    }

    function setCap(address _token, uint256 _amount) public {
        require(msg.sender == owner);
        caps[_token] = _amount;
    }

    function setEnabled(address _token, bool _enabled) public {
        require(msg.sender == owner);
        isApproved[_token] = _enabled;
    }

    function setAggregators(address _token, address _aggregator) public {
        require(msg.sender == owner);
        aggregators[_token] = _aggregator;
    }

    function setPaused(bool _bool) public {
        require(msg.sender == owner);
        paused = _bool;
    }
}