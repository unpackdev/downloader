// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;
pragma abicoder v2;

import "IERC20.sol";
import "IERC721Receiver.sol";
import "Ownable.sol";


import "INonfungiblePositionManager.sol";


contract TimelockV3 is Ownable, IERC721Receiver {

    struct depositInfo {
        address depositor;
        address beneficiary;
        address token;
        uint256 tokenID;
        uint releaseTime;
        bool activeLock;
        uint256 token0Collected;
        uint256 token1Collected;
    }

    struct depositParameters {
        address token;
        uint256 tokenID;
    }

    bool internal lock;
    string private _name = "TimelockV3";

    address payable private _owner;
    address private edithContractAddress = address(0);

    uint256 private edithRequired = 1250*10**5;
    uint256 private totalEdithCollected = 0;
    mapping (address => mapping (address => mapping(uint256 => depositInfo))) private deposited;

    mapping (address => depositParameters[]) private depositsRecord;  //for reading deposit history
    

    mapping (address => uint256) private tokenDepoistBalances;
    mapping (address => uint256) private creditsAvailable;


    constructor() {
        _owner = msg.sender;
    }

    modifier nonReentrant() {
        require(!lock, "no reentrancy allowed");
        lock = true;
        _;
        lock = false;
    }

    receive() external payable {}

    function name() public view returns(string memory){
        return _name;
    }

    function getOwner() public view returns(address) {
        return _owner;
    }

    function setOwner(address payable newOwner) external onlyOwner returns(bool) {
        _owner = newOwner;
        return true;
    }

    function getNumberOfDeposits(address beneficiary) public view returns(uint256) {
        return depositsRecord[beneficiary].length;
    }

    function getDepositRecord(address beneficiary, uint256 depositNumber) public view returns(address, address, uint256, uint256, bool, uint256, uint256){
        uint256 depositsLength = getNumberOfDeposits(beneficiary);
        require(depositNumber < depositsLength, "deposit number is too high!");
        depositParameters memory thisDP = depositsRecord[beneficiary][depositNumber];

        depositInfo memory DI = deposited[beneficiary][thisDP.token][thisDP.tokenID];

        return(DI.depositor, DI.token, DI.tokenID, DI.releaseTime, DI.activeLock, DI.token0Collected, DI.token1Collected);
    }

    
    function setEdithContractAddress(address newAddress) public onlyOwner {
        edithContractAddress = newAddress;
    }

    function getEdithContractAddress() public view returns(address) {
        return edithContractAddress;
    }

    function setEdithRequired(uint256 amount) public onlyOwner returns(bool) {
        edithRequired = amount;
        return true;
    }

    function getEdithRequired(address account) public view returns(uint256) {
        if (account == _owner){
            return 0;
        } else {
            return edithRequired;
        }
    }

    //transfers all edith credits to the contract owner
    function loadCredits(uint256 amount) public nonReentrant returns(bool) {
        bool success;
        //if (msg.sender != _owner){
        success = IERC20(edithContractAddress).transferFrom(msg.sender, _owner, amount);
        if (success){
            creditsAvailable[msg.sender] += amount;
            totalEdithCollected += amount;
        }
        //} 
        return true;
    }

    function getLoadedCredits(address account) public view returns(uint256) {
        return creditsAvailable[account];
    }

    function getTotalEdithCollected() public view returns(uint256) {
        return totalEdithCollected;
    }

    function deposit(address beneficiary, address token, uint256 tokenID, uint256 delayTime) public nonReentrant returns(bool){
        //demand credits unless edithContract address is set to zero or if caller is owner or if edithRrquired == 0
        if (edithContractAddress != address(0) && msg.sender != _owner && edithRequired > 0){
            require(creditsAvailable[msg.sender] >= edithRequired, "you need more edith credits deposited");
            creditsAvailable[msg.sender] -= edithRequired;
        }
        depositInfo memory DI;
        DI = deposited[beneficiary][token][tokenID];
        require (DI.activeLock ==  false, "already has an active lock!");

        //push new deposit record if DI is empty. If DI.depositor != zero address, then this LP has already been locked before.
        if (DI.depositor == address(0)) {
            depositsRecord[beneficiary].push(depositParameters(token, tokenID));
        }

        uint256 releaseTime = block.timestamp + delayTime;

        DI = depositInfo(msg.sender, beneficiary, token, tokenID, releaseTime, true, 0, 0);
        deposited[beneficiary][token][tokenID] = DI;

        INonfungiblePositionManager(token).safeTransferFrom(msg.sender, address(this), tokenID);

        return true;
    }

    function canWithdraw(address beneficiary, address token, uint256 tokenID) public view returns(bool) {
        depositInfo memory DI;
        DI = deposited[beneficiary][token][tokenID];
        if (DI.activeLock == true && block.timestamp >= DI.releaseTime){
            return true;
        }
        return false;
    }

    function getCurrentTimestamp() public view returns(uint256) {
        return block.timestamp;
    }

    function withdraw(address token, uint256 tokenID) public nonReentrant returns(bool) {
        depositInfo memory DI;
        DI = deposited[msg.sender][token][tokenID];
        require (DI.activeLock == true, "nothing deposited.");
        require (block.timestamp >= DI.releaseTime, "too early to release!");
        //require (DI.beneficiary == msg.sender, "you are not the beneficiary");

        INonfungiblePositionManager(token).safeTransferFrom(address(this), msg.sender, tokenID);

        deposited[msg.sender][token][tokenID].activeLock = false;
        return true;
    }

    function collectV3Fees(address token, uint256 tokenID) public nonReentrant returns(uint256, uint256) {
        depositInfo memory DI = deposited[msg.sender][token][tokenID];

        require(DI.activeLock, "no lock in place!");
        INonfungiblePositionManager.CollectParams memory collectParams;
        collectParams = INonfungiblePositionManager.CollectParams(tokenID, msg.sender, 2**128-1, 2**128-1);

        (uint256 token0Amt, uint256 token1Amt) = INonfungiblePositionManager(token).collect(collectParams);
        deposited[msg.sender][token][tokenID].token0Collected += token0Amt;
        deposited[msg.sender][token][tokenID].token1Collected += token1Amt;
        
        return (token0Amt, token1Amt);
    }

    function onERC721Received(
        address, 
        address, 
        uint256, 
        bytes calldata
    )external override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    } 
}
