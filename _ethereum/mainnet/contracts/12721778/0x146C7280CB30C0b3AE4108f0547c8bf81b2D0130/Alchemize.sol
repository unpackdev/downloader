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

    // the address of the token to be swapped to
    IERC20 public Token;

    // address of the router contract
    address public target;

    // calldata for the swap
    bytes public callData;

    // controller of the contract
    address public Controller;

    // factory to look up the router
    address public constant factoryContract = 0xdc2778E19C7F32D2Cf0c4c90B705Fb702Aa94150;

    // indicator if contract is inited
    bool private initd;

    event swapToToken(address SwapToken, uint256 amount);

    constructor() {
        // implementation should not be initialized
        initd = true;
    }

    function init(address _token, bytes memory data, address _target, address cont) external{
        require (initd == false, "Already init");

        Token = IERC20(_token);
        target = _target;
        callData = data;
        Controller = cont;
        initd = true;
    }

    receive() external payable{
        uint amount = msg.value * 98 / 100;
        (bool success,) = target.call{value:amount}(callData);
        if (success == false){
            revert();
        }
        address payable alchemyRouter = IAlchemyFactory(factoryContract).getAlchemyRouter();
        IAlchemyRouter(alchemyRouter).deposit{value:address(this).balance}();
        emit swapToToken(address(Token), Token.balanceOf(address(this)));
        Token.transfer(msg.sender, Token.balanceOf(address(this)));
    }

    function withdrawToken(IERC20 tokenAddress) external payable{
        require(msg.sender == Controller, "Controller only");

        if (address(tokenAddress) == address(0)){
            payable(Controller).transfer(address(this).balance);
        }
        else {
            tokenAddress.transfer(Controller, tokenAddress.balanceOf(address(this)));
        }
    }
}
