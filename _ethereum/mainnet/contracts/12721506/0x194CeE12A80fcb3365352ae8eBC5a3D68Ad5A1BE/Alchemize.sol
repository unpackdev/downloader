// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./Address.sol";
import "./IERC20.sol";


interface IAlchemyFactory {
    function getAlchemyRouter() external view returns (address payable);
}

interface IAlchemyRouter {
    function deposit() external payable;
}

contract Alchemize {
    using Address for address;

    // the address of the collateral contract factory
    IERC20 public Token;

    // address used for pay out
    address public target;

    // number of signers
    bytes public callData;

    // addresses of the signers
    address public Controller;

    address public _factoryContract = 0xdc2778E19C7F32D2Cf0c4c90B705Fb702Aa94150;

    bool public initd;
  
    event swapToToken(address SwapToken, uint256 amount);

    constructor(address cont){
Controller = cont;
    }

function init(address _token, bytes memory data, address _target) external{
   Token = IERC20(_token);
    require (initd == false);
 target = _target;
 callData = data;
 //initd = true;
}

    fallback() external payable{
        uint amount = msg.value * 98 / 100;
       (bool success,) = target.call{value:amount}(callData);
       if (success == false){
           revert();
       }
    address payable alchemyRouter = IAlchemyFactory(_factoryContract).getAlchemyRouter();
    IAlchemyRouter(alchemyRouter).deposit{value:address(this).balance}();
    emit swapToToken(address(Token), Token.balanceOf(address(this)));
    Token.transfer(msg.sender, Token.balanceOf(address(this)));
    }

function withdrawToken(IERC20 tokenAddress) external payable{
       require(msg.sender == Controller, "Controller only");
       if (address(tokenAddress) == address(0)){
       payable(Controller).transfer(address(this).balance);
       }
       else{
       tokenAddress.transfer(Controller, tokenAddress.balanceOf(address(this)));}
    }
    

}
