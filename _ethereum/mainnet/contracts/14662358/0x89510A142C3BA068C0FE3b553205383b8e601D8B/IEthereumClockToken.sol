// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IERC721.sol";
import {IAdmin} from  "./IAdmin.sol";

/**
 * @title EthereumClockToken Interface
 * @author JieLi
 *
 * @notice EthereumClockToken Interface
 */
interface IEthereumClockToken is IERC721, IAdmin {

    /// @notice Event emitted when owner withdrew the ETH.
    event EthWithdrew(address receiver, uint256 amount);

    /// @notice Event emitted when owner withdrew total ETH.
    event Withdrew(address receiver);

    /// @notice event emitted when BaseURI updated
    event BaseURIUpdated(string _newBaseURI);

    event Frozen(address indexed tokenOwner, uint256 indexed tokenId);

    event Charred(address indexed tokenOwner, uint256 indexed tokenId);

    event Redeem(uint256 indexed tokenId, address indexed tokenOwner, uint256 indexed timeStamp);

    event Enhanced(address indexed tokenOwner, uint256 indexed tokenId);

    event Failed(address indexed Owner, uint256 indexed tokenId);

    event GodTier(address indexed Owner, uint256 indexed tokenId);

    // ============= Functions ===========

    function setFrozen(uint256 tokenId) external;

    function setCharred(uint256 tokenId) external;

    function redeem(uint256 tokenId) external;

    function enhance(uint256 tokenId) external returns (bool);

    function godTier(uint256 tokenId) external returns (bool);

    function fail(uint256 tokenId) external returns (bool);

}
