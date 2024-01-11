// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Upgradeable.sol";

contract Bridge is Upgradeable {
    using SignatureUtils for TransferData;

    constructor(address _proxy) Upgradeable(_proxy) {}

    /**
     * @dev To approve or revoke a token from acceptance list
     * @param _tokenAddress the token address
     * @param _value true/false
     */
    function setTokenApproval(address _tokenAddress, bool _value)
        public
        onlyOwner
    {
        isApprovedToken[_tokenAddress] = _value;
    }

    /**
     * @dev To approve or revoke a signer from list
     * @param _newSigner the address of new signer
     */
    function setSigner(address _newSigner) public onlyOwner {
        require(_newSigner != address(0), "Bridge: signer is zero address");
        require(
            _newSigner != signer,
            "Bridge: cannot transfer to current signer"
        );
        signer = _newSigner;
        emit SetSignerEvent(_newSigner);
    }

    /**
     * @dev To add or remove an account from blacklist
     * @param _account the address of account
     * @param _value true/false
     */
    function setBlacklist(address _account, bool _value) public onlyOwner {
        require(_account != address(0), "Bridge: receive zero address");
        blacklist[_account] = _value;
    }

    /**
     * @dev To check an account blacklisted or not
     * @param _account the account to check
     */
    function isBlacklisted(address _account) public view returns (bool) {
        return blacklist[_account];
    }

    /**
     * @dev Call when the user swap from chain A to chain B
     * @notice The user will burn the token, then it will return the other token on other chain

     * @param _addr (0) fromToken, (1) toToken, (2) fromAddress, (3) toAddress
     * @param _data (0) amount
     * @param _internalTxId the transaction id
     */
    function burnToken(
        address[] memory _addr,
        uint256[] memory _data,
        string memory _internalTxId
    ) public notBlacklisted nonReentrant {
        TransferData memory transferData = TransferData(
            _addr[0],
            _addr[1],
            _addr[2],
            _addr[3],
            _data[0],
            _internalTxId
        );

        _execute(transferData, 0, "", address(0));
    }

    /**
     * @dev Call when the user claim on chain B when swapping from chain A to chain B
     * @param _addr (0) fromToken, (1) toToken, (2) fromAddress, (3) toAddress, (4) signer
     * @param _data (0) amount
     * @param _internalTxId the transaction id
     * @param _signature the transaction's signature created by the signer
     */
    function mintToken(
        address[] memory _addr,
        uint256[] memory _data,
        string memory _internalTxId,
        bytes memory _signature
    ) public notBlacklisted nonReentrant {
        TransferData memory transferData = TransferData(
            _addr[0],
            _addr[1],
            _addr[2],
            _addr[3],
            _data[0],
            _internalTxId
        );

        _execute(transferData, 1, _signature, _addr[4]);
    }

    /**
     * @dev Internal function to execute the lock/unlock request
     * @param _transferData the transfer data
     * @param _type 0: lock , 1: unlock
     * @param _signature the transaction's signature created by the signer
     */
    function _execute(
        TransferData memory _transferData,
        uint8 _type,
        bytes memory _signature,
        address _signer
    ) internal {
        {
            require(
                _transferData.amount > 0,
                "Diamond Alpha Bridge: Amount must be greater than 0"
            );
            require(
                _transferData.toAddress != address(0),
                "Diamond Alpha Bridge: To address is zero address"
            );
            require(
                _transferData.fromAddress != address(0),
                "Diamond Alpha Bridge: From address is zero address"
            );
            require(
                _transferData.fromToken != address(0),
                "Diamond Alpha Bridge: Token address is zero address"
            );
            require(
                _transferData.toToken != address(0),
                "Diamond Alpha Bridge: Token address is zero address"
            );
        }

        if (_type == 0) {
            // 0: Lock --> Burn, 1: Unlock --> Mint
            require(
                msg.sender == _transferData.fromAddress,
                "Diamond Alpha Bridge: Cannot lock token"
            );

            require(
                isApprovedToken[_transferData.fromToken],
                "Diamond Alpha Bridge: Token is not supported"
            );

            IERC20(_transferData.fromToken).burnFrom(
                _transferData.fromAddress,
                _transferData.amount
            );
        } else {
            require(
                _transferData.toAddress == msg.sender,
                "Diamond Alpha Bridge: You are not recipient"
            );

            require(_signer == signer, "Diamond Alpha Bridge: Only signer");

            require(
                isApprovedToken[_transferData.toToken],
                "Diamond Alpha Bridge: Token is not supported"
            );

            require(
                _transferData.verify(_signature, _signer),
                "Diamond Alpha Bridge: Verify transfer data failed"
            );

            require(
                !isExecutedTransaction[_signature],
                "Diamond Alpha Bridge: Transfer data has been processed before"
            );

            IERC20(_transferData.toToken).mint(
                _transferData.toAddress,
                _transferData.amount
            );

            isExecutedTransaction[_signature] = true;
        }

        emit MintOrBurnEvent(
            _transferData.internalTxId,
            _transferData.toAddress,
            _transferData.fromAddress,
            _transferData.fromToken,
            _transferData.toToken,
            _transferData.amount,
            _type
        );
    }
}
