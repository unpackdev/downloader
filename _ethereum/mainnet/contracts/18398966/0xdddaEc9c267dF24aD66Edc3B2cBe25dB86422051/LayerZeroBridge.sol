// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19; 

import "./BeefyBridgeAdapter.sol";
import "./ERC20.sol";
import "./ERC20Permit.sol";
import {SafeERC20} from  "@openzeppelin-4/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IXERC20.sol";
import "./IXERC20Lockbox.sol";
import  {NonblockingLzApp} from "./NonblockingLzApp.sol";

// Lazyer Zero Token Bridge adapter for XERC20 tokens
contract LayerZeroBridge is NonblockingLzApp, BeefyBridgeAdapter {
    using SafeERC20 for IERC20;

    // Bridge params
    uint16 private version = 1;
    uint256 public gasLimit;

    // Chain id mappings
    mapping (uint256 => uint16) public chainIdToLzId;
    mapping (uint16 => uint256) public lzIdToChainId;

    /**@notice Initialize the bridge
     * @param _bifi BIFI token address
     * @param _xbifi xBIFI token address
     * @param _lockbox xBIFI lockbox address
     * @param _contracts additional contracts needed
     */
    function initialize(
        IERC20 _bifi,
        IXERC20 _xbifi, 
        IXERC20Lockbox _lockbox,
        address[] calldata _contracts
    ) public override initializer {
        __NonblockingLzAppInit(_contracts[0]);
        BIFI = _bifi;
        xBIFI = _xbifi;
        lockbox = _lockbox;

        if (address(lockbox) != address(0)) {
            BIFI.safeApprove(address(lockbox), type(uint).max);
            IERC20(address(xBIFI)).safeApprove(address(lockbox), type(uint).max);
        }
    }

    function _bridge(address _user, uint256 _dstChainId, uint256 _amount, address _to) internal override {
        _bridgeOut(_user, _amount);

        // Send message to receiving bridge to mint tokens to user. 
        bytes memory adapterParams = abi.encodePacked(version, gasLimit);
        bytes memory payload = abi.encode(_to, _amount);
        
         _lzSend( // {value: messageFee} will be paid out of this contract!
                chainIdToLzId[_dstChainId], // destination chainId
                payload, // abi.encode()'ed bytes
                payable(_user), // refund address (LayerZero will refund any extra gas back to caller of send()
                address(0x0), // future param, unused for this example
                adapterParams, // v1 adapterParams, specify custom destination gas qty
                msg.value
        );

        emit BridgedOut(_dstChainId, _user, _to, _amount);
    }

    /**@notice Estimate gas cost to bridge out funds
     * @param _dstChainId Destination chain id 
     * @param _amount Amount of BIFI to bridge out
     * @param _to Address to receive funds on destination chain
     */
    function bridgeCost(uint256 _dstChainId, uint256 _amount, address _to) external override view returns (uint256 gasCost) {
        bytes memory adapterParams = abi.encodePacked(version, gasLimit);
        bytes memory payload = abi.encode(_to, _amount);
        
        (gasCost,) = lzEndpoint.estimateFees(
            chainIdToLzId[_dstChainId],
            address(this),
            payload,
            false,
            adapterParams
        );
    }

    /**@notice Add chain ids to the bridge
     * @param _chainIds Chain ids to add
     * @param _lzIds LayerZero ids to add
     */
    function addChainIds(uint256[] calldata _chainIds, uint16[] calldata _lzIds) external onlyOwner {
        for (uint i; i < _chainIds.length; ++i) {
            chainIdToLzId[_chainIds[i]] = _lzIds[i];
            lzIdToChainId[_lzIds[i]] = _chainIds[i];
        }
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory /* _srcAddress */, 
        uint64, /*_nonce*/
        bytes memory _payload
    ) internal override {
        (address user, uint256 amount) = abi.decode(_payload, (address,uint256));
        
        _bridgeIn(lzIdToChainId[_srcChainId], user, amount);   
    }

    /**@notice Set gas limit for destination chain execution
     * @param _gasLimit Gas limit for destination chain execution
     */
    function setGasLimit(uint256 _gasLimit) external onlyOwner {
        gasLimit = _gasLimit;
    }
}