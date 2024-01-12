// SPDX-License-Identifier: MIT
/*
 ______     __                            __           __                      __
|_   _ \   [  |                          |  ]         [  |                    |  ]
  | |_) |   | |    .--.     .--.     .--.| |   .--.    | |--.    .---.    .--.| |
  |  __'.   | |  / .'`\ \ / .'`\ \ / /'`\' |  ( (`\]   | .-. |  / /__\\ / /'`\' |
 _| |__) |  | |  | \__. | | \__. | | \__/  |   `'.'.   | | | |  | \__., | \__/  |
|_______/  [___]  '.__.'   '.__.'   '.__.;__] [\__) ) [___]|__]  '.__.'  '.__.;__]
                      ________
                      ___  __ )_____ ______ _________________
                      __  __  |_  _ \_  __ `/__  ___/__  ___/
                      _  /_/ / /  __// /_/ / _  /    _(__  )
                      /_____/  \___/ \__,_/  /_/     /____/
*/
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";

interface INFT {
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

interface IBloodToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external;
}

contract TreeMarketRoot is Ownable {

    IBloodToken public bloodToken;
    address public signer;
    address public paymentAddr;
    uint8 public burnPercent = 70;

    struct ListItem {
        uint256 projectId; // internal projectId from DB
        address nft; // collection address
        uint256 tokenId; // tokenId
        uint256 price; // only for direct buy, otherwise 0
        bool isAuction;
        bool exists;
    }

    struct ItemRemove {
        address nft; // collection address
        uint256 tokenId; // tokenId
    }

    mapping(uint256 => ListItem) public listDetails;
    mapping(bytes32 => bool) private hashUsage;

    event ItemAdded(uint256 project, address nft, uint256 tokenId, uint256 price, bool isAuction);
    event ItemRemoved(uint256 project, address nft, uint256 tokenId);
    event ItemModified(uint256 project, address nft, uint256 tokenId, uint256 price, bool isAuction);
    event ItemBought(address wallet, uint256 project, uint256 price, bool isAuction);

    event TransferWithBurn(address sender, uint256 burnPercentage);

    constructor(
        address _bloodToken,
        address _signer,
        address _paymentAddr
    ) {
        bloodToken = IBloodToken(_bloodToken);
        signer = _signer;
        paymentAddr = _paymentAddr;
    }

    function addItems(ListItem[] calldata _items) external onlyOwner {
        for (uint8 i = 0; i < _items.length; i++) {
            require(
                !listDetails[_items[i].projectId].exists, 
                "NFT already listed."
            );
            require(
                _items[i].exists, 
                "Param `exists` has to be set on true."
            );

            if (_items[i].nft != address(0)) {
                INFT(_items[i].nft).transferFrom(msg.sender, address(this), _items[i].tokenId);
            }

            listDetails[_items[i].projectId] = _items[i];

            emit ItemAdded(
                _items[i].projectId, 
                _items[i].nft, 
                _items[i].tokenId, 
                _items[i].price, 
                _items[i].isAuction
            );
        }
    }

    function removeItems(uint256[] calldata _projectIds) external onlyOwner {
        for (uint8 i = 0; i < _projectIds.length; i++) {
            ListItem memory item = listDetails[_projectIds[i]];
            require(item.exists, "NFT not listed.");

            if (item.nft != address(0)) {
                INFT(item.nft).transferFrom(address(this), msg.sender, item.tokenId);
            }

            emit ItemRemoved(
                _projectIds[i], 
                listDetails[_projectIds[i]].nft, 
                listDetails[_projectIds[i]].tokenId
            );
            delete listDetails[_projectIds[i]];
        }
    }

    function modifyItems(ListItem[] calldata _items) external onlyOwner {
        for (uint8 i = 0; i < _items.length; i++) {
            require(
                listDetails[_items[i].projectId].exists, 
                "NFT not listed."
            );

            listDetails[_items[i].projectId].price = _items[i].price;
            listDetails[_items[i].projectId].isAuction = _items[i].isAuction;

            emit ItemModified(
                _items[i].projectId, 
                _items[i].nft, 
                _items[i].tokenId, 
                _items[i].price, 
                _items[i].isAuction
            );
        }
    }

    function directBuy(address _nft, uint256 _tokenId, uint256 _projectId) external {
        require(listDetails[_projectId].exists, "NFT not listed.");
        require(!listDetails[_projectId].isAuction, "Direct buy not allowed.");

        executeOrder(_nft, _tokenId, _projectId, listDetails[_projectId].price);
    }

    function claimBid(
        address _nft, 
        uint256 _tokenId,
        uint256 _projectId,
        uint256 _price, 
        uint256 _timestamp, 
        bytes memory _signature
    ) external {
        require(listDetails[_projectId].exists, "NFT not listed.");
        require(listDetails[_projectId].isAuction, "Auction bid not allowed.");
        require(
            validateSignature(msg.sender, _nft, _tokenId, _projectId, _price, _timestamp, _signature),
            "Invalid signature."
        );

        executeOrder(_nft, _tokenId, _projectId, _price);
    }

    function executeOrder(address _nft, uint256 _tokenId, uint256 _projectId, uint256 _price) private {
        if (_price > 0) {
            spendBLD(_price, burnPercent);
        }

        if (_nft != address(0)) {
            INFT(_nft).transferFrom(address(this), msg.sender, _tokenId);
        }

        emit ItemBought(msg.sender, _projectId, _price, listDetails[_projectId].isAuction);
        delete listDetails[_projectId];
    }

    /**
    * @dev Validates signature.
    * @param _sender User wanting to buy.
    * @param _nft Collection address.
    * @param _tokenId tokenId from collection.
    * @param _projectId projectId from DB.
    * @param _price Price for which user is buying.
    * @param _timestamp Signature creation timestamp.
    * @param _signature Signature of above data.
    */
    function validateSignature(
        address _sender,
        address _nft,
        uint256 _tokenId,
        uint256 _projectId,
        uint256 _price,
        uint256 _timestamp,
        bytes memory _signature
    ) private returns (bool) {
        bytes32 dataHash = keccak256(
            abi.encodePacked(_sender, _nft, _tokenId, _projectId, _price, _timestamp)
        );
        require(!hashUsage[dataHash], "Signature already used.");
        hashUsage[dataHash] = true;

        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);
        address receivedAddress = ECDSA.recover(message, _signature);
        return receivedAddress == signer;
    }

    function spendBLD(uint256 _amount, uint8 _burnPercentage) private {
        uint256 burnAmount = 0;
        if (_burnPercentage > 0) {
            burnAmount = _amount * _burnPercentage / 100;
            bloodToken.burnFrom(msg.sender, burnAmount);
            emit TransferWithBurn(msg.sender, _burnPercentage);
        }

        uint256 tranAmt = _amount - burnAmount;
        if (tranAmt > 0) {
            require(
                bloodToken.transferFrom(msg.sender, paymentAddr, tranAmt), 
                "Payment failed."
            );
        }
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setSpendData(address _paymentAddr, uint8 _burnPercent) external onlyOwner {
        paymentAddr = _paymentAddr;
        burnPercent = _burnPercent;
    }
}
