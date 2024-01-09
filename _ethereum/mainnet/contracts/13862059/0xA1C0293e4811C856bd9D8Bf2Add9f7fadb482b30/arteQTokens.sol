/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/billionbuild/arteq-contracts).
 * Copyright (c) 2021 BillionBuild (2B) Team.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./ERC1155Supply.sol";
import "./IarteQTokens.sol";
import "./IarteQTaskFinalizer.sol";

/// @author Kam Amini <kam@arteq.io> <kam@2b.team> <kam@arteq.io> <kam.cpp@gmail.com>
///
/// Reviewed and revised by: Masoud Khosravi <masoud_at_2b.team> <mkh_at_arteq.io>
///                          Ali Jafari <ali_at_2b.team> <aj_at_arteq.io>
///
/// @title This contract keeps track of the tokens used in artèQ Investment
/// Fund ecosystem. It also contains the logic used for profit distribution.
///
/// @notice Use at your own risk
contract arteQTokens is ERC1155Supply, IarteQTokens {

    /// The main artèQ token
    uint256 public constant ARTEQ = 1;

    /// The governance token of artèQ Investment Fund
    uint256 public constant gARTEQ = 2;

    // The mapping from token IDs to their respective Metadata URIs
    mapping (uint256 => string) private _tokenMetadataURIs;

    // The admin smart contract
    address private _adminContract;

    // Treasury account responsible for asset-token ratio appreciation.
    address private _treasuryAccount;

    // This can be a Uniswap V1/V2 exchange (pool) account created for ARTEQ token,
    // or any other exchange account. Treasury contract uses these pools to buy
    // back or sell tokens. In case of buy backs, the tokens must be delivered to
    // treasury account from these contracts. Otherwise, the profit distribution
    // logic doesn't get triggered.
    address private _exchange1Account;
    address private _exchange2Account;
    address private _exchange3Account;
    address private _exchange4Account;
    address private _exchange5Account;

    // All the profits accumulated since the deployment of the contract. This is
    // used as a marker to facilitate the caluclation of every eligible account's
    // share from the profits in a given time range.
    uint256 private _allTimeProfit;

    // The actual number of profit tokens transferred to accounts
    uint256 private _profitTokensTransferredToAccounts;

    // The percentage of the bought back tokens which is considered as profit for gARTEQ owners
    // Default value is 20% and only admin contract can change that.
    uint private _profitPercentage;

    // In order to caluclate the share of each elgiible account from the profits,
    // and more importantly, in order to do this efficiently (less gas usage),
    // we need this mapping to remember the "all time profit" when an account
    // is modified (receives tokens or sends tokens).
    mapping (address => uint256) private _profitMarkers;

    // A timestamp indicating when the ramp-up phase gets expired.
    uint256 private _rampUpPhaseExpireTimestamp;

    // Indicates until when the address cannot send any tokens
    mapping (address => uint256) private _lockedUntilTimestamps;

    /// Emitted when the admin contract is changed.
    event AdminContractChanged(address newContract);

    /// Emitted when the treasury account is changed.
    event TreasuryAccountChanged(address newAccount);

    /// Emitted when the exchange account is changed.
    event Exchange1AccountChanged(address newAccount);
    event Exchange2AccountChanged(address newAccount);
    event Exchange3AccountChanged(address newAccount);
    event Exchange4AccountChanged(address newAccount);
    event Exchange5AccountChanged(address newAccount);

    /// Emitted when the profit percentage is changed.
    event ProfitPercentageChanged(uint newPercentage);

    /// Emitted when a token distribution occurs during the ramp-up phase
    event RampUpPhaseTokensDistributed(address to, uint256 amount, uint256 lockedUntilTimestamp);

    /// Emitted when some buy back tokens are received by the treasury account.
    event ProfitTokensCollected(uint256 amount);

    /// Emitted when a share holder receives its tokens from the buy back profits.
    event ProfitTokensDistributed(address to, uint256 amount);

    // Emitted when profits are caluclated because of a manual buy back event
    event ManualBuyBackWithdrawalFromTreasury(uint256 amount);

    modifier adminApprovalRequired(uint256 adminTaskId) {
        _;
        // This must succeed otherwise the tx gets reverted
        IarteQTaskFinalizer(_adminContract).finalizeTask(msg.sender, adminTaskId);
    }

    modifier validToken(uint256 tokenId) {
        require(tokenId == ARTEQ || tokenId == gARTEQ, "arteQTokens: non-existing token");
        _;
    }

    modifier onlyRampUpPhase() {
        require(block.timestamp < _rampUpPhaseExpireTimestamp, "arteQTokens: ramp up phase is finished");
        _;
    }

    constructor(address adminContract) {
        _adminContract = adminContract;

        /// Must be set later
        _treasuryAccount = address(0);

        /// Must be set later
        _exchange1Account = address(0);
        _exchange2Account = address(0);
        _exchange3Account = address(0);
        _exchange4Account = address(0);
        _exchange5Account = address(0);

        string memory arteQURI = "ipfs://QmfBtH8BSztaYn3QFnz2qvu2ehZgy8AZsNMJDkgr3pdqT8";
        string memory gArteQURI = "ipfs://QmRAXmU9AymDgtphh37hqx5R2QXSS2ngchQRDFtg6XSD7w";
        _tokenMetadataURIs[ARTEQ] = arteQURI;
        emit URI(arteQURI, ARTEQ);
        _tokenMetadataURIs[gARTEQ] = gArteQURI;
        emit URI(gArteQURI, gARTEQ);

        /// 10 billion
        _initialMint(_adminContract, ARTEQ, 10 ** 10, "");
        /// 1 million
        _initialMint(_adminContract, gARTEQ, 10 ** 6, "");

        /// Obviously, no profit at the time of deployment
        _allTimeProfit = 0;

        _profitPercentage = 20;

        /// Tuesday, February 1, 2022 12:00:00 AM
        _rampUpPhaseExpireTimestamp = 1643673600;
    }

    /// See {ERC1155-uri}
    function uri(uint256 tokenId) external view virtual override validToken(tokenId) returns (string memory) {
        return _tokenMetadataURIs[tokenId];
    }

    function setURI(
        uint256 adminTaskId,
        uint256 tokenId,
        string memory newUri
    ) external adminApprovalRequired(adminTaskId) validToken(tokenId) {
        _tokenMetadataURIs[tokenId] = newUri;
        emit URI(newUri, tokenId);
    }

    /// Returns the set treasury account
    /// @return The set treasury account
    function getTreasuryAccount() external view returns (address) {
        return _treasuryAccount;
    }

    /// Sets a new treasury account. Just after deployment, treasury account is set to zero address but once
    /// set to a non-zero address, it cannot be changed back to zero address again.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newAccount new treasury address
    function setTreasuryAccount(uint256 adminTaskId, address newAccount) external adminApprovalRequired(adminTaskId) {
        require(newAccount != address(0), "arteQTokens: zero address for treasury account");
        _treasuryAccount = newAccount;
        emit TreasuryAccountChanged(newAccount);
    }

    /// Returns the 1st exchange account
    /// @return The 1st exchnage account
    function getExchange1Account() external view returns (address) {
        return _exchange1Account;
    }

    /// Returns the 2nd exchange account
    /// @return The 2nd exchnage account
    function getExchange2Account() external view returns (address) {
        return _exchange2Account;
    }

    /// Returns the 3rd exchange account
    /// @return The 3rd exchnage account
    function getExchange3Account() external view returns (address) {
        return _exchange3Account;
    }

    /// Returns the 4th exchange account
    /// @return The 4th exchnage account
    function getExchange4Account() external view returns (address) {
        return _exchange4Account;
    }

    /// Returns the 5th exchange account
    /// @return The 5th exchnage account
    function getExchange5Account() external view returns (address) {
        return _exchange5Account;
    }

    /// Sets a new exchange account. Just after deployment, exchange account is set to zero address but once
    /// set to a non-zero address, it cannot be changed back to zero address again.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newAccount new exchange address
    function setExchange1Account(uint256 adminTaskId, address newAccount) external adminApprovalRequired(adminTaskId) {
        require(newAccount != address(0), "arteQTokens: zero address for exchange account");
        _exchange1Account = newAccount;
        emit Exchange1AccountChanged(newAccount);
    }

    /// Sets a new exchange account. Just after deployment, exchange account is set to zero address but once
    /// set to a non-zero address, it cannot be changed back to zero address again.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newAccount new exchange address
    function setExchange2Account(uint256 adminTaskId, address newAccount) external adminApprovalRequired(adminTaskId) {
        require(newAccount != address(0), "arteQTokens: zero address for exchange account");
        _exchange2Account = newAccount;
        emit Exchange2AccountChanged(newAccount);
    }

    /// Sets a new exchange account. Just after deployment, exchange account is set to zero address but once
    /// set to a non-zero address, it cannot be changed back to zero address again.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newAccount new exchange address
    function setExchange3Account(uint256 adminTaskId, address newAccount) external adminApprovalRequired(adminTaskId) {
        require(newAccount != address(0), "arteQTokens: zero address for exchange account");
        _exchange3Account = newAccount;
        emit Exchange3AccountChanged(newAccount);
    }

    /// Sets a new exchange account. Just after deployment, exchange account is set to zero address but once
    /// set to a non-zero address, it cannot be changed back to zero address again.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newAccount new exchange address
    function setExchange4Account(uint256 adminTaskId, address newAccount) external adminApprovalRequired(adminTaskId) {
        require(newAccount != address(0), "arteQTokens: zero address for exchange account");
        _exchange4Account = newAccount;
        emit Exchange4AccountChanged(newAccount);
    }

    /// Sets a new exchange account. Just after deployment, exchange account is set to zero address but once
    /// set to a non-zero address, it cannot be changed back to zero address again.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newAccount new exchange address
    function setExchange5Account(uint256 adminTaskId, address newAccount) external adminApprovalRequired(adminTaskId) {
        require(newAccount != address(0), "arteQTokens: zero address for exchange account");
        _exchange5Account = newAccount;
        emit Exchange5AccountChanged(newAccount);
    }

    /// Returns the profit percentage
    /// @return The set treasury account
    function getProfitPercentage() external view returns (uint) {
        return _profitPercentage;
    }

    /// Sets a new profit percentage. This is the percentage of bought-back tokens which is considered
    /// as profit for gARTEQ owners. The value can be between 10% and 50%.
    ///
    /// @param adminTaskId the task which must have been approved by multiple admins
    /// @param newPercentage new exchange address
    function setProfitPercentage(uint256 adminTaskId, uint newPercentage) external adminApprovalRequired(adminTaskId) {
        require(newPercentage >= 10 && newPercentage <= 50, "arteQTokens: invalid value for profit percentage");
        _profitPercentage = newPercentage;
        emit ProfitPercentageChanged(newPercentage);
    }

    /// Transfer from admin contract
    function transferFromAdminContract(
        uint256 adminTaskId,
        address to,
        uint256 id,
        uint256 amount
    ) external adminApprovalRequired(adminTaskId) {
        _safeTransferFrom(_msgSender(), _adminContract, to, id, amount, "");
    }

    /// A token distribution mechanism, only valid in ramp-up phase, valid till the end of Jan 2022.
    function rampUpPhaseDistributeToken(
        uint256 adminTaskId,
        address[] memory tos,
        uint256[] memory amounts,
        uint256[] memory lockedUntilTimestamps
    ) external adminApprovalRequired(adminTaskId) onlyRampUpPhase {
        require(tos.length == amounts.length, "arteQTokens: inputs have incorrect lengths");
        for (uint256 i = 0; i < tos.length; i++) {
            require(tos[i] != _treasuryAccount, "arteQTokens: cannot transfer to treasury account");
            require(tos[i] != _adminContract, "arteQTokens: cannot transfer to admin contract");
            _safeTransferFrom(_msgSender(), _adminContract, tos[i], ARTEQ, amounts[i], "");
            if (lockedUntilTimestamps[i] > 0) {
                _lockedUntilTimestamps[tos[i]] = lockedUntilTimestamps[i];
            }
            emit RampUpPhaseTokensDistributed(tos[i], amounts[i], lockedUntilTimestamps[i]);
        }
    }

    function balanceOf(address account, uint256 tokenId) public view virtual override validToken(tokenId) returns (uint256) {
        if (tokenId == gARTEQ) {
            return super.balanceOf(account, tokenId);
        }
        return super.balanceOf(account, tokenId) + _calcUnrealizedProfitTokens(account);
    }

    function allTimeProfit() external view returns (uint256) {
        return _allTimeProfit;
    }

    function totalCirculatingGovernanceTokens() external view returns (uint256) {
        return totalSupply(gARTEQ) - balanceOf(_adminContract, gARTEQ);
    }

    function profitTokensTransferredToAccounts() external view returns (uint256) {
        return _profitTokensTransferredToAccounts;
    }

    function compatBalanceOf(address /* origin */, address account, uint256 tokenId) external view virtual override returns (uint256) {
        return balanceOf(account, tokenId);
    }

    function compatTotalSupply(address /* origin */, uint256 tokenId) external view virtual override returns (uint256) {
        return totalSupply(tokenId);
    }

    function compatTransfer(address origin, address to, uint256 tokenId, uint256 amount) external virtual override {
        address from = origin;
        _safeTransferFrom(origin, from, to, tokenId, amount, "");
    }

    function compatTransferFrom(address origin, address from, address to, uint256 tokenId, uint256 amount) external virtual override {
        require(
            from == origin || isApprovedForAll(from, origin),
            "arteQTokens: caller is not owner nor approved "
        );
        _safeTransferFrom(origin, from, to, tokenId, amount, "");
    }

    function compatAllowance(address /* origin */, address account, address operator) external view virtual override returns (uint256) {
        if (isApprovedForAll(account, operator)) {
            return 2 ** 256 - 1;
        }
        return 0;
    }

    function compatApprove(address origin, address operator, uint256 amount) external virtual override {
        _setApprovalForAll(origin, operator, amount > 0);
    }

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueTokens(uint256 adminTaskId, IERC20 foreignToken, address to) external adminApprovalRequired(adminTaskId) {
        foreignToken.transfer(to, foreignToken.balanceOf(address(this)));
    }

    // If this contract gets a balance in some ERC721 contract after it's finished, then we can rescue it.
    function approveNFTRescue(uint256 adminTaskId, IERC721 foreignNFT, address to) external adminApprovalRequired(adminTaskId) {
        foreignNFT.setApprovalForAll(to, true);
    }

    // In case of any manual buy back event which is not processed through DEX contracts, this function
    // helps admins distribute the profits. This function must be called only when the bought back tokens
    // have been successfully transferred to treasury account.
    function processManualBuyBackEvent(uint256 adminTaskId, uint256 boughtBackTokensAmount) external adminApprovalRequired(adminTaskId) {
        uint256 profit = (boughtBackTokensAmount * _profitPercentage) / 100;
        if (profit > 0) {
            _balances[ARTEQ][_treasuryAccount] -= profit;
            emit ManualBuyBackWithdrawalFromTreasury(profit);
            _allTimeProfit += profit;
            emit ProfitTokensCollected(profit);
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        // We have to call the super function in order to have the total supply correct.
        // It is actually needed by the first two _initialMint calls only. After that, it is
        // a no-op function.
        super._beforeTokenTransfer(operator, from, to, id, amounts, data);

        // this is one of the two first _initialMint calls
        if (from == address(0)) {
            return;
        }

        // This is a buy-back callback from exchange account
        if ((
                from == _exchange1Account ||
                from == _exchange2Account ||
                from == _exchange3Account ||
                from == _exchange4Account ||
                from == _exchange5Account
        ) && to == _treasuryAccount) {
            require(amounts.length == 2 && id == ARTEQ, "arteQTokens: invalid transfer from exchange");
            uint256 profit = (amounts[0] * _profitPercentage) / 100;
            amounts[1] = amounts[0] - profit;
            if (profit > 0) {
                _allTimeProfit += profit;
                emit ProfitTokensCollected(profit);
            }
            return;
        }

        // Ensures that the locked accounts cannot send their ARTEQ tokens
        if (id == ARTEQ) {
            require(_lockedUntilTimestamps[from] == 0 || block.timestamp > _lockedUntilTimestamps[from], "arteQTokens: account cannot send tokens");
        }

        // Realize/Transfer the accumulated profit of 'from' account and make it spendable
        if (from != _adminContract &&
            from != _treasuryAccount &&
            from != _exchange1Account &&
            from != _exchange2Account &&
            from != _exchange3Account &&
            from != _exchange4Account &&
            from != _exchange5Account) {
            _realizeAccountProfitTokens(from);
        }

        // Realize/Transfer the accumulated profit of 'to' account and make it spendable
        if (to != _adminContract &&
            to != _treasuryAccount &&
            to != _exchange1Account &&
            to != _exchange2Account &&
            to != _exchange3Account &&
            to != _exchange4Account &&
            to != _exchange5Account) {
            _realizeAccountProfitTokens(to);
        }
    }

    function _calcUnrealizedProfitTokens(address account) internal view returns (uint256) {
        if (account == _adminContract ||
            account == _treasuryAccount ||
            account == _exchange1Account ||
            account == _exchange2Account ||
            account == _exchange3Account ||
            account == _exchange4Account ||
            account == _exchange5Account) {
            return 0;
        }
        uint256 profitDifference = _allTimeProfit - _profitMarkers[account];
        uint256 totalGovTokens = totalSupply(gARTEQ) - balanceOf(_adminContract, gARTEQ);
        if (totalGovTokens == 0) {
            return 0;
        }
        uint256 tokensToTransfer = (profitDifference * balanceOf(account, gARTEQ)) / totalGovTokens;
        return tokensToTransfer;
    }

    // This function actually transfers the unrealized accumulated profit tokens of an account
    // and make them spendable by that account. The balance should not differ after the
    // trasnfer as the balance already includes the unrealized tokens.
    function _realizeAccountProfitTokens(address account) internal {
        bool updateProfitMarker = true;
        // If 'account' has some governance tokens then calculate the accumulated profit since the last distribution
        if (balanceOf(account, gARTEQ) > 0) {
            uint256 tokensToTransfer = _calcUnrealizedProfitTokens(account);
            // If the profit is too small and no token can be transferred, then don't update the profit marker and
            // let the account wait for the next round of profit distribution
            if (tokensToTransfer == 0) {
                updateProfitMarker = false;
            } else {
                _balances[ARTEQ][account] += tokensToTransfer;
                _profitTokensTransferredToAccounts += tokensToTransfer;
                emit ProfitTokensDistributed(account, tokensToTransfer);
            }
        }
        if (updateProfitMarker) {
            _profitMarkers[account] = _allTimeProfit;
        }
    }

    receive() external payable {
        revert("arteQTokens: cannot accept ether");
    }

    fallback() external payable {
        revert("arteQTokens: cannot accept ether");
    }
}
