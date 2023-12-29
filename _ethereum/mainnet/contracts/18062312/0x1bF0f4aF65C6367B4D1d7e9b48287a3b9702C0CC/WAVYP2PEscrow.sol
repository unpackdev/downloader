// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract WAVYP2PEscrow is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct allowedTokens {
        bool isAllowed;
        string tokenName;
        IERC20 tokenAddress;
        uint decimals;
    }

    allowedTokens[] public allowedTokensList;
    mapping(IERC20 => bool) public isAllowed;

    struct Offer {
        uint sendTokenId;
        uint256 sendAmount;
        uint receiveTokenId;
        uint256 receiveAmount;
        uint256 minReceiveAmount;
        address listerAddress;
        uint256 status; // 0 - active, 1 - completed, 2 - revoked
    }

    Offer[] public offerDetails;
    uint256 feeInBips = 25; 
    address feeWallet = 0xFD182B1f0C71558dAE29CbFfBdb84D3Ef8643779;

    event tokenAdded(uint tokenId, string tokenName, IERC20 tokenAddress, uint decimals);
    event OfferCreated(uint256 indexed offerId, address indexed createdBy, uint sendTokenId, uint256 sendAmount, uint receiveTokenId, uint256 receiveAmount, uint256 minReceiveAmount);
    event offerUpdated(uint256 offerId, uint256 receiveAmount, uint256 minReceiveAmount);
    event offerRevoked(uint256 offerId);
    event offerAccepted(uint256 offerId, uint256 amount);
    event offerCompleted(uint256 offerId);

    function addToAllowList(string memory _tokenName, IERC20 _tokenAddress, uint _decimals) external onlyOwner {
        allowedTokensList.push(allowedTokens(true, _tokenName, _tokenAddress, _decimals));
        isAllowed[_tokenAddress] = true;
        emit tokenAdded(allowedTokensList.length - 1, _tokenName, _tokenAddress, _decimals);
    }

    function removeFromAllowList(uint _tokenId) external onlyOwner {
        require(isAllowed[allowedTokensList[_tokenId].tokenAddress], "Not valid token Id or token already disabled");
        isAllowed[allowedTokensList[_tokenId].tokenAddress] = false;
    }

    function makeOffer(uint _sendTokenId, uint256 _sendAmount, uint _receiveTokenId, uint256 _receiveAmount, uint256 _minReceiveAmount) external {
        require(isAllowed[allowedTokensList[_sendTokenId].tokenAddress], "Token being sold is not allowed");
        require(isAllowed[allowedTokensList[_receiveTokenId].tokenAddress], "Token to be received is not allowed"); 
        require(_minReceiveAmount <= _receiveAmount, "Minimum receivable amount cannot be greater than the receive amount");

        IERC20 _token = allowedTokensList[_sendTokenId].tokenAddress;
        uint256 fee = calculateFee(_sendAmount);
        uint256 transferAmount = _sendAmount + fee;

        require(_token.balanceOf(msg.sender) >= transferAmount, "Insufficient balance");
        require(_token.allowance(msg.sender, address(this)) >= transferAmount, "Insufficient allowance");

        _token.safeTransferFrom(msg.sender, address(this), _sendAmount);
        _token.safeTransferFrom(msg.sender, feeWallet, fee);
        offerDetails.push(Offer(_sendTokenId, _sendAmount, _receiveTokenId, _receiveAmount, _minReceiveAmount, msg.sender, 0));

        emit OfferCreated(offerDetails.length - 1, msg.sender, _sendTokenId, _sendAmount, _receiveTokenId, _receiveAmount, _minReceiveAmount);
    }

    function calculateFee(uint256 _amount) private view returns (uint256) {
        return _amount * feeInBips / 10000;
    }

    function acceptOffer(uint256 _offerId, uint256 _amount) external nonReentrant {
        Offer storage _offer = offerDetails[_offerId];
        require(_offer.status == 0, "Offer not available");
        require(_offer.receiveAmount >= _amount, "Amount is greater than what listing expects");
        require(_amount >= _offer.minReceiveAmount, "Amount should be more than minimum Receivable amount");

        IERC20 _sendToken = allowedTokensList[_offer.sendTokenId].tokenAddress;
        IERC20 _receiveToken = allowedTokensList[_offer.receiveTokenId].tokenAddress;

        uint256 fee = calculateFee(_amount);

        require(_receiveToken.balanceOf(msg.sender) >= _amount + fee, "Insufficient balance");
        require(_receiveToken.allowance(msg.sender, address(this)) >= _amount + fee, "Insufficient allowance");

        uint256 proportionalSendAmount =  _offer.sendAmount * _amount / _offer.receiveAmount;
        _offer.sendAmount -= proportionalSendAmount;
        _offer.receiveAmount -= _amount;

        _receiveToken.safeTransferFrom(msg.sender, feeWallet, fee);
        _receiveToken.safeTransferFrom(msg.sender, _offer.listerAddress, _amount);
        _sendToken.safeTransfer(msg.sender, proportionalSendAmount);

        emit offerAccepted(_offerId, _amount);

        if(_offer.receiveAmount == 0) {
            _offer.status = 1;
            emit offerCompleted(_offerId);
        } else if(_offer.receiveAmount < _offer.minReceiveAmount) {
            _offer.minReceiveAmount = _offer.receiveAmount;
        }
    }

    function cancelOffer(uint256 _offerId) external nonReentrant {
        Offer storage _offer = offerDetails[_offerId];
        require(_offer.status == 0, "Offer not available");
        require(_offer.listerAddress == msg.sender, "Caller has not created the offer");
        IERC20 _sendToken = allowedTokensList[_offer.sendTokenId].tokenAddress;
        _sendToken.safeTransfer(_offer.listerAddress, _offer.sendAmount);
        _offer.status = 2;

        emit offerRevoked(_offerId);
    }

    function updateOffer(uint256 _offerId, uint256 _receiveAmount, uint256 _minReceiveAmount) external {
        Offer storage _offer = offerDetails[_offerId];
        require(_offer.status == 0, "Offer not available");
        require(_offer.listerAddress == msg.sender, "Caller has not created the offer");
        require(_minReceiveAmount <= _receiveAmount, "Minimum receivable amount cannot be greater than the receive amount");

        _offer.minReceiveAmount = _minReceiveAmount;
        _offer.receiveAmount = _receiveAmount;
        emit offerUpdated(_offerId, _receiveAmount, _minReceiveAmount);
    }

    function setFeeDetails(uint256 _fee, address _feeWallet) external onlyOwner {
        feeInBips = _fee;
        feeWallet = _feeWallet;
    }

    function withdrawFee() external onlyOwner {
        for (uint i=0; i< allowedTokensList.length; i++) {
            uint256 balance = allowedTokensList[i].tokenAddress.balanceOf(address(this));
            if(balance > 0) {
                allowedTokensList[i].tokenAddress.transferFrom(address(this), feeWallet, balance);
            }
        }
    }
}