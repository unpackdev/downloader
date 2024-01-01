// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

import "./console.sol";

contract FireBotRouter is Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    uint256 public swapFee = 10; // divided 1000
    uint256 public mmFee = 1;
    uint256 public teamFee = 6; // divided 10
    address public teamWallet;
    IERC20 public fireBot;

    uint256 public holderRewards = 0;
    uint256 private totalClaimed = 0;
    uint256 public minShareBalance = 200;

    struct User {
        uint256 claimed;
        uint256[] claimedBlocks;
        uint256[] claimedAmounts;
    }

    mapping(address => User) users;

    constructor(
        IUniswapV2Router02 _uniswapV2Router,
        address _teamWallet,
        IERC20 _fireBot
    ) {
        // Create a uniswap pair for this new token
        // uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        //     .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        teamWallet = _teamWallet;
        fireBot = _fireBot;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    // owner functions
    function updateTeamWallet(address _teamWallet) public onlyOwner {
        teamWallet = _teamWallet;
    }

    function updateMMFee(uint256 _mmFee) public onlyOwner {
        mmFee = _mmFee;
    }

    function updateSwapFee(uint256 _swapFee) public onlyOwner {
        swapFee = _swapFee;
    }

    function updateTeamFee(uint256 _teamFee) public onlyOwner {
        teamFee = _teamFee;
    }

    function updateMinShareBalance(uint256 _minShareBalance) public onlyOwner {
        minShareBalance = _minShareBalance;
    }

    function updateFireBot(address _fireBot) public onlyOwner {
        fireBot = IERC20(_fireBot);
    }

    // user functions
    function claimableAmount(
        address account
    ) public view returns (uint256 userRewards) {
        if (fireBot.balanceOf(account) < minShareBalance) {
            userRewards = 0;
        } else {
            User storage currentUser = users[account];
            userRewards = holderRewards.mul(fireBot.balanceOf(account)).div(fireBot.totalSupply()).sub(currentUser.claimed);
        }
    }

    function cliamRewards() public {
        require(
            fireBot.balanceOf(msg.sender) >= minShareBalance,
            "Invalid balance"
        );
        User storage currentUser = users[msg.sender];
        uint256 claimable = claimableAmount(msg.sender);
        currentUser.claimed += claimable;
        currentUser.claimedBlocks.push(block.timestamp);
        currentUser.claimedAmounts.push(claimable);
        totalClaimed += claimable;
        payable(msg.sender).transfer(claimableAmount(msg.sender));
    }

    // swap functions
    function swapEthForTokens(address[] memory path) public payable {
        require(msg.value > 0, "Invalid amount.");
        uint256 amount = msg.value;
        uint256 teamFeeAmount = amount.mul(teamFee).mul(swapFee).div(10000);
        uint256 realAmount = amount.sub(amount.mul(swapFee).div(1000));
        uint256 revenuAmount = amount.mul(swapFee).div(1000).sub(teamFeeAmount);
        holderRewards += revenuAmount;
        // send fee
        payable(teamWallet).transfer(teamFeeAmount);
        // swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: realAmount
        }(0, path, msg.sender, block.timestamp);
    }

    function swapTokensForEth(
        uint256 tokenAmount,
        address[] memory path
    ) public {
        // fetch tokens
        IERC20 token = IERC20(path[0]);
        token.transferFrom(msg.sender, address(this), tokenAmount);
        // approve
        token.approve(address(uniswapV2Router), tokenAmount);
        uint256 initialBalance = address(this).balance;
        // swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 receivedAmount = address(this).balance.sub(initialBalance);
        // send fee
        uint256 teamFeeAmount = receivedAmount.mul(teamFee).mul(swapFee).div(
            10000
        );
        uint256 realAmount = receivedAmount.sub(
            receivedAmount.mul(swapFee).div(1000)
        );
        uint256 revenuAmount = receivedAmount.mul(swapFee).div(1000).sub(
            teamFeeAmount
        );
        holderRewards += revenuAmount;
        payable(teamWallet).transfer(teamFeeAmount);
        payable(msg.sender).transfer(realAmount);
    }

    function swapEthForTokensForMM(
        address[] memory path,
        uint256 _nonce,
        bytes memory signature
    ) public payable {
        require(msg.value > 0, "Invalid amount.");
        bytes32 messageHash = getMessageHash(msg.sender, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        require(recoverSigner(ethSignedMessageHash, signature) == owner());
        uint256 amount = msg.value;
        uint256 teamFeeAmount = amount.mul(teamFee).mul(mmFee).div(10000);
        uint256 realAmount = amount.sub(amount.mul(mmFee).div(1000));
        uint256 revenuAmount = amount.mul(swapFee).div(1000).sub(teamFeeAmount);
        holderRewards += revenuAmount;
        // send fee
        payable(teamWallet).transfer(teamFeeAmount);
        // swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: realAmount
        }(0, path, msg.sender, block.timestamp);
    }

    function swapTokensForEthForMM(
        uint256 tokenAmount,
        address[] memory path,
        uint256 _nonce,
        bytes memory signature
    ) public {
        bytes32 messageHash = getMessageHash(msg.sender, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        require(recoverSigner(ethSignedMessageHash, signature) == owner());
        // fetch tokens
        IERC20 token = IERC20(path[0]);
        token.transferFrom(msg.sender, address(this), tokenAmount);
        // approve
        token.approve(address(uniswapV2Router), tokenAmount);

        uint256 initialBalance = address(this).balance;
        // swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 receivedAmount = address(this).balance.sub(initialBalance);
        // send fee
        uint256 teamFeeAmount = receivedAmount.mul(teamFee).mul(mmFee).div(
            10000
        );
        uint256 realAmount = receivedAmount.sub(
            receivedAmount.mul(mmFee).div(1000)
        );
        uint256 revenuAmount = receivedAmount.mul(swapFee).div(1000).sub(
            teamFeeAmount
        );
        holderRewards += revenuAmount;
        payable(teamWallet).transfer(teamFeeAmount);
        payable(msg.sender).transfer(realAmount);
    }

    function getMessageHash(
        address account,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return sha256(abi.encodePacked(account, _nonce));
    }

    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}
