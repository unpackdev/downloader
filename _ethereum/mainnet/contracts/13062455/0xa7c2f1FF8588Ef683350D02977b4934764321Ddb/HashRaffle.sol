// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./VRFConsumerBase.sol";
import "./IUniswapV2Router02.sol";

contract HashRaffle is VRFConsumerBase {
    using SafeMath for uint256;

    bytes32 internal keyHash;
    uint256 internal fee;

    address public dao = 0x6Df748fD1d9154FFAEa6F2F59d369cCaCc1c9F2c;

    event RaffleDone(string fileHash, uint256[] picks);

    // SWAP
    IUniswapV2Router02 public uniswapRouter;
    address LinkToken = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    // Constructor. We set the symbol and name and start with sa
    constructor()
        // address vrf_coord,
        // address link_token,
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
            0x514910771AF9Ca656af840dff83E8264EcF986CA
        )
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee =  2* 10**18; // 2 LINK (Varies by network)

        uniswapRouter = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
    }

    function getPathForETHtoLink() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = LinkToken;

        return path;
    }

    receive() external payable {
        uint256 _balance = address(this).balance;
        require(payable(dao).send(_balance));
    }

    // ----- Randomness functions -----

    struct RaffleRequest {
        string fileHash;
        uint256 numberOfResults;
        uint256 maxValue;
    }

    mapping(bytes32 => RaffleRequest) public randomRequests;

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        RaffleRequest memory request = randomRequests[requestId];
        uint256[] memory picks = expand(
            randomness,
            request.numberOfResults,
            request.maxValue
        );

        emit RaffleDone(request.fileHash, picks);
    }

    // ----- Helper functions -----

    function getFee() external view returns (uint256) {
        return
            uniswapRouter.getAmountsIn(fee, getPathForETHtoLink())[0] +
            10000000000000000;
    }

    function setBaseFee(uint256 _fee) public {
        fee = _fee;
    }

    function Raffle(
        uint256 _number,
        uint256 _max,
        string memory fileHash,
        uint256 _deadline
    ) external payable {
        require(msg.value >= this.getFee(), "incorrect value send");
        require(_max > 1, "maximum value needs to be > 1");
        require(_number > 0, "needs to generate at least one number");

        uniswapRouter.swapETHForExactTokens{value: msg.value}(
            fee,
            getPathForETHtoLink(),
            address(this),
            _deadline
        );

        bytes32 requestId = getRandomNumber();
        RaffleRequest storage request = randomRequests[requestId];
        request.fileHash = fileHash;
        request.maxValue = _max;
        request.numberOfResults = _number;
    }

    function getRandomNumber() public returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    function expand(
        uint256 randomValue,
        uint256 n,
        uint256 max
    ) internal pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] =
                uint256(keccak256(abi.encode(randomValue, i))) %
                max;
        }
        return expandedValues;
    }
}
