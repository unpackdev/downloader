pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Address.sol";

contract ReservePool is Ownable{
    using Address for address;
    using SafeERC20 for IERC20;

    IERC20 public erc20;
    event Transfer(address indexed to,uint256 indexed amount);
    event Rescue(address indexed dst, uint256 sad);
    event RescueToken(address indexed dst, address indexed token, uint256 sad);

    constructor(address _erc20) public{
        erc20 = IERC20(_erc20);
    }

    function rescue(address payable to_, uint256 amount_) external onlyOwner {
        require(to_ != address(0), "must not 0");
        require(amount_ > 0, "must gt 0");

        to_.transfer(amount_);
        emit Rescue(to_, amount_);
    }

    function rescue(
        address to_,
        IERC20 token_,
        uint256 amount_
    ) external onlyOwner {
        require(to_ != address(0), "must not 0");
        require(amount_ > 0, "must gt 0");
        require(token_ != erc20, "must not erc20");

        token_.transfer(to_, amount_);
        emit RescueToken(to_, address(token_), amount_);
    }

    function transfer(address _to,uint256 _amount) external onlyOwner{
        require(_to != address(0), "must not 0");
        require(_amount > 0, "must gt 0");
        require(_to.isContract(),"Token must be transfered to a contract!");
        erc20.transfer(_to,_amount);
        emit Transfer(_to,_amount);
    }
}