// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; 

import "./BridgeAdapter.sol";
import "./ERC20.sol";
import "./ERC20Permit.sol";
import "./SafeERC20.sol";
import "./NonBlockingLzApp.sol";
import "./IXERC20.sol";
import "./IXERC20Lockbox.sol";

contract LayerZeroBridgeAdapter is NonblockingLzApp, BridgeAdapter {
    using SafeERC20 for IERC20;
    
    uint256 public gasLimit;
    uint16 private lzVersion = 1;

    //Map chain ids to layerZero ids due to Lz supporting non-EVM chains
    mapping (uint256 => uint16) public chainIdToLzId;
    mapping (uint16 => uint256) public lzIdToChainId;

    /**@notice Initialize the bridge
     * @param _goa GOA token address
     * @param _xgoa xGOA token address
     * @param _lockbox xGOA lockbox address
     * @param _contracts Additional contracts needed
     */
    function initialize(
        IERC20 _goa,
        IXERC20 _xgoa, 
        IXERC20Lockbox _lockbox,
        address[] calldata _contracts
    ) public override initializer {
        __NonblockingLzAppInit(_contracts[0]);
        GOA = _goa;
        xGOA = _xgoa;
        lockbox = _lockbox;

        if (address(lockbox) != address(0)) {
            GOA.safeIncreaseAllowance(address(lockbox), type(uint).max);
            IERC20(address(xGOA)).safeIncreaseAllowance(address(lockbox), type(uint).max);
        }
    }

    /**
     * @param _user User that initiated the bridge
     * @param _dstChainId Destination chain id 
     * @param _amount Amount of GOA to bridge out
     * @param _to Address to receive funds on destination chain
     */
    function _bridge(address _user, uint256 _dstChainId, uint256 _amount, address _to) internal override {
        
        _bridgeOut(_user, _amount);

        // Send message to receiving bridge to mint tokens to user. 
        bytes memory adapterParams = abi.encodePacked(lzVersion, gasLimit);
        bytes memory payload = abi.encode(_to, _amount);
        
         _lzSend( // {value: messageFee} will be paid out of this contract!
                chainIdToLzId[_dstChainId], // destination chainId
                payload, // abi.encode()'ed bytes
                payable(_user), // refund address (LayerZero will refund any extra gas back to caller of send()
                address(0x0), // future param, unused
                adapterParams, // v1 adapterParams, specify custom destination gas qty
                msg.value
        );

        emit BridgedOut(_dstChainId, _user, _to, _amount);
    }

    /**@notice Estimate gas cost to bridge out funds
     * @param _dstChainId Destination chain id 
     * @param _amount Amount of GOA to bridge out
     * @param _to Address to receive funds on destination chain
     */
    function bridgeCost(uint256 _dstChainId, uint256 _amount, address _to) external override view returns (uint256 gasCost) {
        bytes memory adapterParams = abi.encodePacked(lzVersion, gasLimit);
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

    /**
     * @notice LayerZero endpoint will invoke this function to deliver the message on the destination
     * @dev _srcAddress and _nonce are not used in this override.
     * @param _srcChainId - the source endpoint identifier
     * @param _payload - the signed payload is the UA bytes has encoded to be sent
     */
    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory /*_srcAddress*/,  uint64 /*_nonce*/, bytes memory _payload) internal override {
        (address user, uint256 amount) = abi.decode(_payload, (address, uint256));
        _bridgeIn(lzIdToChainId[_srcChainId], user, amount);   
    }

    /**@notice Set gas limit for destination chain execution
     * @param _gasLimit Gas limit for destination chain execution
     */
    function setGasLimit(uint256 _gasLimit) external onlyOwner {
        gasLimit = _gasLimit;
    }
}