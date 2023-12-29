// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Add the tokens, that's when the crowdsale starts
// Pull the tokens out, that's when it ends
// Users send ether and receive tokens here
contract Crowdsale {
    mapping(address => bool) internal buyStarted;
    uint256 public ratio;
    IERC20 public mevdao;
    address public owner;

    event Purchase(address indexed buyer, uint256 indexed amountEth, uint256 indexed tokenAmount, uint256 timestamp);

    modifier onlyOwner {
        require(msg.sender == owner, "owner");
        _;
    }

    constructor(uint256 _ratio, address _mevdao) {
        ratio = _ratio;
        mevdao = IERC20(_mevdao);
        owner = msg.sender;
    }

    receive() external payable {
        participate();
    }

    function participate() public payable {
        require(!buyStarted[msg.sender], "Can't re-enter");
        buyStarted[msg.sender] = true;
        uint256 balance = mevdao.balanceOf(address(this));
        uint256 tokensToReceive = msg.value * ratio; // msg.value * ratio = tokensToReceive

        if (tokensToReceive > balance) {
            // Refund remaining eth
            uint256 remaining = tokensToReceive - balance;
            tokensToReceive = tokensToReceive - remaining;
            uint256 refundAmount = remaining / ratio;
            payable(msg.sender).transfer(refundAmount);
        }

        mevdao.transfer(msg.sender, tokensToReceive);

        emit Purchase(msg.sender, msg.value, tokensToReceive, block.timestamp);
        buyStarted[msg.sender] = false;
    }

    function updateRatio(uint256 _ratio) external onlyOwner {
        ratio = _ratio;
    }

    function recoverETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function recoverStuckTokens(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner, balance);
    }
}