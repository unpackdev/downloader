//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./console.sol";
import "./ISlayToEarnItems.sol";
import "./SlayToEarnAccessControl.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./SlayToEarnClaimRewards.sol";
import "./SlayToEarnToken.sol";
import "./IUniswapV2Router02.sol";

contract SlayToEarnTreasury is Ownable, AccessControl {
    using Math for uint256;

    bytes32 public constant MAINTENANCE_ROLE = keccak256("MAINTENANCE_ROLE");

    SlayToEarnClaimRewards private _claimRewards;
    SlayToEarnToken private _slayToEarnToken;
    address private _usdcToken;
    uint256 private _tokenRewardsPercentage;
    uint256 private _tokenDevPercentage;
    uint256 private _tokenBuyBackPercentage;
    address private _devIncomeWallet;
    address private _buyBackWallet;
    IUniswapV2Router02 private _uniswapRouter;

    constructor(
        SlayToEarnClaimRewards claimRewardsContract,
        SlayToEarnToken slayToEarnToken,
        IERC20Extended usdcToken,
        IUniswapV2Router02 uniswapRouter,
        address devIncomeWallet,
        address buyBackWallet) {

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MAINTENANCE_ROLE, msg.sender);

        _setRoleAdmin(MAINTENANCE_ROLE, DEFAULT_ADMIN_ROLE);

        require(keccak256(bytes(slayToEarnToken.symbol())) == keccak256("SLAY2EARN"), "You did not supply a valid SLAY2EARN token.");
        require(keccak256(bytes(usdcToken.symbol())) == keccak256("USDC"), "You did not supply a valid USDC token.");

        uniswapRouter.factory();
        uniswapRouter.WETH();

        _slayToEarnToken = slayToEarnToken;
        _usdcToken = address(usdcToken);
        _uniswapRouter = uniswapRouter;
        _devIncomeWallet = devIncomeWallet;
        _buyBackWallet = buyBackWallet;

        setClaimRewardsContract(claimRewardsContract);

        setTaxPercentages(2, 3, 1);
    }

    function setTaxPercentages(uint256 rewardPercentage, uint256 devPercentage, uint256 blockifyBuyBackPercentage) public onlyOwner {
        _tokenRewardsPercentage = rewardPercentage;
        _tokenDevPercentage = devPercentage;
        _tokenBuyBackPercentage = blockifyBuyBackPercentage;

        require(_tokenBuyBackPercentage <= 20, "The maximum buy-back fee is 20%.");
        require(_tokenRewardsPercentage <= 20, "The maximum reward fee is 20%.");
        require(_tokenDevPercentage <= 20, "The maximum dev fee is 20%.");
        require(_tokenBuyBackPercentage + _tokenRewardsPercentage + _tokenDevPercentage <= 30, "The maximum total combined fee is 30%.");
        require(_tokenBuyBackPercentage + _tokenRewardsPercentage + _tokenDevPercentage > 0, "At least one fee dimension must be positive.");
    }

    function getBuyBackPercentage() public view returns (uint256) {
        return _tokenBuyBackPercentage;
    }

    function getRewardsPercentage() public view returns (uint256) {
        return _tokenRewardsPercentage;
    }

    function getDevPercentage() public view returns (uint256) {
        return _tokenDevPercentage;
    }

    function setClaimRewardsContract(SlayToEarnClaimRewards claimRewards) public onlyOwner {
        require(claimRewards.getSigner() != address(0), "The claim rewards contract has a zero address for a signer.");

        _claimRewards = claimRewards;
    }

    function getClaimRewardsContract() public view returns (address) {
        return address(_claimRewards);
    }

    function setBuyBackWallet(address buyBackWallet) public onlyOwner {
        _buyBackWallet = buyBackWallet;
    }

    function getBuyBackWallet() public view returns (address) {
        return _buyBackWallet;
    }

    function setDevIncomeWallet(address devIncomeWallet) public onlyOwner {
        _devIncomeWallet = devIncomeWallet;
    }

    function getDevIncomeWallet() public view returns (address) {
        return _devIncomeWallet;
    }

    function getSlayToEarnToken() public view returns (address) {
        return address(_slayToEarnToken);
    }

    function getUsdcToken() public view returns (address) {
        return _usdcToken;
    }

    function isWhitelisted() public view returns (bool) {
        return _slayToEarnToken.isWhitelisted(address(this));
    }

    function recoverTokens(IERC20 tokenContract) public onlyOwner {
        require(isWhitelisted(), "Treasury needs to be whitelisted before sending tokens.");

        tokenContract.transfer(msg.sender, tokenContract.balanceOf(address(this)));
    }

    /**
        Investments into the whole project will be taken from the entire treasury, since everyone profits from that.
        This is used for marketing and potentially exchange listings.
    */
    function payThirdParty(uint256 slayToEarnToSendInEther, address thirdPartyWallet) public onlyOwner {
        require(isWhitelisted(), "Treasury needs to be whitelisted before sending tokens.");

        require(slayToEarnToSendInEther <= 1_000_000_000, "You can send at most 1% of the supply per call.");
        require(slayToEarnToSendInEther > 0, "You need to send a positive amount of tokens.");

        _slayToEarnToken.transfer(thirdPartyWallet, slayToEarnToSendInEther * (1 ether));
    }

    /**
        Distribute treasury fraction into three addresses according to tax percentages.
    */
    function distribute(uint256 slayToEarnToDistributeInEther) public onlyRole(MAINTENANCE_ROLE) {
        require(isWhitelisted(), "Treasury needs to be whitelisted before sending tokens.");

        slayToEarnToDistributeInEther = slayToEarnToDistributeInEther.min(_slayToEarnToken.balanceOf(address(this)));

        require(slayToEarnToDistributeInEther >= 1_000_000, "You need to distribute at least 0.001% of the supply per call. The contract may not have enough balance.");
        require(slayToEarnToDistributeInEther <= 1_000_000_000, "You can distribute at most 1% of the supply per call.");

        uint256 totalTaxPercentage = _tokenDevPercentage + _tokenRewardsPercentage + _tokenBuyBackPercentage;
        uint256 devTokens = (slayToEarnToDistributeInEther * _tokenDevPercentage * (1 ether)) / totalTaxPercentage;
        uint256 rewardTokens = (slayToEarnToDistributeInEther * _tokenRewardsPercentage * (1 ether)) / totalTaxPercentage;
        uint256 buyBackTokens = (slayToEarnToDistributeInEther * _tokenBuyBackPercentage * (1 ether)) / totalTaxPercentage;

        require(devTokens + rewardTokens + buyBackTokens <= slayToEarnToDistributeInEther * (1 ether), "Tokens to distribute exceed request.");

        if (devTokens > 0) {
            require(_devIncomeWallet != address(0), "No dev income wallet specified, but a dev tax is set.");
            _sellAndTransferTo(_devIncomeWallet, devTokens);
        }

        if (buyBackTokens > 0) {
            require(_buyBackWallet != address(0), "No buyback wallet specified, but a buyback tax is set.");
            _sellAndTransferTo(_buyBackWallet, buyBackTokens);
        }

        if (rewardTokens > 0) {
            require(address(_claimRewards) != address(0), "No rewards contract specified, but a rewards tax is set.");
            _slayToEarnToken.transfer(address(_claimRewards), rewardTokens);
        }
    }

    function _sellAndTransferTo(address wallet, uint256 tokensToSell) internal {
        if (tokensToSell == 0) {
            return;
        }

        // sell buffered tokens into USDC and send them to dev wallet.
        address[] memory tradingPath = new address[](2);
        tradingPath[0] = address(_slayToEarnToken);
        tradingPath[1] = address(_usdcToken);

        _slayToEarnToken.increaseAllowance(
            address(_uniswapRouter),
            tokensToSell
        );

        _uniswapRouter.swapExactTokensForTokens(
            tokensToSell,
            0,
            tradingPath,
            wallet,
            block.timestamp
        );
    }
}
