pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ProtocolInterface.sol";
import "./ERC20.sol";
import "./ITokenInterface.sol";
import "./ConstantAddresses.sol";
import "./DSAuth.sol";

contract FulcrumSavingsProtocol is ProtocolInterface, ConstantAddresses, DSAuth {

    address public savingsProxy;
    uint public decimals = 10 ** 18;

    function addSavingsProxy(address _savingsProxy) public auth {
        savingsProxy = _savingsProxy;
    }

    function deposit(address _user, uint _amount) public override {
        require(msg.sender == _user);

        // get dai from user
        require(ERC20(DAI_ADDRESS).transferFrom(_user, address(this), _amount));

        // approve dai to Fulcrum
        ERC20(DAI_ADDRESS).approve(NEW_IDAI_ADDRESS, uint(-1));

        // mint iDai
        ITokenInterface(NEW_IDAI_ADDRESS).mint(_user, _amount);
    }

    function withdraw(address _user, uint _amount) public override {
        require(msg.sender == _user);

        // transfer all users tokens to our contract
        require(ERC20(NEW_IDAI_ADDRESS).transferFrom(_user, address(this), ITokenInterface(NEW_IDAI_ADDRESS).balanceOf(_user)));

        // approve iDai to that contract
        ERC20(NEW_IDAI_ADDRESS).approve(NEW_IDAI_ADDRESS, uint(-1));
        uint tokenPrice = ITokenInterface(NEW_IDAI_ADDRESS).tokenPrice();

        // get dai from iDai contract
        ITokenInterface(NEW_IDAI_ADDRESS).burn(_user, _amount * decimals / tokenPrice);

        // return all remaining tokens back to user
        require(ERC20(NEW_IDAI_ADDRESS).transfer(_user, ITokenInterface(NEW_IDAI_ADDRESS).balanceOf(address(this))));
    }
}
