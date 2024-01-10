// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SignatureVerify.sol";
import "./Ierc20.sol";

contract UniqRequester is Ownable, SignatureVerify {
    // ----- EVENTS ----- //
    event TokensRequested(address indexed _requester, address indexed _mintAddress, uint256[] _tokenIds, uint256 _bundleId); 


    // ----- VARIABLES ----- //
    uint256 internal _transactionOffset;
    mapping(address => mapping(uint256 => bool)) internal _tokenAlreadyRequested;

    // ----- CONSTRUCTOR ----- //
    constructor() {
        _transactionOffset = 3 minutes;
    }

    // ----- MESSAGE SIGNATURE ----- //
    function getMessageHash(
        address _mintContractAddress,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _price,
        address _paymnetTokenAddress,
        uint256 _timestamp,
        address _requesterAddress
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_mintContractAddress,_bundleId,_tokenIds, _price, _paymnetTokenAddress, _timestamp, _requesterAddress)
            );
    }

    function verifySignature(
        address _mintContractAddress,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _price,
        address _paymentTokenAddress,
        bytes memory _signature,
        uint256 _timestamp
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(
            _mintContractAddress,
            _bundleId,
            _tokenIds,
            _price,
            _paymentTokenAddress,
            _timestamp,
            msg.sender
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    // ----- PUBLIC METHODS ----- //
    function requestTokens(
        address _mintContractAddress,
        uint256 _bundleId,
        uint256[] memory _tokenIds,
        uint256 _priceForPackage,
        address _paymentToken,
        bytes memory _signature,
        uint256 _timestamp
    ) external payable {
        require(_timestamp + _transactionOffset >= block.timestamp, "Transaction timed out");
        require(
            verifySignature(
                _mintContractAddress, 
                _bundleId,
                _tokenIds,
                _priceForPackage,
                _paymentToken,
                _signature,
                _timestamp
            ),
            "Signature mismatch"
        );
        for(uint256 i=0; i<_tokenIds.length; i++){
            require(!_tokenAlreadyRequested[_mintContractAddress][_tokenIds[i]], "Token already requested in this network");
            _tokenAlreadyRequested[_mintContractAddress][_tokenIds[i]] = true;
        }
        if (_priceForPackage != 0) {
            if (_paymentToken == address(0)) {
                require(msg.value >= _priceForPackage, "Not enough ether");
                if (_priceForPackage < msg.value) {
                    payable(msg.sender).transfer(msg.value - _priceForPackage);
                }
            } else {
                require(
                    IERC20(_paymentToken).transferFrom(
                        msg.sender,
                        address(this),
                        _priceForPackage
                    )
                );
            }
        }
        emit TokensRequested(msg.sender, _mintContractAddress, _tokenIds, _bundleId);
    }

    receive() external payable {}

    // ----- OWNERS METHODS ----- //

    function withdrawTokens(address token) external onlyOwner {
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val > 0, "Nothing to recover");
        // use interface that not return value (USDT case)
        Ierc20(token).transfer(owner(), val);
    }

    function setTransactionOffset(uint256 _newOffset) external onlyOwner{
        _transactionOffset = _newOffset;
    }

    function withdrawETH() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
