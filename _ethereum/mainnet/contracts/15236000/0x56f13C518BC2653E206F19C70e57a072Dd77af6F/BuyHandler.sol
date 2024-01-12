// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./IAviumNFT.sol";
import "./BuySignatureUtils.sol";

contract BuyHandler is ReentrancyGuard, BuySignatureUtils {
    address public immutable PROXY;
    uint256 public price;
    uint256 public buyLimit;
    address public recipientAddress;
    uint256 public privateStartTime;
    uint256 public privateEndTime;
    uint256 public publicEndTime;
    address public signer;
    mapping(address => uint256) public mintAmount;
    mapping(string => bool) public existedUuid;

    constructor(
        address proxy,
        uint256 _price,
        uint256 _privateStartTime,
        uint256 _privateEndTime,
        uint256 _publicEndTime,
        address _signer
    ) {
        require(
            _privateEndTime > _privateStartTime,
            "BuyHandler: the end time should be greater than the start time"
        );
        require(
            _privateEndTime < _publicEndTime,
            "BuyHandler: the public end time should be greater than the private end time"
        );
        PROXY = proxy;
        price = _price;
        privateStartTime = _privateStartTime;
        privateEndTime = _privateEndTime;
        publicEndTime = _publicEndTime;
        buyLimit = 1;
        recipientAddress = msg.sender;
        signer = _signer;
    }

    event BuyEvent(
        string uuid,
        address to,
        uint256 quantity,
        uint256 currentIndex,
        uint256 price
    );

    event BuyRemainNFTsEvent(
        address to,
        uint256 quantity,
        uint256 currentIndex
    );

    /**
     * @dev Set the buy limit
     * @param _buyLimit the new buy limit
     */
    function setLimitBuy(uint256 _buyLimit) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        buyLimit = _buyLimit;
    }

    /**
     * @dev Set the signer address
     * @param _signer the new signer address
     */
    function setSignerAddress(address _signer) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        require(_signer != address(0), "BuyHandler: invalid _signer");
        signer = _signer;
    }

    /**
     * @dev Set the recipient address
     * @param _recipientAddress the new recipient address
     */
    function setRecipientAddress(address _recipientAddress) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        recipientAddress = _recipientAddress;
    }

    /**
     * @dev Set the start time
     * @param _privateStartTime the new start time
     */
    function setPrivateStartTime(uint256 _privateStartTime) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        require(
            _privateStartTime < privateEndTime,
            "BuyHandler: the end time should be greater than the start time"
        );
        privateStartTime = _privateStartTime;
    }

    /**
     @dev Set the private price
     @param _price the new private price
    */
    function setprice(uint256 _price) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        price = _price;
    }

    /**
     * @dev Set the private end time
     * @param _privateEndTime the new private end time
     */
    function setPrivateEndTime(uint256 _privateEndTime) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        require(
            _privateEndTime > privateStartTime,
            "BuyHandler: the end time should be greater than the start time"
        );
        require(
            _privateEndTime < publicEndTime,
            "BuyHandler: the public end time should be greater than the private end time"
        );
        privateEndTime = _privateEndTime;
    }

    /**
     * @dev Set the public end time
     * @param _publicEndTime the new public end time
     */
    function setPublicEndTime(uint256 _publicEndTime) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        require(
            privateEndTime < _publicEndTime,
            "BuyHandler: the public end time should be greater than the private end time"
        );
        publicEndTime = _publicEndTime;
    }

    /**
     * @dev Buy NFT
     * @param _uuid the sale order id
     * @param _to the address will receive NFTs
     * @param _quantity the quantity of NFTs
     * @param _signature the signature to buy NFTs
     * @param _data data byte
     */
    function buy(
        string memory _uuid,
        address _to,
        uint256 _quantity,
        uint256 _userType,
        bytes memory _signature,
        bytes memory _data
    ) public payable nonReentrant {
        uint256 currentIndex = IAviumNFT(PROXY).getCurrentIndex();
        // require(block.timestamp >= privateStartTime && block.timestamp <= privateEndTime, "BuyHandler: you can not buy nft at this time");
        require(
            verifyBuySignature(
                signer,
                _uuid,
                _to,
                _quantity,
                msg.sender,
                _userType,
                _signature
            ),
            "BuyHandler: wrong signature"
        );
        if (block.timestamp < privateStartTime)
            revert("BuyHandler: you can not buy nft at this time");
        else if (
            block.timestamp >= privateStartTime &&
            block.timestamp <= privateEndTime
        ) {
            if (_userType == 1)
                revert("BuyHandler: you can not buy nft at this time");
            else if (_userType == 2)
                require(
                    mintAmount[msg.sender] < 2,
                    "BuyHandler: you bought exceed the allowed amount"
                );
        } else if (
            block.timestamp > privateEndTime && block.timestamp <= publicEndTime
        ) {
            if (_userType == 1)
                require(
                    mintAmount[msg.sender] < 1,
                    "BuyHandler: you bought exceed the allowed amount"
                );
            else if (_userType == 2)
                require(
                    mintAmount[msg.sender] < 2,
                    "BuyHandler: you bought exceed the allowed amount"
                );
        } else revert("BuyHandler: you can not buy nft at this time");
        require(
            msg.sender == _to,
            "BuyHandler: the sender address should be the address that will receive NFTs"
        );
        require(existedUuid[_uuid] != true, "BuyHandler: the uuid was existed");
        require(
            _quantity <= buyLimit,
            "BuyHandler: the quantity exceed the limit buy"
        );
        require(
            currentIndex + _quantity <= IAviumNFT(PROXY).getTotalMint() + 1,
            "BuyHandler: the total mint has been exeeded"
        );
        require(
            msg.value == price * _quantity,
            "BuyHandler: you don't send enough eth"
        );
        mintAmount[msg.sender] += _quantity;
        existedUuid[_uuid] = true;
        payable(recipientAddress).transfer(msg.value);
        IAviumNFT(PROXY).mint(_to, _quantity, _data);
        emit BuyEvent(_uuid, _to, _quantity, currentIndex, msg.value);
    }

    /**
     * @dev Buy the remaining NFTs
     * @param _to the address will receive NFTs
     * @param _data data byte
     */
    function buyRemainNFTs(address _to, bytes memory _data)
        public
        nonReentrant
    {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        uint256 currentIndex = IAviumNFT(PROXY).getCurrentIndex();
        require(
            currentIndex <= IAviumNFT(PROXY).getTotalMint(),
            "BuyHandler:the total mint has been exeeded"
        );
        require(
            block.timestamp > publicEndTime,
            "BuyHandler: you can not buy the NFTs in this time"
        );
        uint256 quantity = IAviumNFT(PROXY).getTotalMint() + 1 - currentIndex;
        IAviumNFT(PROXY).mint(_to, quantity, _data);
        emit BuyRemainNFTsEvent(_to, quantity, currentIndex);
    }
}
