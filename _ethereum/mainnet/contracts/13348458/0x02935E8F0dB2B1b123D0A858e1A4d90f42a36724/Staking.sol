// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IOutputReceiver.sol";
import "./IRevest.sol";
import "./IAddressRegistry.sol";
import "./IRewardsHandler.sol";
import "./IFNFTHandler.sol";
import "./IAddressLock.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC165.sol";

contract Staking is Ownable, IOutputReceiver, ERC165, IAddressLock {
    using SafeERC20 for IERC20;

    address private revestAddress;
    address public lpAddress;
    address public rewardsHandlerAddress;
    address public addressRegistry;

    uint private constant ONE_DAY = 86400;

    uint private constant WINDOW_ONE = ONE_DAY;
    uint private constant WINDOW_THREE = ONE_DAY*5;
    uint private constant WINDOW_SIX = ONE_DAY*9;
    uint private constant WINDOW_TWELVE = ONE_DAY*14;

    address internal immutable WETH;

    uint[4] internal interestRates = [4, 13, 27, 56];
    string public customMetadataUrl = "https://revest.mypinata.cloud/ipfs/QmeSaVihizntuDQL5BgsujK2nK6bkkwXXzHATGGjM2uyRr";
    string public addressMetadataUrl = "https://revest.mypinata.cloud/ipfs/QmY3KUBToJBthPLvN1Knd7Y51Zxx7FenFhXYV8tPEMVAP3";

    event StakedRevest(uint indexed timePeriod, bool indexed isBasic, uint indexed amount, uint fnftId);

    struct StakingConfig {
        uint allocPoints;
        uint timePeriod;
    }

    // fnftId -> allocPoints
    mapping(uint => StakingConfig) public config;

    constructor(
        address revestAddress_,
        address rewardsHandlerAddress_,
        address addressRegistry_,
        address wrappedEth_
    ) {
        revestAddress = revestAddress_;
        addressRegistry = addressRegistry_;
        rewardsHandlerAddress = rewardsHandlerAddress_;
        WETH = wrappedEth_;
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC165, IERC165) returns (bool) {
        return (
            interfaceId == type(IOutputReceiver).interfaceId
            || interfaceId == type(IAddressLock).interfaceId
            || super.supportsInterface(interfaceId)
        );
    }

    function stakeBasicTokens(uint amount, uint monthsMaturity) public returns (uint) {
        require(monthsMaturity == 1 || monthsMaturity == 3 || monthsMaturity == 6 || monthsMaturity == 12, 'E055');
        IERC20(revestAddress).safeTransferFrom(msg.sender, address(this), amount * 1);
        IERC20(revestAddress).approve(address(getRevest()), amount * 1);

        IRevest.FNFTConfig memory fnftConfig;
        fnftConfig.asset = revestAddress;
        fnftConfig.depositAmount = amount;

        fnftConfig.pipeToContract = address(this);

        address[] memory recipients = new address[](1);
        recipients[0] = _msgSender();

        uint[] memory quantities = new uint[](1);
        // FNFT quantity will always be singular
        quantities[0] = 1;

        uint fnftId = getRevest().mintAddressLock(address(this), '', recipients, quantities, fnftConfig);

        uint interestRate = getInterestRate(monthsMaturity);
        uint allocPoint = amount * interestRate;
        uint currentShares = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, revestAddress, true);
        uint newAllocPoint = currentShares + allocPoint;

        StakingConfig memory stakeConfig = StakingConfig(allocPoint, monthsMaturity);
        config[fnftId] = stakeConfig;

        IRewardsHandler(rewardsHandlerAddress).updateBasicShares(fnftId, newAllocPoint);
        emit StakedRevest(monthsMaturity, true, amount, fnftId);
        return fnftId;
    }

    function stakeLPTokens(uint amount, uint monthsMaturity) public returns (uint) {
        require(lpAddress != address(0x0), "E071");
        require(monthsMaturity == 1 || monthsMaturity == 3 || monthsMaturity == 6 || monthsMaturity == 12, 'E055');
        IERC20(lpAddress).safeTransferFrom(msg.sender, address(this), amount * 1);
        IERC20(lpAddress).approve(address(getRevest()), amount * 1);

        IRevest.FNFTConfig memory fnftConfig;
        fnftConfig.asset = lpAddress;
        fnftConfig.depositAmount = amount;

        fnftConfig.pipeToContract = address(this);

        address[] memory recipients = new address[](1);
        recipients[0] = _msgSender();

        uint[] memory quantities = new uint[](1);
        quantities[0] = 1;

        uint fnftId = getRevest().mintAddressLock(address(this), '', recipients, quantities, fnftConfig);

        uint interestRate = getInterestRate(monthsMaturity);
        uint allocPoint = amount * interestRate;
        uint currentShares = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, revestAddress, true);
        uint newAllocPoint = currentShares + allocPoint;


        StakingConfig memory stakeConfig = StakingConfig(allocPoint, monthsMaturity);
        config[fnftId] = stakeConfig;

        IRewardsHandler(rewardsHandlerAddress).updateLPShares(fnftId, newAllocPoint);
        emit StakedRevest(monthsMaturity, false, amount, fnftId);
        return fnftId;
    }

    function getInterestRate(uint months) public view returns (uint) {
        if (months <= 1) {
            return interestRates[0];
        } else if (months <= 3) {
            return interestRates[1];
        } else if (months <= 6) {
            return interestRates[2];
        } else {
            return interestRates[3];
        }
    }

    function updateInterestRates(uint[4] memory newRates) external onlyOwner {
        interestRates = newRates;
    }

    function receiveRevestOutput(
        uint fnftId,
        address asset,
        address payable owner,
        uint quantity
    ) external override {
        require(_msgSender() == getRegistry().getTokenVault(), "E016");
        uint totalQuantity = quantity * ITokenVault(getRegistry().getTokenVault()).getFNFT(fnftId).depositAmount;
        if (asset == revestAddress) {
            unstakeBasicTokens(fnftId, owner);
        } else if (asset == lpAddress) {
            unstakeLPTokens(fnftId, owner);
        } else {
            require(false, "E072");
        }
        IERC20(asset).safeTransfer(owner, totalQuantity);
    }

    function claimRewards(uint fnftId) external {
        // Check to make sure user owns the fnftId
        require(IFNFTHandler(getRegistry().getRevestFNFT()).getBalance(_msgSender(), fnftId) == 1, 'E061');
        // Receive rewards
        IRewardsHandler(rewardsHandlerAddress).claimRewards(fnftId, _msgSender());
    }

    function unstakeBasicTokens(uint fnftId, address user) internal {
        // Receive rewards
        IRewardsHandler(rewardsHandlerAddress).claimRewards(fnftId, user);

        // Remove allocation points
        uint allocPoint = config[fnftId].allocPoints;
        uint currentShares = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, revestAddress, true);
        uint newAllocPoint = currentShares - allocPoint;
        IRewardsHandler(rewardsHandlerAddress).updateBasicShares(fnftId, newAllocPoint);
    }

    function unstakeLPTokens(uint fnftId, address user) internal {
        IRewardsHandler(rewardsHandlerAddress).claimRewards(fnftId, user);

        // Remove allocation points
        uint allocPoint = config[fnftId].allocPoints;
        uint currentShares = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, lpAddress, true);
        uint newAllocPoint = currentShares - allocPoint;
        IRewardsHandler(rewardsHandlerAddress).updateLPShares(fnftId, newAllocPoint);
    }

    function updateLock(uint fnftId, uint lockId, bytes memory arguments) external override {
        require(IFNFTHandler(getRegistry().getRevestFNFT()).getBalance(_msgSender(), fnftId) == 1, 'E061');
        // Receive rewards
        IRewardsHandler(rewardsHandlerAddress).claimRewards(fnftId, _msgSender());
    }

    function needsUpdate() external pure override returns (bool) {
        return true;
    }

    function setCustomMetadata(string memory _customMetadataUrl) external onlyOwner {
        customMetadataUrl = _customMetadataUrl;
    }

    function getCustomMetadata(uint fnftId) external view override returns (string memory) {
        return customMetadataUrl;
    }

    function getOutputDisplayValues(uint fnftId) external view override returns (bytes memory) {
        bool isRevestToken;
        {
            // Will be zero if this is an LP stake
            uint revestTokenAlloc = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, revestAddress, true);
            uint wethTokenAlloc = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, WETH, true);
            isRevestToken = revestTokenAlloc > 0 || wethTokenAlloc > 0;
        }
        uint revestRewards = IRewardsHandler(rewardsHandlerAddress).getRewards(fnftId, revestAddress);
        uint wethRewards = IRewardsHandler(rewardsHandlerAddress).getRewards(fnftId, WETH);
        return abi.encode(revestRewards, wethRewards, config[fnftId].timePeriod, isRevestToken ? revestAddress : lpAddress);
    }

    function setLPAddress(address lpAddress_) external onlyOwner {
        lpAddress = lpAddress_;
    }

    function setAddressRegistry(address addressRegistry_) external override onlyOwner {
        addressRegistry = addressRegistry_;
    }

    function getAddressRegistry() external view override returns (address) {
        return addressRegistry;
    }

    function getRevest() private view returns (IRevest) {
        return IRevest(getRegistry().getRevest());
    }

    function getRegistry() public view returns (IAddressRegistry) {
        return IAddressRegistry(addressRegistry);
    }

    function getValue(uint fnftId) external view override returns (uint) {
        uint revestStake = IRewardsHandler(rewardsHandlerAddress).getRewards(fnftId, revestAddress);
        return revestStake > 0 ? revestStake : IRewardsHandler(rewardsHandlerAddress).getRewards(fnftId, WETH);
    }

    function getAsset(uint fnftId) external view override returns (address) {
        uint revestStake = IRewardsHandler(rewardsHandlerAddress).getRewards(fnftId, revestAddress);
        return revestStake > 0 ? revestAddress : WETH;
    }

    function setMetadata(string memory _addressMetadataUrl) external onlyOwner {
        addressMetadataUrl = _addressMetadataUrl;
    }

    function setRewardsHandler(address _handler) external onlyOwner {
        rewardsHandlerAddress = _handler;
    }

    function getMetadata() external view override returns (string memory) {
        return addressMetadataUrl;
    }

    function getDisplayValues(uint fnftId, uint lockId) external view override returns (bytes memory) {
        StakingConfig memory lockDetails = config[fnftId];
        return abi.encode(lockDetails.allocPoints, lockDetails.timePeriod);
    }

    function createLock(uint fnftId, uint lockID, bytes memory arguments) external pure override {
        return;
    }

    function isUnlockable(uint fnftId, uint lockId) external view override returns (bool) {
        uint window = getWindow(config[fnftId].timePeriod);
        uint depositTime = ILockManager(getRegistry().getLockManager()).fnftIdToLock(fnftId).creationTime;
        bool mature = block.timestamp - depositTime > window;
        bool window_open = (block.timestamp - depositTime) % (config[fnftId].timePeriod * 30 * ONE_DAY) < window;
        return mature && window_open;
    }

    function getWindow(uint timePeriod) private pure returns (uint) {
        if(timePeriod == 1) {
            return WINDOW_ONE;
        }
        if(timePeriod == 3) {
            return WINDOW_THREE;
        }
        if(timePeriod == 6) {
            return WINDOW_SIX;
        }
        if(timePeriod == 12) {
            return WINDOW_TWELVE;
        }
        // If none of these are true, bad call
        require(false, "Invalid time window");
    }

    // Admin functions

    function manualMapConfig(
        uint[] memory fnftIds,
        uint[] memory allocPoints,
        uint[] memory timePeriod
    ) external onlyOwner {
        for(uint i = 0; i < fnftIds.length; i++) {
            config[fnftIds[i]].allocPoints = allocPoints[i];
            config[fnftIds[i]].timePeriod = timePeriod[i];
        }
    }

}
