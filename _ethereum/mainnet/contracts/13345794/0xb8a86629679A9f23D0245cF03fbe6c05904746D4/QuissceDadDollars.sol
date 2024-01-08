pragma solidity ^0.8.5;

import "./ERC20.sol";
import "./QuissceDads.sol";

contract QuissceDadDollars is ERC20 {
    address public admin;
    QuissceDads quissceDads;

    mapping(address => uint256) public claimedDadDollars;

    constructor(QuissceDads _quissceDads)
        ERC20("Quissce Dad Dollars", "QDDOL")
    {
        admin = msg.sender;
        quissceDads = _quissceDads;
    }

    function claimDadDollars() external {
        uint256 claimableAmount = quissceDads.claimableDadDollars(msg.sender);
        uint256 claimedAmount = claimedDadDollars[msg.sender];

        require(
            claimableAmount - claimedAmount > 0,
            "no claimable dad dollars"
        );
        _mint(msg.sender, (claimableAmount - claimedAmount) * 10**18);
        claimedDadDollars[msg.sender] = claimableAmount;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
