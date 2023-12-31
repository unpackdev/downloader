// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "./Ownable.sol";
import "./IERC20.sol";

contract GazaTokenSplitter is Ownable {
    
    address public teamWallet1;
    address public teamWallet2;
    address public teamWallet3;
    address public teamWallet4;
    address public teamWallet5;

    IERC20 public token;

    constructor() {
        teamWallet1 = 0x66e781EF344294db5cf1458C31CF3f49551Fd2C9;
        teamWallet2 = 0xA9C970d5fE6CFAfB77a2b64812d0d6FbD480a03d;
        teamWallet3 = 0xAb15f1285a6476A3159dA38f3059fafE58f92b35;
        teamWallet4 = 0x81659058B4EFBFcAA72adc4756E4B7701A0633cb;
        teamWallet5 = 0x854b286319B71B644C93fD90B22d1c22021c396B;
    }

    receive() external payable {}

    function updateTeamWallet1(address newWallet) external onlyOwner {
        teamWallet1 = newWallet;
    }

    function updateTeamWallet2(address newWallet) external onlyOwner {
        teamWallet2 = newWallet;
    }

    function updateTeamWallet3(address newWallet) external onlyOwner {
        teamWallet3 = newWallet;
    }

    function updateTeamWallet4(address newWallet) external onlyOwner {
        teamWallet4 = newWallet;
    }

    function updateTeamWallet5(address newWallet) external onlyOwner {
        teamWallet5 = newWallet;
    }


    function updateTokenAddress(address newTokenAddress) external onlyOwner {
        token = IERC20(newTokenAddress);
    }

    function splitTokens() external {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No balance to split");

        uint256 share = balance / 5;

        require(token.transfer(teamWallet1, share), "Transfer failed");
        require(token.transfer(teamWallet2, share), "Transfer failed");
        require(token.transfer(teamWallet3, share), "Transfer failed");
        require(token.transfer(teamWallet4, share), "Transfer failed");
        require(token.transfer(teamWallet5, share), "Transfer failed");
    }

    function splitEth() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether balance to split");

        uint256 share = balance / 5;

        payable(teamWallet1).transfer(share);
        payable(teamWallet2).transfer(share);
        payable(teamWallet3).transfer(share);
        payable(teamWallet4).transfer(share);
        payable(teamWallet5).transfer(share);
    }

    function withdrawStuckEth() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success);
    }

    function withdrawStuckToken(
        address _token,
        address _to
    ) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _contractBalance);
    }
    function splitOtherTokens(address tokenAddress) external {
        IERC20 _token = IERC20(tokenAddress);
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "No balance to split");

        uint256 share = balance / 5;

        require(_token.transfer(teamWallet1, share), "Transfer failed");
        require(_token.transfer(teamWallet2, share), "Transfer failed");
        require(_token.transfer(teamWallet3, share), "Transfer failed");
        require(_token.transfer(teamWallet4, share), "Transfer failed");
        require(_token.transfer(teamWallet5, share), "Transfer failed");
    }

}
