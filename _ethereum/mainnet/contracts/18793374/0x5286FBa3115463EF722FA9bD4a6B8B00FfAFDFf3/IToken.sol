// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IERC20Upgradeable.sol";
import "./IVotesUpgradeable.sol";
import "./IService.sol";

interface IToken is IVotesUpgradeable, IERC20Upgradeable {
    /**
     * @notice This structure is used to define the parameters of ERC20 tokens issued by the protocol for pools.
     * @dev This structure is suitable for both Governance and Preference tokens if they are based on ERC20.
     * @param tokenType Numeric code for the token type
     * @param name Full name of the token
     * @param symbol Ticker symbol (short name) of the token
     * @param description Description of the token
     * @param cap Maximum allowable token issuance
     * @param decimals Number of decimal places for the token (precision)
     */
    struct TokenInfo {
        TokenType tokenType;
        string name;
        string symbol;
        string description;
        uint256 cap;
        uint8 decimals;
    }
    /**
     * @notice Token type encoding
     */
    enum TokenType {
        None,
        Governance,
        Preference
    }

    function initialize(
        IService service_,
        address pool_,
        TokenInfo memory info,
        address primaryTGE_
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function cap() external view returns (uint256);

    function unlockedBalanceOf(address account) external view returns (uint256);

    function pool() external view returns (address);

    function service() external view returns (IService);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function tokenType() external view returns (TokenType);

    function lastTGE() external view returns (address);

    function getTGEList() external view returns (address[] memory);

    function isPrimaryTGESuccessful() external view returns (bool);

    function addTGE(address tge) external;

    function addTSE(address account, address tse) external;

    function setTGEVestedTokens(uint256 amount) external;

    function setProtocolFeeReserved(uint256 amount) external;

    function getTotalTGEVestedTokens() external view returns (uint256);

    function getTotalProtocolFeeReserved() external view returns (uint256);

    function totalSupplyWithReserves() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function delegate(address delegatee) external;

    function setCompliance(bytes32 compliance_) external;

    function partnerFee() external view returns (uint256);

    function partnerAddress() external view returns (address);

    function depositDividends(
        address tokenAddress,
        uint256 amount
    ) external payable;

    function claimDividends() external;
}
