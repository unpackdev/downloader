// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./SignatureVerify.sol";

contract UniqRedeem is Ownable, SignatureVerify {
    /// ----- VARIABLES ----- ///
    uint256 internal _transactionOffset;

    /// @dev Returns true if token was redeemed
    mapping(address => mapping(uint256 => mapping(uint256 => bool)))
        internal _isTokenRedeemedForPurpose;

    /// ----- EVENTS ----- ///
    event Redeemed(
        address indexed _contractAddress,
        uint256 indexed _tokenId,
        address indexed _redeemerAddress,
        string _redeemerName,
        uint256[] _purposes
    );

    /// ----- VIEWS ----- ///
    /// @notice Returns true if token claimed
    function isTokenRedeemedForPurpose(
        address _address,
        uint256 _tokenId,
        uint256 _purpose
    ) external view returns (bool) {
        return _isTokenRedeemedForPurpose[_address][_tokenId][_purpose];
    }

    // ----- MESSAGE SIGNATURE ----- //
    function getMessageHash(
        address[] memory _tokenContracts,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        uint256 _price,
        address _paymentTokenAddress,
        uint256 _timestamp
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _tokenContracts,
                    _tokenIds,
                    _purposes,
                    _price,
                    _paymentTokenAddress,
                    _timestamp
                )
            );
    }

    function verifySignature(
        address[] memory _tokenContracts,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        uint256 _price,
        address _paymentTokenAddress,
        bytes memory _signature,
        uint256 _timestamp
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(
            _tokenContracts,
            _tokenIds,
            _purposes,
            _price,
            _paymentTokenAddress,
            _timestamp
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    /// ----- PUBLIC METHODS ----- ///
    function redeemManyTokens(
        address[] memory _tokenContracts,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        string memory _redeemerName,
        uint256 _price,
        address _paymentTokenAddress,
        bytes memory _signature,
        uint256 _timestamp
    ) external payable {
        require(
            _tokenContracts.length == _tokenIds.length &&
                _tokenIds.length == _purposes.length,
            "Array length mismatch"
        );
        require(_timestamp + _transactionOffset >= block.timestamp, "Transaction timed out");
        require(
            verifySignature(
                _tokenContracts,
                _tokenIds,
                _purposes,
                _price,
                _paymentTokenAddress,
                _signature,
                _timestamp
            ),
            "Signature mismatch"
        );
        uint256 len = _tokenContracts.length;
        for (uint256 i = 0; i < len; i++) {
            require(
                !_isTokenRedeemedForPurpose[_tokenContracts[i]][_tokenIds[i]][
                    _purposes[i]
                ],
                "Can't be redeemed again"
            );
            IERC721 token = IERC721(_tokenContracts[i]);
            require(
                token.ownerOf(_tokenIds[i]) == msg.sender,
                "Redeemee needs to own this token"
            );
            _isTokenRedeemedForPurpose[_tokenContracts[i]][_tokenIds[i]][
                _purposes[i]
            ] = true;
            uint256[] memory purpose = new uint256[](1);
            purpose[0] = _purposes[i];
            emit Redeemed(
                _tokenContracts[i],
                _tokenIds[0],
                msg.sender,
                _redeemerName,
                purpose
            );
        }
        if (_price != 0) {
            if (_paymentTokenAddress == address(0)) {
                require(msg.value >= _price, "Not enough ether");
                if (_price < msg.value) {
                    payable(msg.sender).transfer(msg.value - _price);
                }
            } else {
                require(
                    IERC20(_paymentTokenAddress).transferFrom(
                        msg.sender,
                        address(this),
                        _price
                    )
                );
            }
        }
    }

    function redeemTokenForPurposes(
        address _tokenContract,
        uint256 _tokenId,
        uint256[] memory _purposes,
        string memory _redeemerName,
        uint256 _price,
        address _paymentTokenAddress,
        bytes memory _signature,
        uint256 _timestamp
    ) external payable {
        uint256 len = _purposes.length;
        require(_timestamp + _transactionOffset >= block.timestamp, "Transaction timed out");
        address[] memory _tokenContracts = new address[](len);
        uint256[] memory _tokenIds = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            _tokenContracts[i] = _tokenContract;
            _tokenIds[i] = _tokenId;
            require(
                !_isTokenRedeemedForPurpose[_tokenContract][_tokenId][
                    _purposes[i]
                ],
                "Can't be claimed again"
            );
            IERC721 token = IERC721(_tokenContract);
            require(
                token.ownerOf(_tokenId) == msg.sender,
                "Claimer needs to own this token"
            );
            _isTokenRedeemedForPurpose[_tokenContract][_tokenId][
                _purposes[i]
            ] = true;
        }
        require(
            verifySignature(
                _tokenContracts,
                _tokenIds,
                _purposes,
                _price,
                _paymentTokenAddress,
                _signature,
                _timestamp
            ),
            "Signature mismatch"
        );
        if (_price != 0) {
            if (_paymentTokenAddress == address(0)) {
                require(msg.value >= _price, "Not enough ether");
                if (_price < msg.value) {
                    payable(msg.sender).transfer(msg.value - _price);
                }
            } else {
                require(
                    IERC20(_paymentTokenAddress).transferFrom(
                        msg.sender,
                        address(this),
                        _price
                    )
                );
            }
        }
        emit Redeemed(
            _tokenContract,
            _tokenId,
            msg.sender,
            _redeemerName,
            _purposes
        );
    }

    /// ----- OWNER METHODS ----- ///
    constructor() {
        _transactionOffset = 2 hours;
    }

    function setTransactionOffset(uint256 _newOffset) external onlyOwner{
        _transactionOffset = _newOffset;
    }


    function setStatusesForTokens(address[] memory _tokenAddresses, uint256[] memory _tokenIds, uint256[] memory _purposes, bool[] memory isRedeemed) external onlyOwner{
        uint256 len = _tokenAddresses.length;
        require(len == _tokenIds.length && len == _purposes.length && len == isRedeemed.length, "Arrays lengths mismatch");
        for(uint i = 0; i < len; i++){
            _isTokenRedeemedForPurpose[_tokenAddresses[i]][_tokenIds[i]][_purposes[i]] = isRedeemed[i];
        }
    }

    /// @notice Withdraw/rescue erc20 tokens to owners address
    function withdrawERC20(address _address) external onlyOwner {
        uint256 val = IERC20(_address).balanceOf(address(this));
        Ierc20(_address).transfer(msg.sender, val);
    }

    function withdrawETH() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /// ----- PRIVATE METHODS ----- ///

    receive() external payable {}
}

interface Ierc20 {
    function transfer(address, uint256) external;
}
