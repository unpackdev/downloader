pragma solidity =0.8.15;

import "./IIndexToken.sol";
import "./IVault.sol";
import "./Common.sol";
import "./FixedPoint.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

interface Rebalancer {
    function rebalanceCallback(
        TokenInfo[] calldata required,
        TokenInfo[] calldata received
    ) external;
}

interface IActiveBounty {
    function activeBounty() external view returns (bytes32);

    function authority() external view returns (address);
}

struct Bounty {
    TokenInfo[] infos;
    uint256 deadline;
    bytes32 salt;
}

struct QuoteInput {
    TokenInfo[] targets;
    uint256 supply;
    uint256 trackedMultiplier;
}

contract InvokeableBounty {
    using SafeERC20 for IERC20;
    error BountyInvalidHash();
    error BountyAlreadyCompleted();
    error BountyPastDeadline();
    error BountyAMKTSupplyChange();
    error BountyReentrant();
    error BountyMustIncludeAllUnderlyings();

    event BountyFulfilled(Bounty bounty, bool callback);

    mapping(bytes32 => bool) public completedBounties;

    IIndexToken public immutable indexToken;

    IVault public immutable vault;

    IActiveBounty public immutable activeBounty;

    uint256 public immutable version;
    uint256 public immutable chainId;

    uint256 public reentrancyLock = 1;

    modifier ReentrancyGuard() {
        if (reentrancyLock > 1) revert BountyReentrant();
        reentrancyLock = 2;
        _;
        reentrancyLock = 1;
    }

    modifier invariantCheck() {
        _;
        vault.invariantCheck();
    }

    constructor(
        address _vault,
        address _activeBounty,
        uint256 _version,
        uint256 _chainId
    ) {
        vault = IVault(_vault);
        indexToken = IIndexToken(vault.indexToken());
        activeBounty = IActiveBounty(_activeBounty);
        version = _version;
        chainId = _chainId;
    }

    /// @notice fulfill a bounty, were going to reset the multiplier to 1 (SCALAR) here
    /// @dev we send out the tokens first, so we need to check for weird supply stuff
    /// @dev also we dont follow CEI so we need to check for reentrancy
    /// @dev the units in the bounty are the target units, ie amount of units per 1e18 amkt
    /// @dev check for supply becasue even though they mint/burn at the smae price becasue nominals havent been changed yet,
    ///      if the  supply changes the "value" of the first leg will be differnt from the "value" of the second leg
    ///
    ///
    /// @param bounty the bounty to fulfill
    /// @param callback whether or not to call the rebalancer callback
    function fulfillBounty(
        Bounty memory bounty,
        bool callback
    ) external ReentrancyGuard invariantCheck {
        bytes32 bountyHash = hashBounty(bounty);

        if (activeBounty.activeBounty() != bountyHash)
            revert BountyInvalidHash();

        if (completedBounties[bountyHash]) revert BountyAlreadyCompleted();

        if (block.timestamp > bounty.deadline) revert BountyPastDeadline();

        vault.tryInflation();

        (, uint256 trackedMultiplier, , ) = vault.multiplier();

        uint256 startingSupply = indexToken.totalSupply();

        (
            IVault.InvokeERC20Args[] memory outs,
            TokenInfo[] memory ins,
            IVault.SetNominalArgs[] memory nominals,
            uint256 underlyingTally
        ) = _quote(QuoteInput(bounty.infos, startingSupply, trackedMultiplier));

        if (underlyingTally < vault.underlyingLength())
            revert BountyMustIncludeAllUnderlyings();

        // sends all the tokens to the rebalancer first
        vault.invokeERC20s(outs);

        if (callback) {
            Rebalancer(msg.sender).rebalanceCallback(ins, intoTokenInfo(outs));
        }

        if (indexToken.totalSupply() != startingSupply) {
            revert BountyAMKTSupplyChange();
        }

        // take all tokens from msg.sender
        for (uint256 i; i < ins.length; i++) {
            IERC20(ins[i].token).safeTransferFrom(
                msg.sender,
                address(vault),
                ins[i].units
            );
        }

        // in case any tokens have a callback
        if (indexToken.totalSupply() != startingSupply) {
            revert BountyAMKTSupplyChange();
        }

        vault.invokeSetNominals(nominals);
        vault.invokeSetMultiplier(SCALAR);

        completedBounties[bountyHash] = true;
        emit BountyFulfilled(bounty, callback);
    }

    /// @notice quote a bounty, returns the ins and outs
    /// @dev the units in the bounty are the target units, ie amount of units per 1e18 amkt
    /// @param bounty the bounty to quote
    function quoteBounty(
        Bounty calldata bounty
    ) external view returns (TokenInfo[] memory outs, TokenInfo[] memory) {
        (, uint256 trackedMultipler, , ) = vault.multiplier();

        uint256 startingSupply = indexToken.totalSupply();

        TokenInfo[] memory targets = bounty.infos;

        (
            IVault.InvokeERC20Args[] memory _outs,
            TokenInfo[] memory ins,
            ,

        ) = _quote(QuoteInput(targets, startingSupply, trackedMultipler));

        outs = intoTokenInfo(_outs);
        return (outs, ins);
    }

    function _quote(
        QuoteInput memory input
    )
        internal
        view
        returns (
            IVault.InvokeERC20Args[] memory outs,
            TokenInfo[] memory ins,
            IVault.SetNominalArgs[] memory nominals,
            uint256 underlyingTally
        )
    {
        outs = new IVault.InvokeERC20Args[](input.targets.length);

        ins = new TokenInfo[](input.targets.length);

        nominals = new IVault.SetNominalArgs[](input.targets.length);

        // store the lengths because we dont actually know the size off the bat
        uint256 lenOuts;
        uint256 lenIns;
        uint256 lenNominals;

        for (uint256 i; i < input.targets.length; i++) {
            address token = input.targets[i].token;

            if (vault.isUnderlying(token)) underlyingTally++;

            // number of target units per 1e18 amkt
            uint256 targetUnits = input.targets[i].units;

            uint256 realUnitsAtLastFeeTimestamp = fmul(
                vault.virtualUnits(token),
                input.trackedMultiplier
            );

            if (realUnitsAtLastFeeTimestamp > targetUnits) {
                outs[lenOuts] = IVault.InvokeERC20Args(
                    token,
                    msg.sender,
                    fmul(
                        realUnitsAtLastFeeTimestamp - targetUnits,
                        input.supply
                    )
                );

                unchecked {
                    lenOuts++;
                }
            } else if (targetUnits > realUnitsAtLastFeeTimestamp) {
                ins[lenIns] = TokenInfo(
                    token,
                    fmul(
                        targetUnits - realUnitsAtLastFeeTimestamp,
                        input.supply
                    )
                );

                unchecked {
                    lenIns++;
                }
            } else {
                // theyre equal so we dont need to do anything
                continue;
            }

            nominals[lenNominals] = IVault.SetNominalArgs(token, targetUnits);

            unchecked {
                lenNominals++;
            }
        }

        // use assembly to set the actual sizes so were not sending over a bunch of empty data
        // no effect, since the compiler is planning on allocating outside of this empty zone anyway
        assembly {
            mstore(outs, lenOuts)
            mstore(ins, lenIns)
            mstore(nominals, lenNominals)
        }

        return (outs, ins, nominals, underlyingTally);
    }

    /// @notice hash a bounty
    /// @param bounty, the bounty to hash
    function hashBounty(
        Bounty memory bounty
    ) public view returns (bytes32 hash) {
        return
            keccak256(
                abi.encodePacked(
                    "alongside::invoker::bounty",
                    abi.encode(version),
                    abi.encode(chainId),
                    keccak256(abi.encode(bounty))
                )
            );
    }

    function intoTokenInfo(
        IVault.InvokeERC20Args[] memory args
    ) internal pure returns (TokenInfo[] memory infos) {
        infos = new TokenInfo[](args.length);

        for (uint256 i; i < args.length; i++) {
            infos[i] = TokenInfo(args[i].token, args[i].amount);
        }
    }
}
