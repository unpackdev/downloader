// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "ERC20.sol";
import "IERC20.sol";
import "SafeERC20.sol"; 
import "link.sol";

interface VaultV0 {
    function expiry() external returns (uint);  
    function COLLAT_ADDRESS() external returns (address); 
    function PRICE_FEED() external returns (address);
    function LINK_AGGREGATOR() external returns (address);
    
    /* Multisig Alpha */
    function setOwner(address newOwner) external;
    function settleStrike_MM(uint priceX1e6) external;
    function setExpiry(uint arbitraryExpiry) external;
    function setMaxCap(uint newDepositCap) external;
    function setMaker(address newMaker) external;
    function setPriceFeed(HistoricalPriceConsumerV3_1 newPriceFeed) external;
    function emergencyWithdraw() external;
    function depositOnBehalf(address tgt, uint256 amt) external;
    function setAllowInteraction(bool _flag) external;
}

contract OwnerProxy {

    address public multisigAlpha;
    address public multisigBeta;
    address public teamKey;

    address public multisigAlpha_pending;
    address public multisigBeta_pending;
    address public teamKey_pending;
    
    mapping(bytes32 => uint) public queuedPriceFeed;
    
    event PriceFeedQueued(address indexed _vault, address pricedFeed);
    
    constructor() {
      multisigAlpha = msg.sender;
      multisigBeta  = msg.sender;
      teamKey       = msg.sender;
    }
    
    function setMultisigAlpha(address _newMultisig) external {
      require(msg.sender == multisigAlpha, "!multisigAlpha");
      multisigAlpha_pending = _newMultisig;
    }

    function setMultisigBeta(address _newMultisig) external {
      require(msg.sender == multisigAlpha || msg.sender == multisigBeta, "!multisigAlpha/Beta");
      multisigBeta_pending = _newMultisig;
    }
    
    function setTeamKey(address _newTeamKey) external {
      require(msg.sender == multisigAlpha || msg.sender == multisigBeta || msg.sender == teamKey, "!ownerKey");
      teamKey_pending = _newTeamKey;
    }
    
    function acceptMultisigAlpha() external {
      require(msg.sender == multisigAlpha_pending, "!multisigAlpha_pending");
      multisigAlpha = multisigAlpha_pending;
    }

    function acceptMultisigBeta() external {
      require(msg.sender == multisigBeta_pending, "!multisigBeta_pending");
      multisigBeta = multisigBeta_pending;
    }

    function acceptTeamKey() external {
      require(msg.sender == teamKey_pending, "!teamKey_pending");
      teamKey = teamKey_pending;
    }
    
    function setOwner(VaultV0 _vault, address _newOwner) external { 
      require(msg.sender == multisigAlpha, "!multisigAlpha");
      _vault.setOwner(_newOwner);
    }
    
    function emergencyWithdraw(VaultV0 _vault) external { 
      require(msg.sender == multisigAlpha, "!multisigAlpha");
      _vault.emergencyWithdraw();
      IERC20 COLLAT = IERC20(_vault.COLLAT_ADDRESS());
      COLLAT.transfer(multisigAlpha, COLLAT.balanceOf( address(this) ));
      require(COLLAT.balanceOf(address(this)) == 0, "eWithdraw transfer failed."); 
    }
    
    function queuePriceFeed(VaultV0 _vault, HistoricalPriceConsumerV3_1 _priceFeed) external {
      if        (msg.sender == multisigAlpha) {  // multisigAlpha can instantly change the price feed 
        _vault.setPriceFeed(_priceFeed);
        return;
      } else if (msg.sender == multisigBeta) {
        bytes32 hashedParams = keccak256(abi.encodePacked(_vault, _priceFeed));
        if (queuedPriceFeed[hashedParams] == 0) {
          queuedPriceFeed[hashedParams] = block.timestamp + 1 days;
          emit PriceFeedQueued(address(_vault), address(_priceFeed));
        } else {
          require(block.timestamp > queuedPriceFeed[hashedParams], "Timelocked"); 
          _vault.setPriceFeed(_priceFeed);
        }
      } else if (msg.sender == teamKey) {
        bytes32 hashedParams = keccak256(abi.encodePacked(_vault, _priceFeed));
        if (queuedPriceFeed[hashedParams] > 0) {
          require(block.timestamp > queuedPriceFeed[hashedParams], "Timelocked");
          _vault.setPriceFeed(_priceFeed);
        }
      }
    }

    function settleStrike_MM(VaultV0 _vault, uint _priceX1e6) external {
      if   (msg.sender == multisigAlpha) { // Arbitrary price setting
        _vault.settleStrike_MM(_priceX1e6);
      } else {
        uint curPrice = uint(HistoricalPriceConsumerV3_1(_vault.PRICE_FEED()).getLatestPriceX1e6(AggregatorV3Interface(_vault.LINK_AGGREGATOR())));
        uint upperBound = curPrice;
        uint lowerBound = curPrice; 
        if (msg.sender == multisigBeta) {   // +/- 20% price set
          upperBound = curPrice * 1200 / 1000;
          lowerBound = curPrice *  800 / 1000;
        } else if (msg.sender == teamKey) { // +/- 5% price set
          upperBound = curPrice * 1050 / 1000;
          lowerBound = curPrice *  950 / 1000;        
        } else {
          revert("Not Owner Keys");
        }
        if (_priceX1e6 > upperBound) revert("Price too high");
        if (_priceX1e6 < lowerBound) revert("Price too low");
        _vault.settleStrike_MM(_priceX1e6);       
      }
    }
    
    function setExpiry(VaultV0 _vault, uint _expiry) external {
      require(msg.sender == multisigBeta, "Not multisigBeta");
      require(_vault.expiry() > 0, "Expired");
      require(_expiry < _vault.expiry(), "Can only set expiry nearer");
      _vault.setExpiry(_expiry);
    }
    
    
    function depositOnBehalf(VaultV0 _vault, address _onBehalfOf, uint _amt) external {
      require(msg.sender == teamKey, "Not teamKey");
      IERC20 COLLAT = IERC20(_vault.COLLAT_ADDRESS()); 
      COLLAT.transferFrom(msg.sender, address(this), _amt);
      COLLAT.approve(address(_vault), _amt);
      _vault.depositOnBehalf(_onBehalfOf, _amt);
      require(COLLAT.balanceOf(address(this)) == 0, "Balance Left On OwnerProxy");
    }
    
    function setMaxCap(VaultV0 _vault, uint _maxCap) external {
      require(msg.sender == teamKey, "Not teamKey");
      _vault.setMaxCap(_maxCap);
    }   
    
    function setAllowInteraction(VaultV0 _vault, bool _flag) external {
      require(msg.sender == teamKey, "Not teamKey");
      require(_vault.expiry() == 0, "Not Expired");
      _vault.setAllowInteraction(_flag);
    }

    function setMaker(VaultV0 _vault, address _newMaker) external {
      if (msg.sender == multisigBeta) {  
        _vault.setMaker(_newMaker);
      } else if (msg.sender == teamKey) {
        require(_vault.expiry() == 0, "Not Expired");
        _vault.setMaker(_newMaker);
      } else {
       revert("!teamKey,!musigBeta");
      }
    }    
    
}