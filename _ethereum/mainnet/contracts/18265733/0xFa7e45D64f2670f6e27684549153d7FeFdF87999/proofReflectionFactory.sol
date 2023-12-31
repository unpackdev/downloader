// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./ProofReflectionFactoryFees.sol";
import "./ITeamFinanceLocker.sol";
import "./ITokenCutter.sol";
import "./IFACTORY.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IProofReflectionTokenCutter.sol";
import "./ProofReflectionTokenCutter.sol";

contract ProofReflectionFactory is Ownable {
    struct ProofToken {
        bool status;
        address pair;
        address owner;
        uint256 unlockTime;
        uint256 lockId;
    }

    struct TokenParam {
        string tokenName;
        string tokenSymbol;
        uint256 initialSupply;
        uint256 percentToLP;
        uint256 initialReflectionFee;
        uint256 initialReflectionFeeOnSell;
        uint256 initialLpFee;
        uint256 initialLpFeeOnSell;
        uint256 initialDevFee;
        uint256 initialDevFeeOnSell;
        uint256 unlockTime;
        address devWallet;
        uint256 whitelistPeriod;
        address[] whitelists;
    }

    struct WhitelistAdd_ {
        address [] whitelists;
    }

    mapping(address => ProofToken) public validatedPairs;

    address public proofAdmin;
    address public routerAddress;
    address public lockerAddress;
    address[] public baseNFTWhitelist;
    address payable public revenueAddress;
    address payable public rewardPoolAddress;

    event TokenCreated(address _address);

    constructor(
        address initialRouterAddress,
        address initialLockerAddress,
        address initialRewardPoolAddress,
        address initialRevenueAddress,
        address[] memory nftWhitelist
    ) {
        routerAddress = initialRouterAddress;
        lockerAddress = initialLockerAddress;
        proofAdmin = msg.sender;
        revenueAddress = payable(initialRevenueAddress);
        rewardPoolAddress = payable(initialRewardPoolAddress);
        baseNFTWhitelist = nftWhitelist;
    }

    function addmoreWhitelist(address tokenAddress, WhitelistAdd_ memory _WhitelistAdd) external {
        _checkTokenStatus(tokenAddress);

        IProofReflectionTokenCutter(tokenAddress).addMoreToWhitelist(IProofReflectionTokenCutter.WhitelistAdd_(_WhitelistAdd.whitelists));
    
    }

    function createToken(TokenParam memory tokenParam_) external payable {
        require(
            tokenParam_.unlockTime >= block.timestamp + 30 days,
            "unlock under 30 days"
        );
        require(msg.value >= 1 ether, "not enough liquidity");

        //create token

        ProofReflectionFactoryFees.allFees
            memory fees = ProofReflectionFactoryFees.allFees(
                tokenParam_.initialReflectionFee,
                tokenParam_.initialReflectionFeeOnSell,
                tokenParam_.initialLpFee,
                tokenParam_.initialLpFeeOnSell,
                tokenParam_.initialDevFee,
                tokenParam_.initialDevFeeOnSell
            );

        ProofReflectionTokenCutter newToken = new ProofReflectionTokenCutter();
        IProofReflectionTokenCutter(address(newToken)).setBasicData(
            IProofReflectionTokenCutter.BaseData(
                tokenParam_.tokenName,
                tokenParam_.tokenSymbol,
                tokenParam_.initialSupply,
                tokenParam_.percentToLP,
                tokenParam_.whitelistPeriod,
                msg.sender,
                tokenParam_.devWallet,
                routerAddress,
                proofAdmin,
                tokenParam_.whitelists,
                baseNFTWhitelist
            ),
            fees
        );
        emit TokenCreated(address(newToken));

        //add liquidity
        newToken.approve(routerAddress, type(uint256).max);
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        router.addLiquidityETH{value: msg.value}(
            address(newToken),
            newToken.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp + 111
        );

        // disable trading
        newToken.swapTradingStatus();

        validatedPairs[address(newToken)] = ProofToken(
            false,
            newToken.pair(),
            msg.sender,
            tokenParam_.unlockTime,
            0
        );
    }

    function finalizeToken(address tokenAddress) public payable {
        _checkTokenStatus(tokenAddress);

        address _pair = validatedPairs[tokenAddress].pair;
        uint256 _unlockTime = validatedPairs[tokenAddress].unlockTime;
        IERC20(_pair).approve(lockerAddress, type(uint256).max);

        uint256 lpBalance = IERC20(_pair).balanceOf(address(this));

        uint256 _lockId = ITeamFinanceLocker(lockerAddress).lockToken{
            value: msg.value
        }(_pair, msg.sender, lpBalance, _unlockTime, false, 0x0000000000000000000000000000000000000000);
        validatedPairs[tokenAddress].lockId = _lockId;

        //enable trading
        ITokenCutter(tokenAddress).swapTradingStatus();
        ITokenCutter(tokenAddress).setLaunchedAt();

        validatedPairs[tokenAddress].status = true;
    }

    function cancelToken(address tokenAddress) public {
        _checkTokenStatus(tokenAddress);

        address _pair = validatedPairs[tokenAddress].pair;
        address _owner = validatedPairs[tokenAddress].owner;

        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        IERC20(_pair).approve(routerAddress, type(uint256).max);
        uint256 _lpBalance = IERC20(_pair).balanceOf(address(this));

        // enable transfer and allow router to exceed tx limit to remove liquidity
        ITokenCutter(tokenAddress).cancelToken();
        router.removeLiquidityETH(
            address(tokenAddress),
            _lpBalance,
            0,
            0,
            _owner,
            block.timestamp
        );

        // disable transfer of token
        ITokenCutter(tokenAddress).swapTradingStatus();

        delete validatedPairs[tokenAddress];
    }

    function proofRevenueAddress() external view returns (address) {
        return revenueAddress;
    }

    function proofRewardPoolAddress() external view returns (address) {
        return rewardPoolAddress;
    }

    function distributeExcessFunds() external onlyOwner {
        (bool sent, ) = revenueAddress.call{value: address(this).balance / 2}("");
        require(sent, "");
        (bool sent1, ) = rewardPoolAddress.call{value: address(this).balance}("");
        require(sent1, "");
    }

    function setLockerAddress(address newlockerAddress) external onlyOwner {
        lockerAddress = newlockerAddress;
    }

    function setRouterAddress(address newRouterAddress) external onlyOwner {
        routerAddress = payable(newRouterAddress);
    }

    function setBaseNFTWhitelist(address[] memory newNFTWhitelist) external onlyOwner {
        baseNFTWhitelist = newNFTWhitelist;
    }

    function setProofAdmin(address newProofAdmin) external onlyOwner {
        proofAdmin = newProofAdmin;
    }

    function setRevenueAddress(address newRevenueAddress) external onlyOwner {
        revenueAddress = payable(newRevenueAddress);
    }

    function setRewardPoolAddress(
        address newRewardPoolAddress
    ) external onlyOwner {
        rewardPoolAddress = payable(newRewardPoolAddress);
    }

    function _checkTokenStatus(address tokenAddress) internal view {
        require(validatedPairs[tokenAddress].owner == msg.sender, "!owner");
        require(validatedPairs[tokenAddress].status == false, "validated");
    }

    receive() external payable {}
}
