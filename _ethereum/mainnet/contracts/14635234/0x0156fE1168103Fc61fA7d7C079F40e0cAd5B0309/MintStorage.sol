// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;

import "./IERC20.sol";
import "./MintLogic.sol";
import "./Initializable.sol";
import "./MintLogicProxy.sol";

contract MintStorage is Initializable {

    address public owner;
    address public logicAddr;
    address[] public mintProxys;

    constructor() public initializer {}

    modifier onlyOwner() {
        require(owner == msg.sender, "MintProxy: caller is not the owner");
        _;
    }

    function initialize() public initializer {
        owner = msg.sender;
    }

    function setLogicAddr(address _logicAddr) external onlyOwner {
        logicAddr = _logicAddr;
    }

    function createProxys(uint256 _amount) external onlyOwner {
        for(uint i = 0; i < _amount; i++){
            MintLogicProxy mintProxy = new MintLogicProxy(logicAddr, address(this), abi.encodeWithSignature("initialize(address)", address(this)));
            mintProxys.push(address(mintProxy));
        }
    }

    function execute(uint256 _amount, address _contolAddr, address _nftAddr, uint256 _price, bytes memory _data) external payable {
        for(uint i = 0; i < _amount; i++){
            MintLogic mintLogic = MintLogic(mintProxys[i]);
            try mintLogic.execute{value : _price}(_contolAddr, _nftAddr, _price, _data) {
                continue;
            } catch (bytes memory) {
                break;
            }
        }
        if(address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }

    function fetchBalance(uint256 _amount) public {
        require(msg.sender != tx.origin, "require contract");
        msg.sender.transfer(_amount);
    }

    function fetchToken(address _tokenAddr, uint256 _amount) public {
        require(msg.sender != tx.origin, "require contract");
        IERC20(_tokenAddr).transfer(msg.sender, _amount);
    }

}