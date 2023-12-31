// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "./Ownable.sol";
import "./IERC20.sol";

contract FT500TeamTokenSplitter is Ownable {

    address public teamWallet1;
    address public teamWallet2;
    address public teamWallet3;
    address public teamWallet4;

    address[] public devWallets;
    address[] _tmpWallets;

    IERC20 public token;

    constructor() {
        teamWallet1 = 0xB006fCDAe73736aEe3f14B9a3645cf24aFA781f0;
        teamWallet2 = 0xE4d03628F8697C1114eeDa05069e6B1CA34d6fdc;
        teamWallet3 = 0x2dF22069f3eaBA355bE785831140360AE5303fe4;
        teamWallet4 = 0x04f2Cbcb7cd992d2166C3597403D2B59CE7612B5;
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

    function updateTokenAddress(address newTokenAddress) external onlyOwner {
        token = IERC20(newTokenAddress);
    }

    function updateDevWallets(address[] memory _devWallets) external onlyOwner {
        devWallets = _devWallets;
    }

    function splitTokens() external {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No balance to split");

        
        _tmpWallets = devWallets;
        _tmpWallets.push(teamWallet1);
        _tmpWallets.push(teamWallet2);
        _tmpWallets.push(teamWallet3);
        _tmpWallets.push(teamWallet4);

        uint256 share = balance / _tmpWallets.length;

        for (uint256 i = 0; i < _tmpWallets.length; i++) {
            require(_tmpWallets[i] != address(0), "Invalid wallet address");
            
            require(token.transfer(_tmpWallets[i], share), "Transfer failed");
        }
    }

    function splitEth() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether balance to split");

        _tmpWallets = devWallets;
        _tmpWallets.push(teamWallet1);
        _tmpWallets.push(teamWallet2);
        _tmpWallets.push(teamWallet3);
        _tmpWallets.push(teamWallet4);

        uint256 share = balance / _tmpWallets.length;

        for (uint256 i = 0; i < _tmpWallets.length; i++) {
            require(_tmpWallets[i] != address(0), "Invalid wallet address");
            
            (bool success, ) = _tmpWallets[i].call{value: share}("");
            require(success);
        }
    }

    function splitOtherTokens(address tokenAddress) external {
        IERC20 _token = IERC20(tokenAddress);
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "No balance to split");

        _tmpWallets = devWallets;
        _tmpWallets.push(teamWallet1);
        _tmpWallets.push(teamWallet2);
        _tmpWallets.push(teamWallet3);
        _tmpWallets.push(teamWallet4);

        uint256 share = balance / _tmpWallets.length;

        for (uint256 i = 0; i < _tmpWallets.length; i++) {
            require(_tmpWallets[i] != address(0), "Invalid wallet address");
            
            require(_token.transfer(_tmpWallets[i], share), "Transfer failed");
        }
    }

    function getDevWallets() public view returns (address[] memory){
        return devWallets;
    }
}
