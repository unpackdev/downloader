// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Ownable.sol";
import "./IERC721.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./LibSwap.sol";
import "./LibEIP712.sol";
import "./ValidatorSwap.sol";

contract SPSwap is Ownable, Pausable, ReentrancyGuard, ValidatorSwap {
    using LibSwap for LibSwap.Swap;

    string private constant _EIP712_NAME = "SPSwap";
    string private constant _EIP712_VERSION = "1.0";

    /**
     * @dev Mapping of swapHash => bool indicate if swap hash been filled
     */
    mapping(bytes32 => bool) private _filled;

    /**
     * @dev Mapping of swapHash => bool inicate if swap has been filled
     */
    mapping(address => mapping(bytes32 => bool)) private _cancelled;

    /**
     * @dev Event emited when swap is filled
     * @param makerAddress maker address
     * @param takerAddress takker addres
     * @param filledTimeSeconds time in seconds when swap was filled
     */
    event Fill(
        address indexed makerAddress,
        address indexed takerAddress,
        bytes32 indexed swapHash,
        uint256 filledTimeSeconds
    );

    /**
     * @dev Event emited when swap is cancelled
     * @param makerAddress maker address
     * @param takerAddress takker addres
     * @param canceledTimeSeconds time in seconds when swap was filled
     */
    event Cancel(
        address indexed makerAddress,
        address indexed takerAddress,
        bytes32 indexed swapHash,
        uint256 canceledTimeSeconds
    );

    /**
     * @dev Fills the input swap. Reverts is validations don't check
     * @param swap Swap struct containing swap specifications.
     * @param  signature Proof that swap has been created by maker.
     */
    function fillSwap(LibSwap.Swap calldata swap, bytes calldata signature) 
        external whenNotPaused nonReentrant {
        _fillSwap(swap, signature);
    }

    /**
     * @dev Cancel a swap. Is swap is cancell, it can't fill
     * @param swap Swap struct containing swap specifications.
     * @param  signature Proof that swap has been created by maker.
     */
    function cancelSwap(LibSwap.Swap calldata swap, bytes calldata signature) 
        external whenNotPaused nonReentrant {
        
        LibSwap.SwapInfo memory swapInfo = getSwapInfo(swap);
        validateCancelSwap(swap, signature, swapInfo);
        _cancelled[msg.sender][swapInfo.swapHash] = true;

        emit Cancel(
                swap.makerAddress, 
                swap.takerAddress, 
                swapInfo.swapHash, 
                swapInfo.timestamp
            );
    }

    /**
     * @dev Disable execution
     */
    function deactivate() public onlyOwner {
        _pause();
    }

    /**
     * @dev Enable execution
     */
    function activate() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Fills the input swap. Check validatios, do swap, update state and emit events
     * @param swap Swap struct containing swap specifications.
     * @param  signature Proof that swap has been created by maker.
     */
    function _fillSwap(LibSwap.Swap calldata swap, bytes calldata signature) private {
        LibSwap.SwapInfo memory swapInfo = getSwapInfo(swap);
        validateFillSwap(swap, signature, swapInfo);
        _updateFilledState(swap, swapInfo);
        _transfer(swap);
    }

    /**
     * @dev Transfer tokens betwen maker and taker
     * @param swap Swap struct containing swap specifications.
     */
    function _transfer(LibSwap.Swap calldata swap) private {

        // Transfer maker -> taker
        _dispatchTransferFrom(swap.makerTokenData, swap.makerAddress, swap.takerAddress);
        // Transfer taker -> maker
        _dispatchTransferFrom(swap.takerTokenData, swap.takerAddress, swap.makerAddress);
    }

    /**
     * @dev Call `transferFrom` for each specific token contract
     * @param tokenData Tokens to transfer
     * @param from from transfer address
     * @param to to transfer address
     */
    function _dispatchTransferFrom(LibSwap.TokenData[] calldata tokenData, address from, address to) 
        private {
        
        for (uint256 i = 0; i < tokenData.length; ++i) {
            if (tokenData[i].tokenType == LibSwap.TokenType.ERC721) {
                IERC721(tokenData[i].tokenContract).safeTransferFrom(from, to, tokenData[i].tokenId);
            }
        }
    }

    /**
     * @dev Update state and emit event
     * @param swap swap filled
     * @param swapInfo info of swap filled
     */
    function _updateFilledState(LibSwap.Swap calldata swap, LibSwap.SwapInfo memory swapInfo) private {
        _filled[swapInfo.swapHash] = true;

        emit Fill(
                swap.makerAddress, 
                swap.takerAddress, 
                swapInfo.swapHash, 
                swapInfo.timestamp
            );
    }    

    /**
     * @dev See {ValidatorSwap-getCancelled}.
     */
    function getCancelled() internal view override 
        returns (mapping(address => mapping(bytes32 => bool)) storage) {
        
        return _cancelled;
    }

    /**
     * @dev See {ValidatorSwap-getFilled}.
     */
    function getFilled() internal view override returns (mapping(bytes32 => bool) storage) {
        return _filled;
    }

    /**
     * @dev Gets information about an swap: status and hash
     * @param swap Swap to gather information on.
     * @return swapInfo Information about the swap and its state.
     *                  See LibSwap.SwapInfo for a complete description.
     */
    function getSwapInfo(LibSwap.Swap calldata swap)
        private
        view
        returns (LibSwap.SwapInfo memory swapInfo)
    {
        LibEIP712.EIP712Domain memory eip712Domain = LibEIP712.EIP712Domain(
            _EIP712_NAME,
            _EIP712_VERSION,
            block.chainid,
            address(this)
        );

        swapInfo.swapHash = swap.getHash(eip712Domain);
        swapInfo.swapStatus = LibSwap.SwapStatus.FILLABLE;
        swapInfo.timestamp = block.timestamp;
    }
}


