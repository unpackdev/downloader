pragma solidity ^0.6.2;

import "./Ownable.sol";
import "./Context.sol";
import "./IERC20.sol";

contract RetrieveTokensFeature is Context, Ownable {

    function retrieveTokens(address to, address anotherToken, uint256 amount) virtual public onlyOwner() {
        IERC20 alienToken = IERC20(anotherToken);
        alienToken.transfer(to, amount);
    }

    function retriveETH(address payable to) virtual public onlyOwner() {
        to.transfer(address(this).balance);
    }

}
