// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SignatureVerify.sol";

contract UniqStoreHelper is Ownable, SignatureVerify {
    // ----- VARIABLES ----- //
    address internal _storeAddress;
    uint256 internal _transactionOffset;

    // ----- CONSTRUCTOR ----- //
    constructor(address _storeContractAddress) {
        _storeAddress = _storeContractAddress;
        _transactionOffset = 2 hours;
    }

    // ----- VIEWS ----- //
    function getStoreAddress() external view returns (address) {
        return _storeAddress;
    }

    // ----- MESSAGE SIGNATURE ----- //
    /// @dev not test for functions related to signature
    function getMessageHash(
        uint256[] memory _tokenIds,
        uint256 _price,
        address _paymnetTokenAddress,
        uint256 _timestamp
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_tokenIds, _price, _paymnetTokenAddress, _timestamp)
            );
    }

    /// @dev not test for functions related to signature
    function verifySignature(
        uint256[] memory _tokenIds,
        uint256 _price,
        address _paymentTokenAddress,
        bytes memory _signature,
        uint256 _timestamp
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(
            _tokenIds,
            _price,
            _paymentTokenAddress,
            _timestamp
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    // ----- PUBLIC METHODS ----- //

    function buyToken(
        uint256[] memory _tokenIds,
        uint256 _price,
        address _paymentToken,
        address _receiver,
        bytes memory _signature,
        uint256 _timestamp
    ) external payable {
        require(_tokenIds.length == 1, "More than one token");
        require(_timestamp + _transactionOffset >= block.timestamp, "Transaction timed out");
        require(
            verifySignature(_tokenIds, _price, _paymentToken, _signature, _timestamp),
            "Signature mismatch"
        );
        if (_price != 0) {
            if (_paymentToken == address(0)) {
                require(msg.value >= _price, "Not enough ether");
                if (_price < msg.value) {
                    payable(msg.sender).transfer(msg.value - _price);
                }
            } else {
                require(
                    IERC20(_paymentToken).transferFrom(
                        msg.sender,
                        address(this),
                        _price
                    )
                );
            }
        }
        address[] memory receivers = new address[](1);
        receivers[0] = _receiver;
        IUniqCollections(_storeAddress).batchMintSelectedIds(
            _tokenIds,
            receivers
        );
    }

    function buyTokens(
        uint256[] memory _tokenIds,
        uint256 _priceForPackage,
        address _paymentToken,
        address _receiver,
        bytes memory _signature,
        uint256 _timestamp
    ) external payable {
        require(_timestamp + _transactionOffset >= block.timestamp, "Transaction timed out");
        require(
            verifySignature(
                _tokenIds,
                _priceForPackage,
                _paymentToken,
                _signature,
                _timestamp
            ),
            "Signature mismatch"
        );
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
        address[] memory _receivers = new address[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _receivers[i] = _receiver;
        }
        IUniqCollections(_storeAddress).batchMintSelectedIds(
            _tokenIds,
            _receivers
        );
    }

    // ----- PROXY METHODS ----- //

    function pEditClaimingAddress(address _newAddress) external onlyOwner {
        IUniqCollections(_storeAddress).editClaimingAdress(_newAddress);
    }

    function pEditRoyaltyFee(uint256 _newFee) external onlyOwner {
        IUniqCollections(_storeAddress).editRoyaltyFee(_newFee);
    }

    function pEditTokenUri(string memory _ttokenUri) external onlyOwner {
        IUniqCollections(_storeAddress).editTokenUri(_ttokenUri);
    }

    function pRecoverERC20(address token) external onlyOwner {
        IUniqCollections(_storeAddress).recoverERC20(token);
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val > 0, "Nothing to recover");
        Ierc20(token).transfer(owner(), val);
    }

    function pTransferOwnership(address newOwner) external onlyOwner {
        IUniqCollections(_storeAddress).transferOwnership(newOwner);
    }

    function pBatchMintSelectedIds(
        uint256[] memory _ids,
        address[] memory _addresses
    ) external onlyOwner {
        IUniqCollections(_storeAddress).batchMintSelectedIds(_ids, _addresses);
    }

    function pMintNextToken(address _receiver) external onlyOwner{
        IUniqCollections(_storeAddress).mintNextToken(_receiver);
    }

    // ----- OWNERS METHODS ----- //

    function editStoreAddress(address _newStoreAddress) external onlyOwner {
        _storeAddress = _newStoreAddress;
    }

    function withdrawTokens(address token) external onlyOwner {
        uint256 val = IERC20(token).balanceOf(address(this));
        require(val > 0, "Nothing to recover");
        // use interface that not return value (USDT case)
        Ierc20(token).transfer(owner(), val);
    }

    function setTransactionOffset(uint256 _newOffset) external onlyOwner{
        _transactionOffset = _newOffset;
    }

    receive() external payable {}

    function withdrawETH() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}

interface IUniqCollections {
    function editClaimingAdress(address _newAddress) external;

    function editRoyaltyFee(uint256 _newFee) external;

    function batchMintSelectedIds(
        uint256[] memory _ids,
        address[] memory _addresses
    ) external;

    function editTokenUri(string memory _ttokenUri) external;

    function recoverERC20(address token) external;

    function transferOwnership(address newOwner) external;

    function mintNextToken(address _receiver) external;
}

interface Ierc20 {
    function transfer(address, uint256) external;
}
