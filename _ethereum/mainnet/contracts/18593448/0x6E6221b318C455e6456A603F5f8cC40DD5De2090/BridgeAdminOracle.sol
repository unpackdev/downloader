// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./Ownable.sol";
import "./IBridgeAdminOracle.sol";

contract BridgeAdminOracle is Ownable, IBridgeAdminOracle {
    uint256 public fee;
    address payable private feeReceiver;
    address public token;
    mapping(uint64 => bool) public allowedChains;

    event FeeChanged(uint256 newFee);
    event ChainAdded(uint64 chainId);
    event FeeReceiverChanged(address newFeeReceiver);

    constructor (uint256 _fee, uint64[] memory _allowedChains, address payable _feeReceiver, address _token) {
        fee = _fee;
        feeReceiver = _feeReceiver;
        token = _token;
        for (uint i = 0; i < _allowedChains.length; i++) {
            allowedChains[_allowedChains[i]] = true;
        }
    }

    //NEED THIS FOR THE INTERFACE TO USE IN FEECOLLECTOR
    function getFee() external view returns (uint256) {
        return fee;
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit FeeChanged(_fee);
    }

    function getFeeReceiver() external view returns (address) {
        return feeReceiver;
    }

    function setFeeReceiver(address payable _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
        emit FeeReceiverChanged(_feeReceiver);
    }

    function addChain(uint64 _chainId) external onlyOwner {
        allowedChains[_chainId] = true;
        emit ChainAdded(_chainId);
    }

    function checkChain(uint64 chainId) public view returns(bool) {
        return allowedChains[chainId];
    }

    function checkToken(address _token) public view returns(bool){
        return token == _token;
    }
}

