// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./IERC20.sol";

contract GiftRequester is Ownable{
    //mapping giftNumer for giftType for receiver address
    //where 0 - boxes, 1 - christmast chest, 2 - genesis chest

    mapping(address => mapping(uint256 => uint256)) internal giftNumber; 

    event GiftRequested(address indexed _requester, uint256 indexed _giftNumber, uint256 indexed _giftType ,uint256 _chainId, address _nftAddress, uint256 _tokenId);

    function giftRequestedFor(address _requester) external view returns(uint256, uint256, uint256){
        return (giftNumber[_requester][0],giftNumber[_requester][1],giftNumber[_requester][2]);
    }

    function giftRequest(uint256 _number, address _paymentToken, uint256 _amount, uint256 _chainId, address _nftAddress, uint256 _tokenId, uint256 _giftType, bytes memory _signature) external{
        require(
            verifySignature(msg.sender, _number, _paymentToken, _amount, _chainId, _nftAddress, _tokenId, _giftType, _signature),
            "Signature mismatch"
        );
        require(_number>0,"Gift id can't be zero");
        require(giftNumber[msg.sender][_giftType]==0, "The gift has been delivered, hasn't it?");
        if(_amount>0){
            IERC20(_paymentToken).transferFrom(msg.sender, address(this), _amount);
        }
        giftNumber[msg.sender][_giftType] = _number;
        emit GiftRequested(msg.sender, _number, _giftType, _chainId, _nftAddress, _tokenId);
    }

    function getMessageHash(address _address, uint256 _giftNum, address _paymentToken, uint256 _amount, uint256 _chainId, address _nftAddress, uint256 _tokenId, uint256 _giftType )
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_address, _giftNum, _paymentToken, _amount, _chainId, _nftAddress, _tokenId, _giftType, address(this)));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verifySignature(
        address _address,
        uint256 _giftNum,
        address _paymentToken,
        uint256 _amount,
        uint256 _chainId, 
        address _nftAddress, 
        uint256 _tokenId,
        uint256 _giftType,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(_address, _giftNum, _paymentToken, _amount, _chainId, _nftAddress, _tokenId, _giftType);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, _signature) == owner();
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
}