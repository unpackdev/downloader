/*
 /$$$$$$$$                     /$$$$$$$$                                          /$$          
| $$_____/                    | $$_____/                                         |__/          
| $$        /$$$$$$   /$$$$$$$| $$     /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$      /$$  /$$$$$$ 
| $$$$$    /$$__  $$ /$$_____/| $$$$$ /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$    | $$ /$$__  $$
| $$__/   | $$  \__/| $$      | $$__/| $$  \ $$| $$  \__/| $$  \ $$| $$$$$$$$    | $$| $$  \ $$
| $$      | $$      | $$      | $$   | $$  | $$| $$      | $$  | $$| $$_____/    | $$| $$  | $$
| $$$$$$$$| $$      |  $$$$$$$| $$   |  $$$$$$/| $$      |  $$$$$$$|  $$$$$$$ /$$| $$|  $$$$$$/
|________/|__/       \_______/|__/    \______/ |__/       \____  $$ \_______/|__/|__/ \______/ 
                                                          /$$  \ $$                            
                                                         |  $$$$$$/                            
                                                          \______/                             
*/
//SPDX-License-Identifier: CC-BY-NC-ND
pragma solidity ^0.8.0;

import "./ErcForge1155Template.sol";
import "./IErcForgeInitiable.sol";
import "./ERC1155.sol";

contract ErcForgeDeployer {
    mapping(uint256 => address) private _templateAddresses;
    address public fullDiscountTokenAddress;
    uint256 public fullDiscountTokenId;
    address owner;

    uint256 public fee = 20000000 gwei;
    uint256 public referrerDiscount = 1000000 gwei;
    uint256 public referrerReward = 2000000 gwei;
    
    uint256 public totalReferrerFunds;
    mapping(address => uint256) private _referrerFunds;

    bool public isPaused = false;


    event ContractCreated(address contractAddress);
    

    constructor() {
        owner = msg.sender;
    }


    function setTemplateAddress(uint256 _templateType, address _address) public {
        require(msg.sender == owner, "Not owner");
        _templateAddresses[_templateType] = _address;
    }

    function getTemplateAddress(uint256 _templateType) public view returns(address) {
        require(msg.sender == owner, "Not owner");
        return _templateAddresses[_templateType];
    }

    function setFullDiscountToken(address _address, uint256 _id) public {
        require(msg.sender == owner, "Not owner");
        fullDiscountTokenAddress = _address;
        fullDiscountTokenId = _id;
    }

    function setOwner(address _owner) public {
        require(msg.sender == owner, "Not owner");
        owner = _owner;
    }

    function setFee(uint256 _fee) public {
        require(msg.sender == owner, "Not owner");
        fee = _fee;
    }

    function setReferrerDiscount(uint256 _referrerDiscount) public {
        require(msg.sender == owner, "Not owner");
        referrerDiscount = _referrerDiscount;
    }

    function setReferrerReward(uint256 _referrerReward) public {
        require(msg.sender == owner, "Not owner");
        referrerReward = _referrerReward;
    }

    function setIsPaused(bool _isPaused) public {
        require(msg.sender == owner, "Not owner");
        isPaused = _isPaused;
    }

    function getFee(bool hasReferrer) public view returns (uint256) {
        uint256 tmpFee = fee;
        if (hasReferrer)
            tmpFee -= referrerDiscount;  

        if (fullDiscountTokenAddress != address(0)) {
            ERC1155 fullDiscountToken = ERC1155(fullDiscountTokenAddress);
            if (fullDiscountToken.balanceOf(msg.sender, fullDiscountTokenId) > 0)
                tmpFee = 0;
        }     
        return tmpFee;
    }

    function createContract(uint256 contractType, string memory name, string memory symbol, string memory uri, string memory contractUri, address referrer) public payable returns (address) {
        require(!isPaused, "Paused");
        require(_templateAddresses[contractType] != address(0), "Contract type not defined");
        uint256 tmpFee = getFee(referrer != address(0));
        require(msg.value >= tmpFee, "Not enough funds");

        address clone = createClone(_templateAddresses[contractType]);
        IErcForgeInitiable token = IErcForgeInitiable(clone);
        token.init(msg.sender, name, symbol, uri, contractUri);        
        emit ContractCreated(clone);

        if (referrer != address(0) && tmpFee != 0) {
            _referrerFunds[referrer] += referrerReward;
            totalReferrerFunds += referrerReward;
        }

        return clone;
    }

    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    function withdraw() public {     
        uint256 funds;   
        if (msg.sender == owner)
            funds = address(this).balance - totalReferrerFunds;
        else {
            funds = _referrerFunds[msg.sender];
            totalReferrerFunds -= funds;
            _referrerFunds[msg.sender] = 0;
        }
        payable(msg.sender).transfer(funds);
    }

    function getBalance(address user) public view returns (uint256) {
        if (user == owner)
            return address(this).balance - totalReferrerFunds;
        else
            return _referrerFunds[user];
    }
}
