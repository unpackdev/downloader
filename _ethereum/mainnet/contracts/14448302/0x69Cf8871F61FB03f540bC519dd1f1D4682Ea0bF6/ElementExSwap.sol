// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SpecialTransferHelper.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

contract ElementExSwap is SpecialTransferHelper, Ownable, ReentrancyGuard {

    struct SimpleTrades {
        uint256 value;
        bytes tradeData;
    }

    struct ERC20Details {
        address[] tokenAddrs;
        uint256[] amounts;
    }

    struct ERC1155Details {
        address tokenAddr;
        uint256[] ids;
        uint256[] amounts;
    }

    struct ConverstionDetails {
        bytes conversionData;
    }

    struct TradeDetails {
        uint256 marketId;
        uint256 value;
        bytes tradeData;
    }

    struct Market {
        address proxy;
        bool isLib;
        bool isActive;
        bool partialFill; // support partial Fill
    }

    event TradeNotFilled(uint256 tradeInfo); // marketId << 248 | index << 240 | value
    event TradeNotFilledSingleMarket(address market, uint256 tradeInfo); // tradeInfo = index << 240 | value

    address public guardian;
    address public converter;
    address public punkProxy;
    bool public openForTrades;

    // opensea-v2 index 0, element index 1, .....
    Market[] public markets;

    modifier isOpenForTrades() {
        require(openForTrades, "trades not allowed");
        _;
    }

    constructor(address[] memory _proxies, bool[] memory _isLibs, bool[] memory _partialFill) {
        openForTrades = false;
        for (uint256 i = 0; i < _proxies.length; i++) {
            markets.push(Market(_proxies[i], _isLibs[i], true, _partialFill[i]));
        }
    }

    function setOpenForTrades(bool _openForTrades) external onlyOwner {
        openForTrades = _openForTrades;
    }

    function setUp() external onlyOwner {
        // Create CryptoPunk Proxy
        IWrappedPunk(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6).registerProxy();
        punkProxy = IWrappedPunk(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6).proxyInfo(address(this));

        // approve wrapped mooncats rescue to Acclimated​MoonCats contract
        IERC721(0x7C40c393DC0f283F318791d746d894DdD3693572).setApprovalForAll(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69, true);
    }

    // @audit This function is used to approve specific tokens to specific market contracts with high volume.
    // This is done in very rare cases for the gas optimization purposes.
    function setOneTimeApproval(IERC20 token, address operator, uint256 amount) external onlyOwner {
        token.approve(operator, amount);
    }

    function updateGuardian(address _guardian) external onlyOwner {
        guardian = _guardian;
    }

    // @audit we will setup a system that will monitor the contract for any leftover
    // assets. In case any asset is leftover, the system should be able to trigger this
    // function to close all the trades until the leftover assets are rescued.
    function closeAllTrades() external {
        require(_msgSender() == guardian);
        openForTrades = false;
    }

    function setConverter(address _converter) external onlyOwner {
        converter = _converter;
    }

    function addMarket(address _proxy, bool _isLib, bool _partialFill) external onlyOwner {
        markets.push(Market(_proxy, _isLib, true, _partialFill));
    }

    function setMarketStatus(uint256 _marketId, bool _newStatus) external onlyOwner {
        Market storage market = markets[_marketId];
        market.isActive = _newStatus;
    }

    function setMarketProxy(uint256 _marketId, address _newProxy, bool _isLib, bool _partialFill) external onlyOwner {
        Market storage market = markets[_marketId];
        market.proxy = _newProxy;
        market.isLib = _isLib;
        market.partialFill = _partialFill;
    }

    function _transferEth(address _to, uint256 _amount) internal {
        bool callStatus;
        assembly {
        // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), _to, _amount, 0, 0, 0, 0)
        }
        require(callStatus, "_transferEth: Eth transfer failed");
    }

    function _checkCallResult(bool _success) internal pure {
        if (!_success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function _transferFromHelper(
        ERC20Details calldata erc20Details,
        SpecialTransferHelper.ERC721Details[] calldata erc721Details,
        ERC1155Details[] calldata erc1155Details
    ) internal {
        // transfer ERC20 tokens from the sender to this contract
        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            erc20Details.tokenAddrs[i].call(abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), erc20Details.amounts[i]));
        }

        // transfer ERC721 tokens from the sender to this contract
        for (uint256 i = 0; i < erc721Details.length; i++) {
            // accept CryptoPunks
            if (erc721Details[i].tokenAddr == 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB) {
                _acceptCryptoPunk(erc721Details[i]);
            }
            // accept Mooncat
            else if (erc721Details[i].tokenAddr == 0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6) {
                _acceptMoonCat(erc721Details[i]);
            }
            // default
            else {
                for (uint256 j = 0; j < erc721Details[i].ids.length; j++) {
                    IERC721(erc721Details[i].tokenAddr).transferFrom(
                        _msgSender(),
                        address(this),
                        erc721Details[i].ids[j]
                    );
                }
            }
        }

        // transfer ERC1155 tokens from the sender to this contract
        for (uint256 i = 0; i < erc1155Details.length; i++) {
            IERC1155(erc1155Details[i].tokenAddr).safeBatchTransferFrom(
                _msgSender(),
                address(this),
                erc1155Details[i].ids,
                erc1155Details[i].amounts,
                ""
            );
        }
    }

    function _conversionHelper(
        ConverstionDetails[] calldata _converstionDetails
    ) internal {
        for (uint256 i = 0; i < _converstionDetails.length; i++) {
            // convert to desired asset
            (bool success,) = converter.delegatecall(_converstionDetails[i].conversionData);
            // check if the call passed successfully
            _checkCallResult(success);
        }
    }

    function _trade(
        TradeDetails[] calldata _tradeDetails
    ) internal {
        for (uint256 i = 0; i < _tradeDetails.length; i++) {

            // get market details
            Market memory market = markets[_tradeDetails[i].marketId];

            // market should be active
            require(market.isActive, "_trade: InActive Market");

            // execute trade
            (bool success,) = market.isLib
            ? market.proxy.delegatecall(_tradeDetails[i].tradeData)
            : market.proxy.call{value : _tradeDetails[i].value}(_tradeDetails[i].tradeData);

            // check if the call passed successfully
            if (!success) {
                if (!market.partialFill) {
                    _checkCallResult(success);
                }
                emit TradeNotFilled(_tradeDetails[i].marketId << 248 | i << 240 | _tradeDetails[i].value);
            }
        }
    }

    function _returnDust(address[] memory _tokens) internal {
        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                gas(),
                caller(),
                selfbalance(),
                0,
                0,
                0,
                0
                )
            }
        }
        // return remaining tokens (if any)
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (IERC20(_tokens[i]).balanceOf(address(this)) > 0) {
                _tokens[i].call(abi.encodeWithSelector(0xa9059cbb, msg.sender, IERC20(_tokens[i]).balanceOf(address(this))));
            }
        }
    }

    function buyOneWithETH(
        address marketProxy,
        SimpleTrades calldata tradeDetail
    ) payable external nonReentrant {
        // execute trade
        (bool success,) = address(marketProxy).call{value : tradeDetail.value}(tradeDetail.tradeData);
        _checkCallResult(success);
    }

    function batchBuyFromSingleMarketWithETH(
        address marketProxy,
        SimpleTrades[] calldata tradeDetails
    ) payable external nonReentrant {

        for (uint256 i = 0; i < tradeDetails.length; i++) {

            // execute trade
            (bool success,) = marketProxy.call{value : tradeDetails[i].value}(tradeDetails[i].tradeData);

            // check if the call passed successfully
            if (!success) {
                emit TradeNotFilledSingleMarket(marketProxy, i << 240 | tradeDetails[i].value);
            }
        }

        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                gas(),
                caller(),
                selfbalance(),
                0,
                0,
                0,
                0
                )
            }
        }
    }

    function batchBuyWithETH(
        TradeDetails[] calldata tradeDetails
    ) payable external nonReentrant {
        // execute trades
        _trade(tradeDetails);

        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                gas(),
                caller(),
                selfbalance(),
                0,
                0,
                0,
                0
                )
            }
        }
    }


    function batchBuyWithETHSimulate(
        TradeDetails[] calldata tradeDetails
    ) payable external {
        uint256 result = _simulateTrade(tradeDetails);

        bytes memory errorData = abi.encodePacked(result);
        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let callStatus := call(
                gas(),
                caller(),
                selfbalance(),
                0,
                0,
                0,
                0
                )
            }

            revert(add(errorData, 0x20), mload(errorData))
        }
    }

    function buyOneWithERC20s(
        address marketProxy,
        ERC20Details calldata erc20Details,
        SimpleTrades calldata tradeDetails,
        ConverstionDetails[] calldata converstionDetails,
        address[] calldata dustTokens
    ) payable external nonReentrant {
        // transfer ERC20 tokens from the sender to this contract
        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            erc20Details.tokenAddrs[i].call(abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), erc20Details.amounts[i]));
        }

        // Convert any assets if needed
        _conversionHelper(converstionDetails);

        // execute trade
        (bool success,) = marketProxy.call{value : tradeDetails.value}(tradeDetails.tradeData);

        // check if the call passed successfully
        _checkCallResult(success);

        // return dust tokens (if any)
        _returnDust(dustTokens);
    }


    function batchBuyWithERC20s(
        ERC20Details calldata erc20Details,
        TradeDetails[] calldata tradeDetails,
        ConverstionDetails[] calldata converstionDetails,
        address[] calldata dustTokens
    ) payable external nonReentrant {
        // transfer ERC20 tokens from the sender to this contract
        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            erc20Details.tokenAddrs[i].call(abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), erc20Details.amounts[i]));
        }

        // Convert any assets if needed
        _conversionHelper(converstionDetails);

        // execute trades
        _trade(tradeDetails);

        // return dust tokens (if any)
        _returnDust(dustTokens);
    }


    function batchBuyWithERC20sSimulate(
        ERC20Details calldata erc20Details,
        TradeDetails[] calldata tradeDetails,
        ConverstionDetails[] calldata converstionDetails,
        address[] calldata dustTokens
    ) payable external {
        // transfer ERC20 tokens from the sender to this contract
        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            erc20Details.tokenAddrs[i].call(abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), erc20Details.amounts[i]));
        }

        // Convert any assets if needed
        _conversionHelper(converstionDetails);

        uint256 result = _simulateTrade(tradeDetails);

        // return dust tokens (if any)
        _returnDust(dustTokens);

        bytes memory errorData = abi.encodePacked(result);
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }


    // swaps any combination of ERC-20/721/1155
    // User needs to approve assets before invoking swap
    // WARNING: DO NOT SEND TOKENS TO THIS FUNCTION DIRECTLY!!!
    function multiAssetSwapEx(
        ERC20Details calldata erc20Details,
        SpecialTransferHelper.ERC721Details[] calldata erc721Details,
        ERC1155Details[] calldata erc1155Details,
        ConverstionDetails[] calldata converstionDetails,
        TradeDetails[] calldata tradeDetails,
        address[] calldata dustTokens
        //uint256[2] calldata feeDetails    // [affiliateIndex, ETH fee in Wei]
    ) payable external isOpenForTrades nonReentrant {
        // collect fees
        // _collectFee(feeDetails);

        // transfer all tokens
        _transferFromHelper(
            erc20Details,
            erc721Details,
            erc1155Details
        );

        // Convert any assets if needed
        _conversionHelper(converstionDetails);

        // execute trades
        _trade(tradeDetails);

        // return dust tokens (if any)
        _returnDust(dustTokens);
    }


    function _simulateTrade(
        TradeDetails[] calldata _tradeDetails
    ) internal returns (uint256) {
        uint256 result;
        for (uint256 i = 0; i < _tradeDetails.length; i++) {
            // get market details
            Market memory market = markets[_tradeDetails[i].marketId];

            // market should be active
            require(market.isActive, "Simulate: InActive Market");

            // execute trade
            (bool success,) = market.isLib
            ? market.proxy.delegatecall(_tradeDetails[i].tradeData)
            : market.proxy.call{value : _tradeDetails[i].value}(_tradeDetails[i].tradeData);

            if (success) {
                result |= 1 << i;
            }
        }
        return result;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    // Used by ERC721BasicToken.sol
    function onERC721Received(
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function supportsInterface(bytes4 interfaceId)
    external
    virtual
    view
    returns (bool)
    {
        return interfaceId == this.supportsInterface.selector;
    }

    receive() external payable {}

    // Emergency function: In case any ETH get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueETH(address recipient) onlyOwner external {
        _transferEth(recipient, address(this).balance);
    }

    // Emergency function: In case any ERC20 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC20(address asset, address recipient) onlyOwner external {
        asset.call(abi.encodeWithSelector(0xa9059cbb, recipient, IERC20(asset).balanceOf(address(this))));
    }

    // Emergency function: In case any ERC721 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC721(address asset, uint256[] calldata ids, address recipient) onlyOwner external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC721(asset).transferFrom(address(this), recipient, ids[i]);
        }
    }

    // Emergency function: In case any ERC1155 tokens get stuck in the contract unintentionally
    // Only owner can retrieve the asset balance to a recipient address
    function rescueERC1155(address asset, uint256[] calldata ids, uint256[] calldata amounts, address recipient) onlyOwner external {
        for (uint256 i = 0; i < ids.length; i++) {
            IERC1155(asset).safeTransferFrom(address(this), recipient, ids[i], amounts[i], "");
        }
    }
}
