pragma solidity ^0.5.0;

import "./SdaoOneInch.sol";
import "./Ownable.sol";

contract DynasetSwap is Ownable {
    // OneSplit Config
    address ONE_SPLIT_ADDRESS = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;
    uint256 FLAGS = uint256(0);

    
    function getTokenBalance(address token) public view returns(uint256 balance){

         IERC20 token = IERC20(token);
         uint256 balance = token.balanceOf(address(this));
         return balance;
    }

    function oneSplitSwap(address _from, address _to, uint256 _amount, uint256 _minReturn,
        uint256[] memory _distribution) public payable {

        _oneSplitSwap(_from, _to, _amount, _minReturn, _distribution);
    }

    function _oneSplitSwap(address _from, address _to, uint256 _amount, uint256 _minReturn,
        uint256[] memory _distribution) internal {
        // Setup contracts

        require (getTokenBalance(_from) > 0,"no asset to swap");
        
        IERC20 _fromIERC20 = IERC20(_from);
        IERC20 _toIERC20 = IERC20(_to);
        IOneSplit _oneSplitContract = IOneSplit(ONE_SPLIT_ADDRESS);

        // Approve tokens
        _fromIERC20.approve(ONE_SPLIT_ADDRESS, _amount);
        //console.log("Token approved");
        // Swap tokens: give _from, get _to
        _oneSplitContract.swap(_fromIERC20, _toIERC20, _amount, _minReturn, _distribution,FLAGS);

    }

    function _oneSplitSwapExpected(address _from, address _to, uint256 _amount, uint256 _parts) external {
        // Setup contracts
        IERC20 _fromIERC20 = IERC20(_from);
        IERC20 _toIERC20 = IERC20(_to);
        IOneSplit _oneSplitContract = IOneSplit(ONE_SPLIT_ADDRESS);

        // Approve tokens
        _fromIERC20.approve(ONE_SPLIT_ADDRESS, _amount);
        //console.log("Token approved");
        // Swap tokens: give _from, get _to
        _oneSplitContract.getExpectedReturn(_fromIERC20, _toIERC20, _amount, _parts, FLAGS);

    }


    function withdrawETHAndAnyTokens(address addresse) external onlyOwner {
           IERC20 Token = IERC20(addresse);
           uint256 currentTokenBalance = Token.balanceOf(address(this));
           Token.transfer(msg.sender, currentTokenBalance); 
    }
}
