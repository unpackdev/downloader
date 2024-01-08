// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IInvestmentsManager.sol";
import "./LazyInitCapableElement.sol";
import "./GeneralUtilities.sol";
import "./KnowledgeBase.sol";
import "./IOrganization.sol";
import "./ITreasuryManager.sol";
import "./ERC20Burnable.sol";

contract InvestmentsManager is IInvestmentsManager, LazyInitCapableElement {
    using ReflectionUtilities for address;
    using Uint256Utilities for uint256;
    using AddressUtilities for address;
    using Getters for IOrganization;
    using TransferUtilities for address;

    uint256 public constant override ONE_HUNDRED = 1e18;

    bytes32 private _organizationComponentKey;

    uint256 public override executorRewardPercentage;

    address public override prestoAddress;

    address public override tokenFromETHToBurn;
    address[] private _tokensFromETH;

    uint256 public override lastSwapToETHBlock;
    uint256 public override swapToETHInterval;

    address[] private _tokensToETH;
    uint256[] private _tokensToETHPercentages;

    constructor(bytes memory lazyInitData) LazyInitCapableElement(lazyInitData) {
    }

    function _lazyInit(bytes memory lazyInitData) internal override virtual returns (bytes memory lazyInitResponse) {
        (_organizationComponentKey, executorRewardPercentage, prestoAddress, lazyInitData, lazyInitResponse) = abi.decode(lazyInitData, (bytes32, uint256, address, bytes, bytes));
        _initFromETH(lazyInitData);
        _initToETH(lazyInitResponse);
        lazyInitResponse = "";
    }

    function _supportsInterface(bytes4 interfaceId) internal override pure returns(bool) {
        return
            interfaceId == type(IInvestmentsManager).interfaceId ||
            interfaceId == this.ONE_HUNDRED.selector ||
            interfaceId == this.refundETHReceiver.selector ||
            interfaceId == this.executorRewardPercentage.selector ||
            interfaceId == this.prestoAddress.selector ||
            interfaceId == this.tokenFromETHToBurn.selector ||
            interfaceId == this.tokensFromETH.selector ||
            interfaceId == this.setTokensFromETH.selector ||
            interfaceId == this.swapFromETH.selector ||
            interfaceId == this.lastSwapToETHBlock.selector ||
            interfaceId == this.swapToETHInterval.selector ||
            interfaceId == this.nextSwapToETHBlock.selector ||
            interfaceId == this.tokensToETH.selector ||
            interfaceId == this.setTokensToETH.selector ||
            interfaceId == this.swapToETH.selector;
    }

    receive() external payable {
    }

    function refundETHReceiver() public override view returns(bytes32 key, address receiverAddress) {
        key = _organizationComponentKey;
        receiverAddress = IOrganization(host).get(key);
        receiverAddress != address(0) ? receiverAddress : address(IOrganization(host).treasuryManager());
    }

    function tokensFromETH() override external view returns(address[] memory addresses) {
        return _tokensFromETH;
    }

    function setTokensFromETH(address[] calldata addresses) external override authorizedOnly returns(address[] memory oldAddresses) {
        oldAddresses = _tokensFromETH;
        for(uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "zero");
        }
        _tokensFromETH = addresses;
    }

    function swapFromETH(PrestoOperation[] calldata tokensFromETHData, PrestoOperation calldata tokenFromETHToBurnData, address executorRewardReceiver) external override returns (uint256[] memory tokenAmounts, uint256 tokenFromETHToBurnAmount, uint256 executorReward) {

        uint256 ethBalance = address(this).balance;

        require(ethBalance > 0, "No ETH");

        address[] memory receivers;

        (ethBalance, executorReward, receivers) = _receiveETH(ethBalance, executorRewardReceiver);

        address tokenToBurn = tokenFromETHToBurn;

        uint256 length = _tokensFromETH.length;

        PrestoOperation[] memory prestoOperations = new PrestoOperation[](length + (tokenToBurn == address(0) ? 0 : 1));

        uint256 splittedBalance = ethBalance / (prestoOperations.length);

        for(uint256 i = 0; i < length; i++) {
            PrestoOperation memory inputOperation = tokensFromETHData[i];
            require(inputOperation.ammPlugin != address(0), 'AMM Plugin');
            require(inputOperation.tokenMins[0] > 0, "SLIPPPPPPPPPPPPPAGE");
            inputOperation.swapPath[inputOperation.swapPath.length - 1] = _tokensFromETH[i];
            require(inputOperation.liquidityPoolAddresses.length == inputOperation.swapPath.length, "LP");
            prestoOperations[i] = PrestoOperation({
                inputTokenAddress : address(0),
                inputTokenAmount : splittedBalance,
                ammPlugin : inputOperation.ammPlugin,
                liquidityPoolAddresses : inputOperation.liquidityPoolAddresses,
                swapPath : inputOperation.swapPath,
                enterInETH : true,
                exitInETH : false,
                tokenMins : inputOperation.tokenMins[0].asSingletonArray(),
                receivers : receivers,
                receiversPercentages : new uint256[](0)
            });
        }
        if(tokenToBurn != address(0)) {
            PrestoOperation memory inputOperation = tokenFromETHToBurnData;
            require(inputOperation.ammPlugin != address(0), 'AMM Plugin');
            require(inputOperation.tokenMins[0] > 0, "SLIPPPPPPPPPPPPPAGE");
            inputOperation.swapPath[inputOperation.swapPath.length - 1] = tokenToBurn;
            require(inputOperation.liquidityPoolAddresses.length == inputOperation.swapPath.length, "LP");
            prestoOperations[prestoOperations.length - 1] = PrestoOperation({
                inputTokenAddress : address(0),
                inputTokenAmount : splittedBalance,
                ammPlugin : inputOperation.ammPlugin,
                liquidityPoolAddresses : inputOperation.liquidityPoolAddresses,
                swapPath : inputOperation.swapPath,
                enterInETH : true,
                exitInETH : false,
                tokenMins : inputOperation.tokenMins[0].asSingletonArray(),
                receivers : address(0).asSingletonArray(),
                receiversPercentages : new uint256[](0)
            });
        }

        tokenAmounts = IPrestoUniV3(prestoAddress).execute{value : ethBalance}(prestoOperations);

        if(tokenToBurn != address(0)) {
            tokenFromETHToBurnAmount = tokenAmounts[tokenAmounts.length - 1];
            uint256[] memory outputs = tokenAmounts;
            tokenAmounts = new uint256[](outputs.length - 1);
            for(uint256 i = 0; i < tokenAmounts.length; i++) {
                tokenAmounts[i] = outputs[i];
            }
        }
    }

    function nextSwapToETHBlock() public view override returns(uint256) {
        return lastSwapToETHBlock == 0 ? 0 : (lastSwapToETHBlock + swapToETHInterval);
    }

    function tokensToETH() external view override returns(address[] memory addresses, uint256[] memory percentages) {
        return (_tokensToETH, _tokensToETHPercentages);
    }

    function setTokensToETH(address[] calldata addresses, uint256[] calldata percentages) external override authorizedOnly returns(address[] memory oldAddresses, uint256[] memory oldPercentages) {
        oldAddresses = _tokensToETH;
        oldPercentages = _tokensToETHPercentages;

        require(addresses.length == percentages.length, "length");

        for(uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "zero");
            require(percentages[i] > 0, "zero");
        }

        _tokensToETH = addresses;
        _tokensToETHPercentages = percentages;
    }

    function swapToETH(PrestoOperation[] calldata tokensToETHData, address executorRewardReceiver) external override returns (uint256[] memory executorRewards, uint256[] memory ethAmounts) {

        require(_tokensToETH.length > 0, "no tokens");

        require(block.number >= nextSwapToETHBlock(), "Too early BRO");
        lastSwapToETHBlock = block.number;

        (uint256[] memory values, address[] memory receivers, uint256[] memory receiversPercentages) = _receiveTokens(executorRewardReceiver);
        PrestoOperation[] memory prestoOperations = new PrestoOperation[](values.length);

        for(uint256 i = 0; i < prestoOperations.length; i++) {
            PrestoOperation memory inputOperation = tokensToETHData[i];
            require(inputOperation.ammPlugin != address(0), 'AMM Plugin');
            require(inputOperation.tokenMins[0] > 0, "SLIPPPPPPPPPPPPPAGE");
            inputOperation.swapPath[inputOperation.swapPath.length - 1] = address(0);
            prestoOperations[i] = PrestoOperation({
                inputTokenAddress : _tokensToETH[i],
                inputTokenAmount : values[i],
                ammPlugin : inputOperation.ammPlugin,
                liquidityPoolAddresses : inputOperation.liquidityPoolAddresses,
                swapPath : inputOperation.swapPath,
                enterInETH : false,
                exitInETH : true,
                tokenMins : inputOperation.tokenMins[0].asSingletonArray(),
                receivers : receivers,
                receiversPercentages : receiversPercentages
            });
        }

        ethAmounts = IPrestoUniV3(prestoAddress).execute(prestoOperations);

        executorRewards = new uint256[](ethAmounts.length);
        uint256 percentage = executorRewardPercentage;
        if(percentage > 0) {
            for(uint256 i = 0; i < executorRewards.length; i++) {
                executorRewards[i] = _calculatePercentage(ethAmounts[i], percentage);
            }
        }
    }

    function _initFromETH(bytes memory fromETHData) private {
        (tokenFromETHToBurn, _tokensFromETH) = abi.decode(fromETHData, (address, address[]));
    }

    function _initToETH(bytes memory toETHData) private {
        uint256 firstSwapToETHBlock;
        uint256 _swapToETHInterval;
        (firstSwapToETHBlock, _swapToETHInterval, _tokensToETH, _tokensToETHPercentages) = abi.decode(toETHData, (uint256, uint256, address[], uint256[]));
        swapToETHInterval = _swapToETHInterval;
        if(firstSwapToETHBlock != 0 && _swapToETHInterval < firstSwapToETHBlock) {
            lastSwapToETHBlock = firstSwapToETHBlock - _swapToETHInterval;
        }
    }

    function _calculatePercentage(uint256 totalSupply, uint256 percentage) private pure returns(uint256) {
        return (totalSupply * ((percentage * 1e18) / ONE_HUNDRED)) / 1e18;
    }

    function _receiveETH(uint256 ethBalanceInput, address executorRewardReceiver) private returns(uint256 ethBalance, uint256 executorReward, address[] memory receivers) {
        ethBalance = ethBalanceInput;
        receivers = address(this).asSingletonArray();
        if(executorRewardPercentage > 0) {
            executorReward = _calculatePercentage(ethBalance, executorRewardPercentage);
            address receiver = executorRewardReceiver != address(0) ? executorRewardReceiver : msg.sender;
            address(0).safeTransfer(receiver, executorReward);
            ethBalance -= executorReward;
        }
    }

    function _receiveTokens(address executorRewardReceiver) private returns(uint256[] memory values, address[] memory receivers, uint256[] memory receiverPercentages) {
        uint256 length = _tokensToETH.length;
        values = new uint256[](length);
        for(uint256 i = 0; i < length; i++) {
            address tokenAddress = _tokensToETH[i];
            values[i] = _calculatePercentage(IERC20(tokenAddress).balanceOf(address(this)), _tokensToETHPercentages[i]);
            tokenAddress.safeApprove(prestoAddress, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        }
        (,address refundETHReceiverAddress) = refundETHReceiver();
        if(executorRewardPercentage > 0) {
            receivers = new address[](2);
            receivers[0] = executorRewardReceiver != address(0) ? executorRewardReceiver : msg.sender;
            receivers[1] = refundETHReceiverAddress;
            receiverPercentages = new uint256[](1);
            receiverPercentages[0] = executorRewardPercentage;
        } else {
            receivers = refundETHReceiverAddress.asSingletonArray();
        }
    }
}