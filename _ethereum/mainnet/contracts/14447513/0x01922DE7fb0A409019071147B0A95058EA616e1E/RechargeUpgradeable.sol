// SPDX-License-Identifier: MIT
// File: contracts\open-zeppelin-contracts\token\ERC20\IERC20.sol

pragma solidity ^0.8.0;

import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SignatureCheckerUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";


contract RechargeContract is Initializable,OwnableUpgradeable,AccessControlEnumerableUpgradeable,ReentrancyGuardUpgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping (string => address) public contractTokenMap;

    address public signer1;
    address public signer2;

    bytes32 public constant SWITCH = keccak256("SWITCH");

    bytes32 public constant MODIFYCONTRACTTOKEN = keccak256("MODIFYCONTRACTTOKEN");


    event AccountRecharge(address indexed from, address indexed to,address indexed contractAddress, uint256 num);
    event Withdraw(address indexed from, address indexed to,address indexed contractAddress,uint256 num,string orderId,uint256 deadline);

    bool withdrawSwitch;
    bool accountRechargeSwitch;

    mapping(string => uint256) public withdrawHistory;

    function initialize() public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(SWITCH, _msgSender());
        _setupRole(MODIFYCONTRACTTOKEN, _msgSender());

        signer1 = 0x663a6C4e47d80be613c741e2ab920EEA41F49bb7;
        signer2 = 0xE6601Ff38829a201a463fD569d9F87b88F5A3b4b;
        withdrawSwitch = true;
        accountRechargeSwitch = true;
    }

    function grantRoles(bytes32 role, address[] calldata  account) public virtual onlyOwner() {
        for (uint256 i = 0; i < account.length; i++) {
            grantRole(role,account[i]);
        }

    }

    function setSig (address _signer1,address _signer2) public virtual onlyOwner(){
        signer1 = _signer1;
        signer2 = _signer2;
    }

    function modifyContractTokenMap (string memory _tokenName,address _contractTokenAddress) public virtual onlyRole(MODIFYCONTRACTTOKEN) {
        contractTokenMap[_tokenName] = _contractTokenAddress;
    }

    function modifySwitch (bool _withdrawSwitch,bool _accountRechargeSwitch) public virtual onlyRole(SWITCH) {
        withdrawSwitch = _withdrawSwitch;
        accountRechargeSwitch = _accountRechargeSwitch;
    }


    function accountRecharge(string memory _tokenName,uint256 amount) external nonReentrant{
        require (accountRechargeSwitch,"Not yet open");
        require (contractTokenMap[_tokenName] != address(0),"Not yet open");
        require(amount>=0, "Error:amount less zero");
        address contractTokenAddress = contractTokenMap[_tokenName];
        IERC20Upgradeable(contractTokenAddress).transferFrom(_msgSender(),address(this),  amount);
        emit AccountRecharge(_msgSender(),address(this),address(contractTokenAddress),amount);
    }

    function withdraw (string memory _tokenName,uint256 amount,string memory orderId, uint256 deadline, bytes memory signature,bytes memory signature2) external virtual  nonReentrant{
        require (withdrawSwitch,"Not yet open");
        require (contractTokenMap[_tokenName] != address(0),"Not yet open");
        require (withdrawHistory[orderId] == 0,"not repeatable");
        address contractTokenAddress = contractTokenMap[_tokenName];
        address withdrawAddress = _msgSender();
        bytes32 hash1 = keccak256(
            abi.encode(address(this),withdrawAddress,contractTokenAddress,amount,orderId,deadline)
        );
        require (SignatureCheckerUpgradeable.isValidSignatureNow(signer1,ECDSAUpgradeable.toEthSignedMessageHash(hash1),signature),"Signature error");
        require (SignatureCheckerUpgradeable.isValidSignatureNow(signer2,ECDSAUpgradeable.toEthSignedMessageHash(hash1),signature2),"Signature error");
        require (block.timestamp < deadline, "already passed deadline");
        IERC20Upgradeable(contractTokenAddress).transfer(withdrawAddress,amount);
        withdrawHistory[orderId]=block.number;
        emit Withdraw(address(this),withdrawAddress,contractTokenAddress,amount,orderId, deadline);

    }
}