// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import "./Clone.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";
import "./FullMath.sol";

///
/// @title VestingModule
/// @author 0xSplits <will@0xSplits.xyz>
/// @notice A maximally-composable vesting contract allowing multiple isolated
/// streams of different tokens to reach a beneficiary over time. Streams share
/// a vesting period but may begin or have funds released independently.
/// @dev Funds pile up in the contract via `receive()` & simple ERC20 `transfer`
/// until a caller creates a new vesting stream. The funds then vest linearly
/// over {vestingPeriod} and may be withdrawn accordingly by anyone on behalf
/// of the {beneficiary}. There is no limit on the number of simultaneous
/// vesting streams which may be created, ongoing or withdrawn from in a single
/// tx.
/// This contract uses address(0) in some fns/events/mappings to refer to ETH.
///
contract VestingModule is Clone {
    /// -----------------------------------------------------------------------
    /// errors
    /// -----------------------------------------------------------------------

    error InvalidVestingStreamId(uint256 id);

    /// -----------------------------------------------------------------------
    /// libraries
    /// -----------------------------------------------------------------------

    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /// -----------------------------------------------------------------------
    /// events
    /// -----------------------------------------------------------------------

    /// @notice New vesting stream created
    /// @param id Id of vesting stream
    /// @param token Address of token to vest (0x0 for ETH)
    /// @param amount Amount to vest
    event CreateVestingStream(
        uint256 indexed id,
        address indexed token,
        uint256 amount
    );

    /// @notice Release from vesting stream
    /// @param id Id of vesting stream
    /// @param amount Amount released from stream
    event ReleaseFromVestingStream(uint256 indexed id, uint256 amount);

    /// @notice Emitted after each successful ETH transfer to proxy
    /// @param amount Amount of ETH received
    event ReceiveETH(uint256 amount);

    /// -----------------------------------------------------------------------
    /// structs
    /// -----------------------------------------------------------------------

    /// @notice holds vesting stream metadata
    struct VestingStream {
        address token;
        uint256 vestingStart;
        uint256 total;
        uint256 released;
    }

    /// -----------------------------------------------------------------------
    /// storage
    /// -----------------------------------------------------------------------

    /// Address to receive funds after vesting
    /// @dev equivalent to address public immutable beneficiary;
    function beneficiary() public pure returns (address) {
        return _getArgAddress(0);
    }

    /// Period of time for funds to vest (defaults to 365 days)
    /// @dev equivalent to uint256 public immutable vestingPeriod;
    function vestingPeriod() public pure returns (uint256) {
        return _getArgUint256(20);
    }

    /// Number of vesting streams
    /// @dev Used for sequential ids
    uint256 public numVestingStreams;

    /// Mapping from Id to vesting stream
    mapping(uint256 => VestingStream) internal vestingStreams;
    /// Mapping from token to amount vesting (includes current & previous)
    mapping(address => uint256) public vesting;
    /// Mapping from token to amount released
    mapping(address => uint256) public released;

    /// -----------------------------------------------------------------------
    /// constructor
    /// -----------------------------------------------------------------------

    // solhint-disable-next-line no-empty-blocks
    constructor() {}

    /// -----------------------------------------------------------------------
    /// functions
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// functions - public & external
    /// -----------------------------------------------------------------------

    /// @notice receive ETH
    /// @dev receive with emitted event is implemented w/i clone bytecode
    /* receive() external payable { */
    /*     emit ReceiveETH(msg.value); */
    /* } */

    /// @notice Creates new vesting streams
    /// @param tokens Addresses of ETH (0x0) & ERC20s to begin vesting
    /// @return ids Ids of created vesting streams for {tokens}
    function createVestingStreams(address[] calldata tokens)
        external
        payable
        returns (uint256[] memory ids)
    {
        uint256 numTokens = tokens.length;
        ids = new uint256[](numTokens);
        // use count as first new sequential id
        uint256 vestingStreamId = numVestingStreams;

        unchecked {
            // overflow should be impossible in for-loop index
            for (uint256 i = 0; i < numTokens; ++i) {
                address token = tokens[i];
                // overflow should be impossible
                // shouldn't need to worry about re-entrancy from ERC20 view fn
                // recognizes 0x0 as ETH
                // user chooses tokens array, pernicious ERC20 can't cause DoS
                // slither-disable-next-line calls-loop
                uint256 pendingAmount = (
                    token != address(0)
                        ? ERC20(token).balanceOf(address(this))
                        : address(this).balance
                    // vesting >= released
                ) - (vesting[token] - released[token]);
                vesting[token] += pendingAmount;
                // overflow should be impossible
                vestingStreams[vestingStreamId] = VestingStream({
                    token: token,
                    vestingStart: block.timestamp, // solhint-disable-line not-rely-on-time
                    total: pendingAmount,
                    released: 0
                });
                emit CreateVestingStream(vestingStreamId, token, pendingAmount);
                ids[i] = vestingStreamId;
                ++vestingStreamId;
            }
            // use last created id as new count
            numVestingStreams = vestingStreamId;
        }
    }

    /// @notice Releases vested funds to the beneficiary
    /// @param ids Ids of vesting streams to release funds from
    /// @return releasedFunds Amounts of funds released from vesting streams {ids}
    function releaseFromVesting(uint256[] calldata ids)
        external
        payable
        returns (uint256[] memory releasedFunds)
    {
        uint256 numIds = ids.length;
        releasedFunds = new uint256[](numIds);

        unchecked {
            // overflow should be impossible in for-loop index
            for (uint256 i = 0; i < numIds; ++i) {
                uint256 id = ids[i];
                if (id >= numVestingStreams) revert InvalidVestingStreamId(id);
                VestingStream memory vs = vestingStreams[id];
                uint256 transferAmount = _vestedAndUnreleased(vs);
                address token = vs.token;
                // overflow should be impossible
                vestingStreams[id].released += transferAmount;
                // overflow should be impossible
                released[token] += transferAmount;
                // don't need to worry about re-entrancy; funds can't be stolen from beneficiary
                // pernicious ERC20s would only mess their own storage, not brick the balance of any ERC20 or ETH
                if (token != address(0)) {
                    ERC20(token).safeTransfer(beneficiary(), transferAmount);
                } else {
                    beneficiary().safeTransferETH(transferAmount);
                }

                emit ReleaseFromVestingStream(id, transferAmount);
                releasedFunds[i] = transferAmount;
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// functions - views
    /// -----------------------------------------------------------------------

    /// @notice View vesting stream {id}
    /// @param id Id of vesting stream to view
    /// @return vs Vesting stream
    function vestingStream(uint256 id)
        external
        view
        returns (VestingStream memory vs)
    {
        vs = vestingStreams[id];
    }

    /// @notice View vested amount in vesting stream {id}
    /// @param id Id of vesting stream to get vested amount of
    /// @return Amount vested in vesting stream {id}
    function vested(uint256 id) external view returns (uint256) {
        VestingStream memory vs = vestingStreams[id];
        return _vested(vs);
    }

    /// @notice View vested-and-unreleased amount in vesting stream {id}
    /// @param id Id of vesting stream to get vested-and-unreleased amount of
    /// @return Amount vested-and-unreleased in vesting stream {id}
    function vestedAndUnreleased(uint256 id) external view returns (uint256) {
        VestingStream memory vs = vestingStreams[id];
        return _vestedAndUnreleased(vs);
    }

    /// -----------------------------------------------------------------------
    /// functions - private & internal
    /// -----------------------------------------------------------------------

    /// @notice View vested amount in vesting stream {vs}
    /// @param vs Vesting stream to get vested amount of
    /// @return Amount vested in vesting stream {vs}
    function _vested(VestingStream memory vs) internal view returns (uint256) {
        uint256 elapsedTime;
        unchecked {
            // block.timestamp >= vs.vestingStart for any existing stream
            // solhint-disable-next-line not-rely-on-time
            elapsedTime = block.timestamp - vs.vestingStart;
        }
        return
            elapsedTime >= vestingPeriod()
                ? vs.total
                : FullMath.mulDiv(vs.total, elapsedTime, vestingPeriod());
    }

    /// @notice View vested-and-unreleased amount in vesting stream {vs}
    /// @param vs Vesting stream to get vested-and-unreleased amount of
    /// @return Amount vested-and-unreleased in vesting stream {vs}
    function _vestedAndUnreleased(VestingStream memory vs)
        internal
        view
        returns (uint256)
    {
        unchecked {
            // underflow should be impossible
            return _vested(vs) - vs.released;
        }
    }
}
