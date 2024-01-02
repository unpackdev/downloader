// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./EthConnectorStorage.sol";
import "./IEthConnectorLogic.sol";

contract EthConnectorLogic is IEthConnectorLogic, EthConnectorStorage, 
    OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "EthConnectorLogic: zero address");
        _;
    }

    function initialize(
        address _across,
        address _wrappedNativeToken,
        uint _sourceChainId,
        uint _targetChainId
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        PausableUpgradeable.__Pausable_init();

        across = _across;
        wrappedNativeToken = _wrappedNativeToken;
        sourceChainId = _sourceChainId;
        targetChainId = _targetChainId;
        minModifier = ONE_HUNDRED_PERCENT;
    }

    /// @notice Setter for min bidding amount
    /// @dev Bidding below the min amount is not possible since cancelling or 
    ///      withdrawing such a bid becomes impossible (due to Across bridge fee)
    function setMinAmount(address _token, uint _minAmount) external override onlyOwner {
        minAmounts[_token] = _minAmount;
    }

    /// @notice Setter for min amount modifier
    /// @dev In the case of network fee changes, instead of 
    ///      updating min amount for all tokens, we only update this modifier
    function setMinModifier(uint _minModifier) external override onlyOwner {
        minModifier = _minModifier;
    }

    /// @notice Setter for Polygon connector
    function setPolyConnector(address _polyConnector) external override onlyOwner {
        polyConnector = _polyConnector;
    }

    /// @notice Setter for Across
    function setAcross(address _across) external override onlyOwner {
        across = _across;
    }

    /// @notice Withdraws tokens in the emergency case
    /// @dev Only owner can call this
    function withdrawToken(
        address _token,
        address _to,
        uint _amount
    ) external override onlyOwner {
        if (_token == ETH_ADDR) 
            _to.call{value: _amount}("");
        else
            IERC20(_token).transfer(_to, _amount);
    }

    /// @notice Same as putBid, but using Across bridge
    /// @param _relayerFeePercentage This fee is taken by Across relayers for processing the request
   function putBidAcross(
        TeleOrdinalLib.Loc calldata _loc,
        bytes memory _buyerBTCScript,
        ScriptTypes _scriptType,
        uint _amount,
        address _token,
        int64 _relayerFeePercentage
    ) external override payable {

        _checkBid(_amount, _token);

        // Sends msg to Polygon
        bytes memory message = abi.encode(
            false,
            sourceChainId,
            msg.sender, 
            _loc.txId, 
            _loc.outputIdx, 
            _loc.satoshiIdx, 
            _buyerBTCScript,
            _scriptType,
            msgIndx
        );
        emit MsgSent(
            "putBidAcross",
            abi.encode(message, _amount, _token)
        );

        _sendMsgUsingAcross(
            _token,
            _amount,
            message,
            _relayerFeePercentage
        );
    }

    /// @notice Same as increaseBid, but using Across bridge
    /// @param _relayerFeePercentage This fee is taken by Across relayers for processing the request
    function increaseBidAcross(
        TeleOrdinalLib.Loc calldata _loc,
        uint _bidIdx,
        uint _addedAmount,
        address _token,
        int64 _relayerFeePercentage
    ) external override payable {

        // Checks that token is supported
        require(
            minAmounts[_token] > 0,
            "EthConnectorLogic: token not supported"
        );
        
        // Sends message to Polygon
        bytes memory message = abi.encode(
            true,
            sourceChainId,
            msg.sender, 
            _loc.txId, 
            _loc.outputIdx, 
            _loc.satoshiIdx,  
            _bidIdx,
            msgIndx
        );
        emit MsgSent(
            "increaseBidAcross",
            abi.encode(message, _addedAmount, _token)
        );

        _sendMsgUsingAcross(
            _token,
            _addedAmount,
            message,
            _relayerFeePercentage
        );
    }

    /// @notice Sends tokens and message using Across bridge
    function _sendMsgUsingAcross(
        address _token,
        uint _amount,
        bytes memory _message,
        int64 _relayerFeePercentage
    ) internal {

        if (_token == ETH_ADDR) {
            require(msg.value == _amount, "EthConnectorLogic: wrong value");
            _token = wrappedNativeToken;
        } else {
            // Prevents sending ETH
            require(msg.value == 0, "EthConnectorLogic: wrong value");

            // Transfers tokens from user to contract
            IERC20(_token).transferFrom(
                msg.sender,
                address(this),
                _amount
            );

            IERC20(_token).approve(
                across, 
                _amount
            );
        }

        // Calling across for transferring token and msg
        Address.functionCallWithValue(
            across,
            abi.encodeWithSignature(
                "deposit(address,address,uint256,uint256,int64,uint32,bytes,uint256)",
                polyConnector,
                _token,
                _amount,
                targetChainId,
                _relayerFeePercentage,
                uint32(block.timestamp),
                _message,
                115792089237316195423570985008687907853269984665640564039457584007913129639935
            ),
            msg.value
        );

        msgIndx++;  
    }

    /// @notice Checks if bidding is possible
    /// @dev Bidding amount should be >= min and token should be acceptable
    function _checkBid(uint _amount, address _token) internal view {
        // Checks that amount is greater than min
        // Note: if the amount is lower than min, 
        //       it may become impossible to cancel or withdraw funds in future
        require(
            minAmounts[_token] > 0,
            "EthConnectorLogic: token not supported"
        );
        require(
            _amount >= (minAmounts[_token] * minModifier / ONE_HUNDRED_PERCENT),
            "EthConnectorLogic: low amount"
        );
    }

}