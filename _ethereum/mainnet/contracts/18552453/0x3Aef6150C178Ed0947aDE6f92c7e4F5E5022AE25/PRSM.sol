
pragma solidity =0.8.21;

import "./ERC20.sol";
import {Owned} from "Owned.sol";

import {WETH} from "WETH.sol";
import {IUniswapV2Router02} from "IUniswapV2Router02.sol";

contract Prism is ERC20, Owned {
    mapping(address => bool) public transferLimitImmune;

    // This is the initial max tradable amount
    // This is set lower than the final amount to prevent snipers getting too much
    // After it is changed this value will be 174747670
    // This number is 0.108% of the golden proportion
    uint256 internal max_tradable = 1747476;

    address public immutable immutable_repository;

    error Retain();
    error OverTransferLimit();

    constructor(
        address _pool,
        address _angels,
        address _exchanges,
        address _contributors,
        address _atonement
    ) payable Owned(msg.sender)  {
        // This is the Fibonacci Allocation
        uint supply = 112358132134558914423337761098715972584418167651094617711286574636875025121393;

        // This is the circulating supply
        uint golden_proportion = 161803398874;

        // Refer to documentation for percentages and explanation of distribution
        uint pool = 116498447191;
        uint angels = 14562305898;
        uint exchanges = 9708203932;
        uint contributors = 4854101966;
        uint atonement = 16180339887;
        
        assert(pool + angels + exchanges + contributors + atonement == golden_proportion);

        //The Immutable Repository is the deployer which retains the Fibonacci Allocation permanently.
        //Holders should model their behavior after the Immutable Repository and learn the power of retaining.
        immutable_repository = msg.sender;

        // Allow mints over max tradable
        transferLimitImmune[address(0)] = true;

        // Allow transfers over max tradable
        transferLimitImmune[_pool] = true;
        transferLimitImmune[_angels] = true;
        transferLimitImmune[_exchanges] = true;
        transferLimitImmune[_contributors] = true;
        transferLimitImmune[_atonement] = true;

        // Mint the fibonacci sequence
        _mint(immutable_repository, supply);

        // Mint tokens to the addresses
        _mint(_angels, angels);
        _mint(_exchanges, exchanges);
        _mint(_contributors, contributors);
        _mint(_atonement, atonement);

        _mint(_pool, pool);
    }

    function name() public pure override returns (string memory) {
        return "Prism";
    }
    function symbol() public pure override returns (string memory) {
        return "PRSM";
    }
    function decimals() public pure override returns (uint8) {
        return 27;
    }
    function changeTradable() public onlyOwner {
        max_tradable = 174747670;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override {
        // Cannot read immutable variables from assembly
        address repo = immutable_repository;
        /// @solidity memory-safe-assembly
        assembly {
            // If 'from' is the Immutable Repository then revert
            if eq(repo, from) {
                // Store revert signature in memory
                mstore(0x00, 0x7c53b42a)
                revert(0x1c, 0x04) // Revert with Retain()
            }
            // If amount > max tradable check if 'from' is immune
            // if amount is less than max tradable continue to transfer()
            if gt(amount, sload(max_tradable.slot)) {
                // Store from and immunity storage slot in memory for hashing
                mstore(0x00, from)
                mstore(0x20, transferLimitImmune.slot)
                // load the hashed value to get storage hash of value
                // if 'from' is not immune then revert
                // 'from' must be set to true from constructor
                // Only those addresses will not trigger this revert here
                if iszero(sload(keccak256(0x00, 0x40))) {
                    // Store revert signature in memory
                    mstore(0x00, 0xb26fb503)
                    revert(0x1c, 0x04) // Revert with OverTransferLimit()
                }
            }
        }
    }

    function _constantNameHash() internal pure override returns (bytes32 result) {
        // keccak256(bytes("Spectrum"))
        return 0x7a19dfb547ec25cf2f18bf07f0ba0d617689900af227b2911fa9e71b22422ac4;
    }
}