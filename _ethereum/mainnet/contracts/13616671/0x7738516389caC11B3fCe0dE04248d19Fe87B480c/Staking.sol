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

interface IOldStaking {
    function config(uint fnftId) external view returns (uint allocPoints, uint timePeriod);
    function manualMapConfig(uint[] memory fnftIds, uint[] memory timePeriod) external;
}

contract Staking is Ownable, IOutputReceiver, ERC165, IAddressLock {
    using SafeERC20 for IERC20;

    address private revestAddress;
    address public lpAddress;
    address public rewardsHandlerAddress;
    address public addressRegistry;

    //TODO: ADD SETTERS FOR THESE
    address public oldStakingContract;
    uint public previousStakingIDCutoff;

    uint private constant ONE_DAY = 86400;

    uint private constant WINDOW_ONE = ONE_DAY;
    uint private constant WINDOW_THREE = ONE_DAY*5;
    uint private constant WINDOW_SIX = ONE_DAY*9;
    uint private constant WINDOW_TWELVE = ONE_DAY*14;
    uint private constant MAX_INT = 2**256 - 1;

    address internal immutable WETH;

    uint[4] internal interestRates = [4, 13, 27, 56];
    string public customMetadataUrl = "https://revest.mypinata.cloud/ipfs/QmeSaVihizntuDQL5BgsujK2nK6bkkwXXzHATGGjM2uyRr";
    string public addressMetadataUrl = "https://revest.mypinata.cloud/ipfs/QmY3KUBToJBthPLvN1Knd7Y51Zxx7FenFhXYV8tPEMVAP3";

    event StakedRevest(uint indexed timePeriod, bool indexed isBasic, uint indexed amount, uint fnftId);



    // fnftId -> timePeriods
    mapping(uint => uint) public timePeriods;

    constructor(
        address revestAddress_,
        address lpAddress_,
        address rewardsHandlerAddress_,
        address addressRegistry_,
        address wrappedEth_
    ) {
        revestAddress = revestAddress_;
        lpAddress = lpAddress_;
        addressRegistry = addressRegistry_;
        rewardsHandlerAddress = rewardsHandlerAddress_;
        WETH = wrappedEth_;
        previousStakingIDCutoff = IFNFTHandler(IAddressRegistry(addressRegistry).getRevestFNFT()).getNextId() - 1;

        IERC20(lpAddress).approve(address(getRevest()), MAX_INT);
        IERC20(revestAddress).approve(address(getRevest()), MAX_INT);
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
        IERC20(revestAddress).safeTransferFrom(msg.sender, address(this), amount);

        IRevest.FNFTConfig memory fnftConfig;
        fnftConfig.asset = revestAddress;
        fnftConfig.depositAmount = amount;
        fnftConfig.isMulti = true;

        fnftConfig.pipeToContract = address(this);

        address[] memory recipients = new address[](1);
        recipients[0] = _msgSender();

        uint[] memory quantities = new uint[](1);
        // FNFT quantity will always be singular
        quantities[0] = 1;

        uint fnftId = getRevest().mintAddressLock(address(this), '', recipients, quantities, fnftConfig);

        uint interestRate = getInterestRate(monthsMaturity);
        uint allocPoint = amount * interestRate;

        timePeriods[fnftId] = monthsMaturity;

        IRewardsHandler(rewardsHandlerAddress).updateBasicShares(fnftId, allocPoint);

        emit StakedRevest(monthsMaturity, true, amount, fnftId);
        return fnftId;
    }

    function stakeLPTokens(uint amount, uint monthsMaturity) public returns (uint) {
        require(monthsMaturity == 1 || monthsMaturity == 3 || monthsMaturity == 6 || monthsMaturity == 12, 'E055');
        IERC20(lpAddress).safeTransferFrom(msg.sender, address(this), amount);

        IRevest.FNFTConfig memory fnftConfig;
        fnftConfig.asset = lpAddress;
        fnftConfig.depositAmount = amount;
        fnftConfig.isMulti = true;

        fnftConfig.pipeToContract = address(this);

        address[] memory recipients = new address[](1);
        recipients[0] = _msgSender();

        uint[] memory quantities = new uint[](1);
        quantities[0] = 1;

        uint fnftId = getRevest().mintAddressLock(address(this), '', recipients, quantities, fnftConfig);

        uint interestRate = getInterestRate(monthsMaturity);
        uint allocPoint = amount * interestRate;
        timePeriods[fnftId] = monthsMaturity;

        IRewardsHandler(rewardsHandlerAddress).updateLPShares(fnftId, allocPoint);
        emit StakedRevest(monthsMaturity, false, amount, fnftId);
        return fnftId;
    }

    function depositAdditionalToStake(uint fnftId, uint amount) public {
        //Prevent unauthorized access
        require(IFNFTHandler(getRegistry().getRevestFNFT()).getBalance(_msgSender(), fnftId) == 1, 'E061');
        require(fnftId > previousStakingIDCutoff, 'E080');
        uint time = timePeriods[fnftId];
        require(time > 0, 'E078');
        address asset = ITokenVault(getRegistry().getTokenVault()).getFNFT(fnftId).asset;
        require(asset == revestAddress || asset == lpAddress, 'E079');

        //Pull tokens from caller
        IERC20(asset).safeTransferFrom(_msgSender(), address(this), amount);
        //Claim rewards owed
        IRewardsHandler(rewardsHandlerAddress).claimRewards(fnftId, _msgSender());

        //Retreive current allocation points – WETH and RVST implicitly have identical alloc points
        uint oldAllocPoints = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, revestAddress, asset == revestAddress);
        uint allocPoints = amount * getInterestRate(time) + oldAllocPoints;
        if(asset == revestAddress) {
            IRewardsHandler(rewardsHandlerAddress).updateBasicShares(fnftId, allocPoints);
        } else if (asset == lpAddress) {
            IRewardsHandler(rewardsHandlerAddress).updateLPShares(fnftId, allocPoints);
        }
        //Deposit additional tokens
        getRevest().depositAdditionalToFNFT(fnftId, amount, 1);
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

    function receiveRevestOutput(
        uint fnftId,
        address asset,
        address payable owner,
        uint quantity
    ) external override {
        address vault = getRegistry().getTokenVault();
        require(_msgSender() == vault, "E016");

        uint totalQuantity = quantity * ITokenVault(vault).getFNFT(fnftId).depositAmount;
        IRewardsHandler(rewardsHandlerAddress).claimRewards(fnftId, owner);
        if (asset == revestAddress) {
            IRewardsHandler(rewardsHandlerAddress).updateBasicShares(fnftId, 0);
        } else if (asset == lpAddress) {
            IRewardsHandler(rewardsHandlerAddress).updateLPShares(fnftId, 0);
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

    function updateLock(uint fnftId, uint, bytes memory) external override {
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

    function getCustomMetadata(uint) external view override returns (string memory) {
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
        uint timePeriod = timePeriods[fnftId];
        if(fnftId <= previousStakingIDCutoff) {
            (,timePeriod) = IOldStaking(oldStakingContract).config(fnftId);
        }
        return abi.encode(revestRewards, wethRewards, timePeriod, isRevestToken ? revestAddress : lpAddress);
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

    function getDisplayValues(uint fnftId, uint) external view override returns (bytes memory) {
        uint allocPoints;
        {
            uint revestTokenAlloc = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, revestAddress, true);
            uint lpTokenAlloc = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, revestAddress, false);
            allocPoints = revestTokenAlloc > 0 ? revestTokenAlloc : lpTokenAlloc;
        }
        uint timePeriod = timePeriods[fnftId];
        if(fnftId <= previousStakingIDCutoff) {
            (allocPoints, timePeriod) = IOldStaking(oldStakingContract).config(fnftId);
        }
        return abi.encode(allocPoints, timePeriod);
    }

    function createLock(uint, uint, bytes memory) external pure override {
        return;
    }

    function isUnlockable(uint fnftId, uint) external view override returns (bool) {
        uint timePeriod = timePeriods[fnftId];
        if(fnftId <= previousStakingIDCutoff) {
            (, timePeriod) = IOldStaking(oldStakingContract).config(fnftId);
        }
        uint window = getWindow(timePeriod);
        uint depositTime = ILockManager(getRegistry().getLockManager()).fnftIdToLock(fnftId).creationTime;
        bool mature = block.timestamp - depositTime > window;
        bool window_open = (block.timestamp - depositTime) % (timePeriod * 30 * ONE_DAY) < window;
        return mature && window_open;
    }

    function getWindow(uint timePeriod) private pure returns (uint window) {
        if(timePeriod == 1) {
            window = WINDOW_ONE;
        }
        if(timePeriod == 3) {
            window = WINDOW_THREE;
        }
        if(timePeriod == 6) {
            window = WINDOW_SIX;
        }
        if(timePeriod == 12) {
            window = WINDOW_TWELVE;
        }
    }

    // Admin functions

    function manualMapConfig(
        uint[] memory fnftIds,
        uint[] memory timePeriod
    ) external onlyOwner {
        for(uint i = 0; i < fnftIds.length; i++) {
            timePeriods[fnftIds[i]] = timePeriod[i];
        }
    }

    function updateInterestRates(uint[4] memory newRates) external onlyOwner {
        interestRates = newRates;
    }

    function setCutoff(uint cutoff) external onlyOwner {
        previousStakingIDCutoff = cutoff;
    }

    function setOldStaking(address stake) external onlyOwner {
        oldStakingContract = stake;
    }



}
