// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./interface.sol";

contract LessLibrary is Ownable {
    address public usd;
    address[] public factoryAddress = new address[](2);

    uint256 private minInvestorBalance = 1000 * 1e18;
    uint256 private votingTime = 5 minutes; //three days
    uint256 private registrationTime = 5 minutes; // one day
    uint256 private minVoterBalance = 500 * 1e18; // minimum number of  tokens to hold to vote
    uint256 private minCreatorStakedBalance = 10000 * 1e18; // minimum number of tokens to hold to launch rocket
    uint8 private feePercent = 2;
    uint256 private usdFee;
    address private uniswapRouter; // uniswapV2 Router
    address payable private lessVault;
    address private devAddress;
    PresaleInfo[] private presaleAddresses; // track all presales created

    mapping(address=> bool) public stablecoinWhitelist;

    mapping(address => bool) private isPresale;
    mapping(bytes32 => bool) private usedSignature;
    mapping(address => bool) private signers; //adresses that can call sign functions

    struct PresaleInfo {
        bytes32 title;
        address presaleAddress;
        string description;
        bool isCertified;
        uint256 openVotingTime;
    }

    modifier onlyDev() {
        require(owner() == msg.sender || msg.sender == devAddress, "onlyDev");
        _;
    }

    modifier onlyPresale() {
        require(isPresale[msg.sender], "Not presale");
        _;
    }

    modifier onlyFactory() {
        require(factoryAddress[0] == msg.sender || factoryAddress[1] == msg.sender, "onlyFactory");
        _;
    }

    modifier factoryIndexCheck(uint8 _index){
        require(_index == 0 || _index == 1, "Invalid index");
        _;
    }

    constructor(address _dev, address payable _vault, address _uniswapRouter, address _usd, address[] memory _stablecoins, uint8 _usdDecimals) {
        require(_dev != address(0) && _vault != address(0) && _usdDecimals > 0, "Wrong params");
        devAddress = _dev;
        lessVault = _vault;
        uniswapRouter = _uniswapRouter;
        usd = _usd;
        usdFee = 1000 * 10 ** _usdDecimals;
        for(uint256 i=0; i <_stablecoins.length; i++){
            stablecoinWhitelist[_stablecoins[i]] = true;
        }
    }

    function setFactoryAddress(address _factory, uint8 _index) external onlyDev factoryIndexCheck(_index){
        require(_factory != address(0), "not 0");
        factoryAddress[_index] = _factory;
    }

    function setUsdFee(uint256 _newAmount) external onlyDev {
        require(_newAmount > 0, "0 amt");
        usdFee = _newAmount;
    }

    function setUsdAddress(address _newAddress) external onlyDev {
        require(_newAddress != address(0), "0 addr");
        usd = _newAddress;
    }

    function addPresaleAddress(
        address _presale,
        bytes32 _title,
        string memory _description,
        bool _type,
        uint256 _openVotingTime
    )
        external
        onlyFactory
        returns (uint256)
    {
        presaleAddresses.push(PresaleInfo(_title, _presale, _description, _type, _openVotingTime));
        isPresale[_presale] = true;
        return presaleAddresses.length - 1;
    }

    function addOrRemoveStaiblecoin(address _stablecoin, bool _isValid) external onlyDev {
        require(_stablecoin != address(0), "Not 0 addr");
        if(_isValid){
            require(!stablecoinWhitelist[_stablecoin], "Wrong param");
        }
        else {
            require(stablecoinWhitelist[_stablecoin], "Wrong param");
        }
        stablecoinWhitelist[_stablecoin] = _isValid;
    }

    function changeDev(address _newDev) external onlyDev {
        require(_newDev != address(0), "Wrong new address");
        devAddress = _newDev;
    }

    function setVotingTime(uint256 _newVotingTime) external onlyDev {
        require(_newVotingTime > 0, "Wrong new time");
        votingTime = _newVotingTime;
    }

    function setRegistrationTime(uint256 _newRegistrationTime) external onlyDev {
        require(_newRegistrationTime > 0, "Wrong new time");
        registrationTime = _newRegistrationTime;
    }

    function setUniswapRouter(address _uniswapRouter) external onlyDev {
        uniswapRouter = _uniswapRouter;
    }

    function setSingUsed(bytes memory _sign, address _presale) external {
        require(isPresale[_presale], "u have no permition");
        usedSignature[keccak256(_sign)] = true;
    }

    function addOrRemoveSigner(address _address, bool _canSign) external onlyDev {
        signers[_address] = _canSign;
    }

    function getPresalesCount() external view returns (uint256) {
        return presaleAddresses.length;
    }

    function getUsdFee() external view returns(uint256, address) {
        return (usdFee, usd);
    }

    function isValidStablecoin(address _stablecoin) external view returns (bool) {
        return stablecoinWhitelist[_stablecoin];
    }

    function getPresaleAddress(uint256 id) external view returns (address) {
        return presaleAddresses[id].presaleAddress;
    }

    function getVotingTime() external view returns(uint256){
        return votingTime;
    }

    function getRegistrationTime() external view returns(uint256){
        return registrationTime;
    }

    function getMinInvestorBalance() external view returns (uint256) {
        return minInvestorBalance;
    }

    function getDev() external view onlyFactory returns (address) {
        return devAddress;
    }

    function getMinVoterBalance() external view returns (uint256) {
        return minVoterBalance;
    }
    //back!!!
    function getMinYesVotesThreshold(uint256 totalStakedAmount) external pure returns (uint256) {
        uint256 stakedAmount = totalStakedAmount;
        return stakedAmount / 10;
    }

    function getFactoryAddress(uint8 _index) external view factoryIndexCheck(_index) returns (address) {
        return factoryAddress[_index];
    }

    function getMinCreatorStakedBalance() external view returns (uint256) {
        return minCreatorStakedBalance;
    }

    function getUniswapRouter() external view returns (address) {
        return uniswapRouter;
    }

    function calculateFee(uint256 amount) external view onlyPresale returns(uint256){
        return amount * feePercent / 100;
    }

    function getVaultAddress() external view onlyPresale returns(address payable){
        return lessVault;
    }

    function getArrForSearch() external view returns(PresaleInfo[] memory) {
        return presaleAddresses;
    }
    
    function _verifySigner(bytes32 data, bytes memory signature, uint8 _index)
        public
        view
        factoryIndexCheck(_index)
        returns (bool)
    {
        address messageSigner =
            ECDSA.recover(data, signature);
        require(
            isSigner(messageSigner),
            "Unauthorised signer"
        );
        return true;
    }

    function getSignUsed(bytes memory _sign) external view returns(bool) {
        return usedSignature[keccak256(_sign)];
    }

    function isSigner(address _address) internal view returns (bool) {
        return signers[_address];
    }
}
