pragma solidity ^0.5.16;

import "./SafeMath.sol";
import "./ERC20Mintable.sol";
import "./ERC20Burnable.sol";
import "./ERC20Detailed.sol";
import "./Ownable.sol";
import "./IBridgeContract.sol";
import "./IXGTToken.sol";

contract XGTTokenMainnet is
    Initializable,
    Ownable,
    ERC20Detailed,
    ERC20Mintable,
    ERC20Burnable
{
    using SafeMath for uint256;

    address public xDaiContract;
    IBridgeContract public bridge;

    function initializeToken(address _xDaiContract, address _bridge) public {
        require(xDaiContract == address(0), "XGT-ALREADY-INITIALIZED");
        _transferOwnership(msg.sender);
        xDaiContract = _xDaiContract;
        bridge = IBridgeContract(_bridge);
    }

    function setBridge(address _address) external onlyOwner {
        bridge = IBridgeContract(_address);
    }

    function transferredToMainnet(address _user, uint256 _amount) external {
        require(msg.sender == address(bridge), "XGT-NOT-BRIDGE");
        require(
            bridge.messageSender() == xDaiContract,
            "XGT-NOT-XDAI-CONTRACT"
        );
        _mint(_user, _amount);
    }

    function transferToXDai(uint256 _amount) external {
        _burn(msg.sender, _amount);
        bytes4 _methodSelector =
            IXGTToken(address(0)).transferredToXDai.selector;
        bytes memory data =
            abi.encodeWithSelector(_methodSelector, msg.sender, _amount);
        bridge.requireToPassMessage(xDaiContract, data, 300000);
    }

    // Safety override
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(this), "XGT-CANT-TRANSFER-TO-CONTRACT");
        return super.transfer(recipient, amount);
    }

    // Safety override
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        require(recipient != address(this), "XGT-CANT-TRANSFER-TO-CONTRACT");
        return super.transferFrom(sender, recipient, amount);
    }
}
