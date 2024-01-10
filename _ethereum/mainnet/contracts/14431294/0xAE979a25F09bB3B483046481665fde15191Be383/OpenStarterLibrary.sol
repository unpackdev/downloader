// SPDX-License-Identifier: LicenseRef-StarterLabs-Business-Source
/*
-----------------------------------------------------------------------------
The Licensed Work is (c) 2022 Starter Labs, LLC
Licensor:             Starter Labs, LLC
Licensed Work:        OpenStarter v1
Effective Date:       2022 March 1
Full License Text:    https://github.com/StarterXyz/LICENSE
-----------------------------------------------------------------------------
 */
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

interface IOpenStarterStaking {
    function accounts(address)
        external
        view
        returns (
            uint256[15] memory,
            uint256,
            uint256,
            uint256
        );

    function getUserBalances(address) external view returns (uint256[] memory);

    function getStakerTier(address) external view returns (uint256);
}

interface IExternalStaking {
    function balanceOf(address) external view returns (uint256);
}

contract OpenStarterLibrary is Ownable {
    using SafeMath for uint256;

    uint256[15][10] private tiers; // tiers[0][] is APE; tiers[1][] is START;

    // Archeologist:    20K+ START OR 10K APE for 14+ days
    // Conservator:     10K+ START OR 1K APE for 10+ days
    // Researcher:      1K+ START OR 100 APE for 7+ days
    // Navigator:       100+ START OR 10 APE for 5+ days
    // Lottery:         <Navigator or no staking at all

    mapping(address => bool) private starterDevs;

    IOpenStarterStaking public openStarterStakingPool;
    IExternalStaking public externalStaking;

    address private nftFactoryAddress;
    address private saleFactoryAddress;
    address private vaultFactoryAddress;

    address[] public nfts;
    address[] public sales;

    uint256 private devFeePercentage = 10; // 10% dev fee for INOs

    address private WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 private allocationCount = 4;
    uint256[] private allocationPercentage = [5, 10, 20, 30, 35];
    uint256[] private allocationTime = [30 * 60, 60 * 60, 90 * 60, 120 * 60];

    uint256[15] private minVoterBalance = [
        10 * 1e18,
        100 * 1e18,
        100000 * 1e18
    ]; // min APE needed to vote
    uint256[15] private minYesVotesThreshold = [
        10000000 * 1e18,
        100000 * 1e18,
        100000000000 * 1e18
    ]; // min YES votes needed to pass
    uint256 private externalTokenIndex = 0;

    string public featured; // ipfs link for featured projects list
    string public upcomings; // ipfs link for upcoming projects list
    string public finished; // ipfs link for finished projects list

    constructor(address _openStarterStakingPool, address _externalStaking)
        public
    {
        openStarterStakingPool = IOpenStarterStaking(_openStarterStakingPool);
        externalStaking = IExternalStaking(_externalStaking);

        starterDevs[address(0xf7e925818a20E5573Ee0f3ba7aBC963e17f2c476)] = true;
        starterDevs[address(0x283B3b8f340E8FB94D55b17E906744a74074cD07)] = true;

        tiers[0][0] = 10 * 1e18; // tiers: 10+ APE, 100+ APE, 1K+ APE, 10K+ APE
        tiers[0][1] = 100 * 1e18;
        tiers[0][2] = 1000 * 1e18;
        tiers[0][3] = 10000 * 1e18;

        tiers[1][0] = 100 * 1e18; // tiers: 100+ START, 1K+ START, 10K+ START, 20K+ START
        tiers[1][1] = 1000 * 1e18;
        tiers[1][2] = 10000 * 1e18;
        tiers[1][3] = 20000 * 1e18;
    }

    modifier onlyStarterDev() {
        require(
            owner == msg.sender || starterDevs[msg.sender],
            "onlyStarterDev"
        );
        _;
    }

    modifier onlyFactory() {
        require(
            owner == msg.sender ||
                starterDevs[msg.sender] ||
                nftFactoryAddress == msg.sender ||
                saleFactoryAddress == msg.sender,
            "onlyFactory"
        );
        _;
    }

    function getTier(uint256 tokenIndex, uint256 tierIndex)
        external
        view
        returns (uint256)
    {
        return tiers[tokenIndex][tierIndex];
    }

    function setTier(
        uint256 tokenIndex,
        uint256 tierIndex,
        uint256 _value
    ) external onlyStarterDev {
        tiers[tokenIndex][tierIndex] = _value;
    }

    function getUserTier(uint256 stakingTokenIndex, uint256 amount)
        external
        view
        returns (uint256)
    {
        uint256 i = 0;
        uint256 tier = 0;
        uint256 tiersLen = tiers[stakingTokenIndex].length;
        for (i = 0; i < tiersLen; i++) {
            if (
                amount >= tiers[stakingTokenIndex][i] &&
                tiers[stakingTokenIndex][i] > 0
            ) {
                tier = i + 1;
            } else {
                break;
            }
        }
        return tier;
    }

    function getStarterDev(address _dev) external view returns (bool) {
        return starterDevs[_dev];
    }

    function setStarterDevAddress(address _newDev) external onlyOwner {
        starterDevs[_newDev] = true;
    }

    function removeStarterDevAddress(address _oldDev) external onlyOwner {
        starterDevs[_oldDev] = false;
    }

    function getNftFactoryAddress() external view returns (address) {
        return nftFactoryAddress;
    }

    function setNftFactoryAddress(address _newFactoryAddress)
        external
        onlyStarterDev
    {
        nftFactoryAddress = _newFactoryAddress;
    }

    function getSaleFactoryAddress() external view returns (address) {
        return saleFactoryAddress;
    }

    function setSaleFactoryAddress(address _newFactoryAddress)
        external
        onlyStarterDev
    {
        saleFactoryAddress = _newFactoryAddress;
    }

    function getVaultFactoryAddress() external view returns (address) {
        return vaultFactoryAddress;
    }

    function setVaultFactoryAddress(address _newFactoryAddress)
        external
        onlyStarterDev
    {
        vaultFactoryAddress = _newFactoryAddress;
    }

    function addNfts(address _nftAddress)
        external
        onlyFactory
        returns (uint256)
    {
        nfts.push(_nftAddress);
        return nfts.length - 1;
    }

    function addSaleAddress(address _saleAddress)
        external
        onlyFactory
        returns (uint256)
    {
        sales.push(_saleAddress);
        return sales.length - 1;
    }

    function addSales(address[] calldata _saleAddresses) external onlyFactory {
        uint256 salesLen = _saleAddresses.length;
        for (uint256 i = 0; i < salesLen; i++) {
            sales.push(_saleAddresses[i]);
        }
    }

    function setNftAddress(uint256 _index, address _nftAddress)
        external
        onlyFactory
    {
        nfts[_index] = _nftAddress;
    }

    function setSaleAddress(uint256 _index, address _saleAddress)
        external
        onlyFactory
    {
        sales[_index] = _saleAddress;
    }

    function getStakingPool() external view returns (address) {
        return address(openStarterStakingPool);
    }

    function setStakingPool(address _openStarterStakingPool)
        external
        onlyStarterDev
    {
        openStarterStakingPool = IOpenStarterStaking(_openStarterStakingPool);
    }

    function getExternalStaking() external view returns (address) {
        return address(externalStaking);
    }

    function setExternalStaking(address _openStarterStakingPool)
        external
        onlyStarterDev
    {
        externalStaking = IExternalStaking(_openStarterStakingPool);
    }

    function getNftsCount() external view returns (uint256) {
        return nfts.length;
    }

    function getNftAddress(uint256 nftId) external view returns (address) {
        return nfts[nftId];
    }

    function getSalesCount() external view returns (uint256) {
        return sales.length;
    }

    function getSaleAddress(uint256 saleId) external view returns (address) {
        return sales[saleId];
    }

    function getDevFeePercentage() external view returns (uint256) {
        return devFeePercentage;
    }

    function setDevFeePercentage(uint256 _devFeePercentage)
        external
        onlyStarterDev
    {
        devFeePercentage = _devFeePercentage;
    }

    function getWETH() external view returns (address) {
        return WETH;
    }

    function setWETH(address _WETH) external onlyStarterDev {
        WETH = _WETH;
    }

    function getAllocationCount() external view returns (uint256) {
        return allocationCount;
    }

    function setAllocationCount(uint256 _count) external onlyStarterDev {
        allocationCount = _count;
    }

    function getAllocationPercentage(uint256 _index)
        external
        view
        returns (uint256)
    {
        return allocationPercentage[_index];
    }

    function setAllocationPercentage(uint256 _index, uint256 _value)
        external
        onlyStarterDev
    {
        allocationPercentage[_index] = _value;
    }

    function getAllocationTime(uint256 _index) external view returns (uint256) {
        return allocationTime[_index];
    }

    function setAllocationTime(uint256 _index, uint256 _value)
        external
        onlyStarterDev
    {
        allocationTime[_index] = _value;
    }

    function getStaked(address _sender, uint256 _voteTokenIndex)
        external
        view
        returns (uint256)
    {
        uint256[] memory balances = openStarterStakingPool.getUserBalances(
            _sender
        );
        uint256 externalBalance = 0;
        if (
            address(externalStaking) !=
            0x0000000000000000000000000000000000000000 &&
            _voteTokenIndex == externalTokenIndex // only include outside bal if its the votetoken
        ) {
            externalBalance = externalStaking.balanceOf(_sender);
        }
        return balances[_voteTokenIndex] + externalBalance;
    }

    function getStakerTier(address _staker) external view returns (uint256) {
        return openStarterStakingPool.getStakerTier(_staker);
    }

    function getMinVoterBalance(uint256 _voteTokenIndex)
        external
        view
        returns (uint256)
    {
        return minVoterBalance[_voteTokenIndex];
    }

    function setMinVoterBalance(uint256 _voteTokenIndex, uint256 _balance)
        external
        onlyStarterDev
    {
        minVoterBalance[_voteTokenIndex] = _balance;
    }

    function getMinYesVotesThreshold(uint256 _voteTokenIndex)
        external
        view
        returns (uint256)
    {
        return minYesVotesThreshold[_voteTokenIndex];
    }

    function setMinYesVotesThreshold(uint256 _voteTokenIndex, uint256 _balance)
        external
        onlyStarterDev
    {
        minYesVotesThreshold[_voteTokenIndex] = _balance;
    }

    function getTierByTime(uint256 _openTime, uint256 _currentTimestamp)
        external
        view
        returns (uint256)
    {
        if (
            _currentTimestamp >= _openTime &&
            _currentTimestamp <= _openTime + allocationTime[0]
        ) {
            return 4;
        }
        for (uint256 i = 0; i < allocationCount - 1; i++) {
            if (
                _currentTimestamp > _openTime + allocationTime[i] &&
                _currentTimestamp <= _openTime + allocationTime[i + 1]
            ) {
                return allocationCount - i - 1;
            }
        }
        return 0;
    }

    function setFeaturedProjects(string memory _url) external onlyStarterDev {
        featured = _url;
    }

    function setUpcomingProjects(string memory _url) external onlyStarterDev {
        upcomings = _url;
    }

    function setFinishedProjects(string memory _url) external onlyStarterDev {
        finished = _url;
    }

    function getExternalTokenIndex() external view returns (uint256) {
        return externalTokenIndex;
    }

    function setExternalTokenIndex(uint256 _index) external onlyStarterDev {
        externalTokenIndex = _index;
    }

    function getExternalStaked(uint256 tokenIndex, address _staker)
        external
        view
        returns (uint256)
    {
        if (tokenIndex != externalTokenIndex) return 0;
        if (
            address(externalStaking) ==
            0x0000000000000000000000000000000000000000
        ) return 0;
        return externalStaking.balanceOf(_staker);
    }
}
