pragma solidity 0.5.17;

interface IPeakDeFiFund {
    enum CyclePhase {
        Intermission,
        Manage
    }

    enum VoteDirection {
        Empty,
        For,
        Against
    }

    enum Subchunk {
        Propose,
        Vote
    }

    function initParams(
        address payable _devFundingAccount,
        uint256[2] calldata _phaseLengths,
        uint256 _devFundingRate,
        address payable _previousVersion,
        address _usdcAddr,
        address payable _kyberAddr,
        address _compoundFactoryAddr,
        address _peakdefiLogic,
        address _peakdefiLogic2,
        address _peakdefiLogic3,
        uint256 _startCycleNumber,
        address payable _oneInchAddr,
        address _peakRewardAddr,
        address _peakStakingAddr
    ) external;

    function initOwner() external;

    function cyclePhase() external view returns (CyclePhase phase);

    function isInitialized() external view returns (bool);

    function devFundingAccount() external view returns (uint256);

    function previousVersion() external view returns (uint256);

    function cycleNumber() external view returns (uint256);

    function totalFundsInUSDC() external view returns (uint256);

    function totalFundsAtManagePhaseStart() external view returns (uint256);

    function totalLostFundAmount() external view returns (uint256);

    function totalFundsAtManagePhaseEnd() external view returns (uint256);

    function startTimeOfCyclePhase() external view returns (uint256);

    function startTimeOfLastManagementPhase() external view returns (uint256);

    function devFundingRate() external view returns (uint256);

    function totalCommissionLeft() external view returns (uint256);

    function totalSharesAtLastManagePhaseStart() external view returns (uint256);

    function peakReferralTotalCommissionLeft() external view returns (uint256);

    function peakManagerStakeRequired() external view returns (uint256);

    function peakReferralToken() external view returns (uint256);

    function peakReward() external view returns (address);

    function peakStaking() external view returns (address);

    function isPermissioned() external view returns (bool);

    function initInternalTokens(
        address _repAddr,
        address _sTokenAddr,
        address _peakReferralTokenAddr
    ) external;

    function initRegistration(
        uint256 _newManagerRepToken,
        uint256 _maxNewManagersPerCycle,
        uint256 _reptokenPrice,
        uint256 _peakManagerStakeRequired,
        bool _isPermissioned
    ) external;

    function initTokenListings(
        address[] calldata _kyberTokens,
        address[] calldata _compoundTokens
    ) external;

    function setProxy(address payable proxyAddr) external;

    function developerInitiateUpgrade(address payable _candidate) external returns (bool _success);

    function migrateOwnedContractsToNextVersion() external;

    function transferAssetToNextVersion(address _assetAddress) external;

    function investmentsCount(address _userAddr)
        external
        view
        returns (uint256 _count);

    function nextVersion()
        external
        view
        returns (address payable);

    function transferOwnership(address newOwner) external;

    function compoundOrdersCount(address _userAddr)
        external
        view
        returns (uint256 _count);

    function getPhaseLengths()
        external
        view
        returns (uint256[2] memory _phaseLengths);

    function commissionBalanceOf(address _manager)
        external
        returns (uint256 _commission, uint256 _penalty);

    function commissionOfAt(address _manager, uint256 _cycle)
        external
        returns (uint256 _commission, uint256 _penalty);

    function changeDeveloperFeeAccount(address payable _newAddr) external;

    function changeDeveloperFeeRate(uint256 _newProp) external;

    function listKyberToken(address _token) external;

    function listCompoundToken(address _token) external;

    function nextPhase() external;

    function registerWithUSDC() external;

    function registerWithETH() external payable;

    function registerWithToken(address _token, uint256 _donationInTokens) external;

    function depositEther(address _referrer) external payable;

    function depositEtherAdvanced(
        bool _useKyber,
        bytes calldata _calldata,
        address _referrer
    ) external payable;

    function depositUSDC(uint256 _usdcAmount, address _referrer) external;

    function depositToken(
        address _tokenAddr,
        uint256 _tokenAmount,
        address _referrer
    ) external;

    function depositTokenAdvanced(
        address _tokenAddr,
        uint256 _tokenAmount,
        bool _useKyber,
        bytes calldata _calldata,
        address _referrer
    ) external;

    function withdrawEther(uint256 _amountInUSDC) external;

    function withdrawEtherAdvanced(
        uint256 _amountInUSDC,
        bool _useKyber,
        bytes calldata _calldata
    ) external;

    function withdrawUSDC(uint256 _amountInUSDC) external;

    function withdrawToken(address _tokenAddr, uint256 _amountInUSDC) external;

    function withdrawTokenAdvanced(
        address _tokenAddr,
        uint256 _amountInUSDC,
        bool _useKyber,
        bytes calldata _calldata
    ) external;

    function redeemCommission(bool _inShares) external;

    function redeemCommissionForCycle(bool _inShares, uint256 _cycle) external;

    function sellLeftoverToken(address _tokenAddr, bytes calldata _calldata)
        external;

    function sellLeftoverCompoundOrder(address payable _orderAddress) external;

    function burnDeadman(address _deadman) external;

    function createInvestment(
        address _tokenAddress,
        uint256 _stake,
        uint256 _maxPrice
    ) external;

    function createInvestmentV2(
        address _sender,
        address _tokenAddress,
        uint256 _stake,
        uint256 _maxPrice,
        bytes calldata _calldata,
        bool _useKyber
    ) external;

    function sellInvestmentAsset(
        uint256 _investmentId,
        uint256 _tokenAmount,
        uint256 _minPrice
    ) external;

    function sellInvestmentAssetV2(
        address _sender,
        uint256 _investmentId,
        uint256 _tokenAmount,
        uint256 _minPrice,
        bytes calldata _calldata,
        bool _useKyber
    ) external;

    function createCompoundOrder(
        address _sender,
        bool _orderType,
        address _tokenAddress,
        uint256 _stake,
        uint256 _minPrice,
        uint256 _maxPrice
    ) external;

    function sellCompoundOrder(
        address _sender,
        uint256 _orderId,
        uint256 _minPrice,
        uint256 _maxPrice
    ) external;

    function repayCompoundOrder(
        address _sender,
        uint256 _orderId,
        uint256 _repayAmountInUSDC
    ) external;

    function emergencyExitCompoundTokens(
        address _sender,
        uint256 _orderId,
        address _tokenAddr,
        address _receiver
    ) external;

    function peakReferralCommissionBalanceOf(address _referrer) external returns (uint256 _commission);

    function peakReferralCommissionOfAt(address _referrer, uint256 _cycle) external returns (uint256 _commission);

    function peakReferralRedeemCommission() external;

    function peakReferralRedeemCommissionForCycle(uint256 _cycle) external;

    function peakChangeManagerStakeRequired(uint256 _newValue) external;
}
