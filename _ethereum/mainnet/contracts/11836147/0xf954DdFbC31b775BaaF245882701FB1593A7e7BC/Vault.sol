pragma solidity ^0.5.7;

import "./Ownable.sol";
import "./IERC20.sol";

contract Vault is Ownable {
    address public swaps;

    modifier onlySwaps() {
        require(msg.sender == swaps);
        _;
    }

    function() external payable {}

    function tokenFallback(address, uint, bytes calldata) external {}

    function setSwaps(address _swaps) public onlyOwner {
        swaps = _swaps;
    }

    function withdraw(address _token, address _receiver, uint _amount)
        public
        onlySwaps
    {
        if (_token == address(0)) {
            address(uint160(_receiver)).transfer(_amount);
        } else {
            IERC20(_token).transfer(_receiver, _amount);
        }
    }
}
