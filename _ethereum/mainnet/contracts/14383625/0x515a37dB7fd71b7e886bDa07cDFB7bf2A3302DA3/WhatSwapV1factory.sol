// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./WhatSwapV1Pool.sol";


contract WhatSwapV1factory is Ownable {
    using SafeERC20 for IERC20;

    address public feeTo;
    address public pairContract;
    uint public totalPairs;

    uint public lpFee; // for  0.1 % => 10
    uint private FLASHLOAN_FEE_TOTAL = 1; // for  0.01 % => 1
    uint private FLASHLOAN_FEE_PROTOCOL = 4000; // for  40.00 % => 4000

    mapping(address => address) public getPair;

    event feeToUpdated(address previousFeeTo, address newFeeTo);
    event lpFeeUpdated(uint previousFee, uint newFee);
    event PairCreated(address indexed tokenAddress, address pair, uint);
    event flashLoanFeeUpdated(uint flashloan_fee_total, uint flashloan_fee_protocol);

    constructor() {
        setup();
    }
    
    function getFlashLoanFeesInBips() public view returns (uint, uint) {
        return (FLASHLOAN_FEE_TOTAL, FLASHLOAN_FEE_PROTOCOL);
    }

    function setup() internal {
        feeTo = msg.sender;
        pairContract = address(new WhatSwapV1Pool());
    }

    function createPair(address tokenAddress) public returns (address pair) {
        require(tokenAddress != address(0), 'WhatSwapV1: ZERO_ADDRESS');
        require(getPair[tokenAddress] == address(0), 'WhatSwapV1: PAIR_EXISTS');

        bytes32 salt = keccak256(abi.encodePacked(tokenAddress));
        bytes20 pairBytes = bytes20(pairContract);
        
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), pairBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            pair := create2(0, clone, 0x37, salt)
        }

        WhatSwapV1Pool(pair).initialize(tokenAddress);
        getPair[tokenAddress] = pair;
        totalPairs = totalPairs + 1;
        emit PairCreated(tokenAddress, pair, totalPairs);
    }

    function createPairWithAddLP(address tokenAddress, uint amount0min, uint amount1, address to, uint deadline) payable external returns (address pair, uint lpAmount) {
        pair = getPair[tokenAddress];
        if(pair == address(0)){ pair = createPair(tokenAddress); }
        lpAmount = WhatSwapV1Pool(pair).addLPfromFactory{value: msg.value}(amount0min, amount1, msg.sender, to, deadline);
    }
    
    function flashLoan(address _receiver, address _poolToken, bool _takeEth, uint _amount, bytes calldata _params) external {
        require(_poolToken != address(0), 'WhatSwapV1: ZERO_ADDRESS');
        address pair = getPair[_poolToken];
        require(pair != address(0), 'WhatSwapV1: PAIR_NOT_FOUND');
        WhatSwapV1Pool(pair).flashLoan(_receiver, _takeEth, _amount, _params);
    }
    
    function changeFeeTo(address _feeTo) external onlyOwner {
        require(_feeTo != address(0), 'WhatSwapV1: ZERO_ADDRESS');
        emit feeToUpdated(feeTo, _feeTo);
        feeTo = _feeTo;
    }
    
    function changeLpFee(uint _newFee) external onlyOwner {
        require(_newFee < 1000, 'WhatSwapV1: INVALID_FEE');
        emit lpFeeUpdated(lpFee, _newFee);
        lpFee = _newFee;
    }
    
    function setFlashLoanFeesInBips(uint _newFeeTotal, uint _newFeeProtocol) external onlyOwner {
        require(_newFeeTotal > 0 && _newFeeTotal < 10000, 'WhatSwapV1: INVALID_TOTAL_FEE_RANGE');
        require(_newFeeProtocol > 0 && _newFeeProtocol < 10000, 'WhatSwapV1: INVALID_PROTOCOL_FEE_RANGE');
        FLASHLOAN_FEE_TOTAL = _newFeeTotal;
        FLASHLOAN_FEE_PROTOCOL = _newFeeProtocol;
        emit flashLoanFeeUpdated(_newFeeTotal, _newFeeProtocol);
    }
    
    function rescueTokens(address tokenAddress, address to) external onlyOwner {
        require(tokenAddress != address(0), 'WhatSwapV1: ZERO_ADDRESS');
        require(tokenAddress != to, 'WhatSwapV1: IDENTICAL_ADDRESSES');

        IERC20(tokenAddress).safeTransfer(to, IERC20(tokenAddress).balanceOf(address(this)));
    }
    
    function rescueEth(address to) external onlyOwner {
        require(to != address(0), 'WhatSwapV1: ZERO_ADDRESS');
        (bool success, ) = to.call{value: address(this).balance}(new bytes(0));
        require(success, 'WhatSwapV1: ETH_TXN_FAILED');
    }
}