pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


contract SimpleOracleAccruedRatioUSD {
    using SafeMath for uint256;
    address public admin;
    address public superAdmin;
    uint256 public accruedRatioUSD;
    uint256 public lastUpdateTime;
    uint256 public MAXIMUM_CHANGE_PCT = 3;

    constructor(uint256 _accruedRatioUSD, address _admin, address _superAdmin) public {
        admin = _admin;
        superAdmin = _superAdmin;
        accruedRatioUSD = _accruedRatioUSD;
    }

    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == superAdmin);
        _;
    }

    modifier onlySuperAdmin {
        require(msg.sender == superAdmin);
        _;
    }

    function isValidRatio(uint256 _accruedRatioUSD) view internal {
      require(_accruedRatioUSD >= accruedRatioUSD, "ratio should be monotonically increased");
      uint256 maximumChange = accruedRatioUSD.mul(MAXIMUM_CHANGE_PCT).div(100);
      require(_accruedRatioUSD.sub(accruedRatioUSD) < maximumChange, "exceeds maximum chagne");
    }

    function checkTimeStamp() view internal {
      // 82800 = 23 * 60 * 60  (23 hours)
      require(block.timestamp.sub(lastUpdateTime) > 82800, "oracle are not allowed to update two times within 23 hours");
    }

    function set(uint256 _accruedRatioUSD) onlyAdmin public{
        if(msg.sender != superAdmin) {
          isValidRatio(_accruedRatioUSD);
          checkTimeStamp();
        }
        lastUpdateTime = block.timestamp;
        accruedRatioUSD = _accruedRatioUSD;
    }

    function query() external view returns(uint256)  {
        // QueryEvent(msg.sender, block.number);
        return accruedRatioUSD;
    }
}