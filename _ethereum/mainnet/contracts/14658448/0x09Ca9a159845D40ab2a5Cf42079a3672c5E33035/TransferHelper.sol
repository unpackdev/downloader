// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.7.6;

import "Pausable.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "EnumerableSet.sol";

import "Ownable.sol";

contract TransferHelper is TransferOwnable, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    string public constant NAME = "Transfer Helper";
    string public constant VERSION = "0.1.0";

    EnumerableSet.AddressSet senderSet;
    mapping(address => EnumerableSet.AddressSet) senderToTokens;
    mapping(address => mapping(address => EnumerableSet.AddressSet)) tokenToReceivers;

    event tokenReceiverAdded(
        address indexed sender,
        address indexed token,
        address indexed receiver
    );
    event tokenReceiverRemoved(
        address indexed sender,
        address indexed token,
        address indexed receiver
    );

    function execTransfer(
        address _token,
        address _receiver,
        uint256 _amount
    ) external whenNotPaused {
        address _sender = _msgSender();
        require(senderToTokens[_sender].contains(_token), "Not allowed token");
        require(
            tokenToReceivers[_sender][_token].contains(_receiver),
            "Not allowed address"
        );

        IERC20(_token).safeTransferFrom(_sender, _receiver, _amount);
    }

    function addTokenReceiver(address _token, address _receiver)
        external
        whenNotPaused
    {
        address _sender = _msgSender();

        senderSet.add(_sender);
        senderToTokens[_sender].add(_token);
        tokenToReceivers[_sender][_token].add(_receiver);
        emit tokenReceiverAdded(_sender, _token, _receiver);
    }

    function removeTokenReceiver(address _token, address _receiver)
        external
        whenNotPaused
    {
        address _sender = _msgSender();

        tokenToReceivers[_sender][_token].remove(_receiver);
        if (tokenToReceivers[_sender][_token].length() == 0) {
            senderToTokens[_sender].remove(_token);
        }
        if (senderToTokens[_sender].length() == 0) {
            senderSet.remove(_sender);
        }
        emit tokenReceiverRemoved(_sender, _token, _receiver);
    }

    function getAllSenders() public view returns (address[] memory) {
        bytes32[] memory store = senderSet._inner._values;
        address[] memory result;
        assembly {
            result := store
        }
        return result;
    }

    function getAllowedTokensBySender(address _sender)
        public
        view
        returns (address[] memory)
    {
        bytes32[] memory store = senderToTokens[_sender]._inner._values;
        address[] memory result;
        assembly {
            result := store
        }
        return result;
    }

    function getAllowedReceiversByToken(address _sender, address _token)
        public
        view
        returns (address[] memory)
    {
        bytes32[] memory store = tokenToReceivers[_sender][_token]
            ._inner
            ._values;
        address[] memory result;
        assembly {
            result := store
        }
        return result;
    }

    function setPaused(bool paused) external onlyOwner {
        if (paused) _pause();
        else _unpause();
    }
}
