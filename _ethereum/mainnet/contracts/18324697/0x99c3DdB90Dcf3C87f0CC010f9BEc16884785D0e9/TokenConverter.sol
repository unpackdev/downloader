//SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

// Sends the new tokens after proving that you hold the previous tokens
contract TokenConverter {
    address public owner;
    address public oldToken;
    address public newToken;
    mapping (address => uint256) public claimants; // People that don't hold tokens but can claim them for an airdrop or whatever
    mapping (address => bool) public claimed; // People that don't hold tokens but can claim them for an airdrop or whatever

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(address _oldToken, address _newToken) {
        owner = msg.sender;
        oldToken = _oldToken;
        newToken = _newToken;
    }

    function claim() external {
        uint256 tokenBalance = IERC20(oldToken).balanceOf(msg.sender);
        require(tokenBalance > 0, "You don't hold the old token");
        require(IERC20(oldToken).transferFrom(msg.sender, address(this), tokenBalance), "Transfer from failed");
        IERC20(newToken).transfer(msg.sender, tokenBalance);
    }

    function rescueEth() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    function rescueTokens(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner, balance);
    }
}