pragma solidity ^0.6.2;
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Initializable.sol";

contract CWCExchange is Initializable {
    using SafeMath for uint256;

    uint256 public rate;
    IERC20 public token;
    address public owner;

    function initialize(uint256 _rate, IERC20 _token) public initializer {
        rate = _rate;
        token = _token;
    }

    receive() external payable {
        uint256 tokens = msg.value.mul(rate);
        token.transfer(msg.sender, tokens);
    }

    function withdraw() public {
        require(
            msg.sender == owner,
            "Address not allowed to call this function"
        );
        msg.sender.transfer(address(this).balance);
    }

    function withdrawToken(uint256 amount) public {
        require(
            msg.sender == owner,
            "Address not allowed to call this function"
        );
        token.transfer(msg.sender, amount);
    }

    function setOwner(address _owner) public {
        require(owner == address(0), "Owner already set, cannot modify!");
        owner = _owner;
    }
}
