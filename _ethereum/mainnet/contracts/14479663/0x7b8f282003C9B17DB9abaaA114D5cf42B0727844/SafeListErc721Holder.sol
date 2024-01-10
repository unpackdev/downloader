// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ReentrancyGuard.sol";
import "./AvantArteDrawInterface.sol";
import "./Erc721SingleAddressHolder.sol";
import "./SafeListController.sol";
import "./BasicFunctionality.sol";
import "./WithdrawSplitter.sol";
import "./TimerController.sol";

struct Props {
    address proxyAddr;
    address owner;
    uint256 costInWei;
    address[] safeList;
    uint256 maxPurchaseAmount;
    WithdrawSplit[] withdrawSplits;
}

contract SafeListErc721Holder is
    ReentrancyGuard,
    Erc721SingleAddressHolder,
    SafeListController,
    BasicFunctionality,
    WithdrawSplitter,
    AvantArteDrawInterface
{
    constructor(Props memory props)
        SafeListController(MSLCProps(props.safeList, props.maxPurchaseAmount))
        Erc721SingleAddressHolder(props.proxyAddr)
        BasicFunctionality(BFProps(props.owner, props.costInWei))
        WithdrawSplitter(props.withdrawSplits)
    {
        proxyAddr = props.proxyAddr;
    }

    /// @dev allows to purchase a token
    function purchase(
        uint256 tokenId,
        string calldata productId,
        string calldata accountId
    ) external payable override onlyRunning onlyEnabled onlySafeListed {
        require(availableErc721Tokens.length > 0, "no supply");
        require(msg.value >= costInWei, "no funds");
        _incrementCount();
        _incrementAddressPurchasedCount(1);

        _splitWithdraw(msg.value);
        emit OnPurchase(msg.sender, tokenId, productId, accountId);
        _safeTransferErc721Token(tokenId, msg.sender, msg.data);
    }

    /// @dev allows admins to take the remaining tokens in the end of the draw
    function withdrawTokens(uint256[] calldata tokenIds) external onlyOwner {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            _safeTransferErc721Token(tokenIds[i], msg.sender, msg.data);
        }
    }

    /// @dev allows admins to assign tokens manually
    function assignTokens(uint256[] calldata tokenIds) external onlyOwner {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            availableErc721Tokens.push(tokenIds[i]);
        }
    }

    /// @dev removed mistakenly assigned tokens
    function unassignTokens(uint256[] calldata tokenIds) external onlyOwner {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            _removeListedErc721Token(tokenIds[i]);
        }
    }

    function isActive() external view override returns (bool) {
        return isEnabled && _isTimerRunning();
    }

    function count(uint256) external view override returns (uint256) {
        return availableErc721Tokens.length;
    }

    function cost(uint256) external view override returns (uint256) {
        return costInWei;
    }

    function isAllowedToPurchase(uint256)
        external
        view
        virtual
        override
        returns (bool)
    {
        return
            isEnabled && _isTimerRunning() && _isAddressSafeListed(msg.sender);
    }

    function getAvailableTokenId()
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _safeGetFirstErc721Token();
    }

    function getTimerData()
        external
        view
        virtual
        override
        returns (TimerData memory)
    {
        return _getTimerData();
    }

    function setWithdrawSplit(WithdrawSplit[] calldata _withdrawSplits)
        external
        onlyOwner
    {
        _setWithdrawSplit(_withdrawSplits);
    }
}
