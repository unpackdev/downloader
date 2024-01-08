pragma solidity 0.5.2;

import "./CustomToken.sol";
import "./Ownable.sol";
import "./TokenTimelock.sol";

contract REOB is CustomToken, Ownable {
    uint8 private DECIMALS = 18; //자리수
    uint256 private MAX_TOKEN_COUNT = 1000000000;   // 총 토큰 개수
    uint256 private MAX_SUPPLY = MAX_TOKEN_COUNT * (10 ** uint256(DECIMALS)); //총 발행량
    uint256 private INITIAL_SUPPLY = MAX_SUPPLY * 1 / 1; //초기 공급량

    bool private issued = false;


  // Lock
  mapping (address => address) public lockStatus;
  event Lock(address _receiver, uint256 _amount);


    constructor()
        CustomToken("REOB", "REOB", DECIMALS, MAX_SUPPLY)
        public {
            require(issued == false);
            super.mint(msg.sender, INITIAL_SUPPLY);
            issued = true;
    }


  function timeLockToken(address beneficiary, uint256 amount, uint256 releaseTime) onlyOwner public {
    TokenTimelock lockContract = new TokenTimelock(this, beneficiary, releaseTime);

    transfer(address(lockContract), amount);
    lockStatus[beneficiary] = address(lockContract);
    emit Lock(beneficiary, amount);
  }

}
