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
  function spend(address wallet_, uint256 amount_) external;
  function walletsBalances(address wallet_) external view returns (uint256);
}

contract TreeMarket is Ownable {

    IBloodToken public bloodToken;
    address public signer;

    struct ListItem {
        uint256 projectId; // internal projectId from DB
        address nft; // collection address
        uint256 tokenId; // tokenId
        uint256 price; // only for direct buy, otherwise 0
        bool isAuction;
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

    constructor(
        address _bloodToken,
        address _signer
    ) {
        bloodToken = IBloodToken(_bloodToken);
        signer = _signer;
    }

    function addItems(ListItem[] calldata _items) external onlyOwner {
        for (uint8 i = 0; i < _items.length; i++) {
            require(
                listDetails[_items[i].projectId].nft == address(0), 
                "NFT already listed."
            );

            INFT(_items[i].nft).transferFrom(msg.sender, address(this), _items[i].tokenId);

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
            require(item.nft != address(0), "NFT not listed.");

            INFT(item.nft).transferFrom(address(this), msg.sender, item.tokenId);

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
                listDetails[_items[i].projectId].nft != address(0), 
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
        require(listDetails[_projectId].nft != address(0), "NFT not listed.");
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
        require(listDetails[_projectId].nft != address(0), "NFT not listed.");
        require(listDetails[_projectId].isAuction, "Auction bid not allowed.");
        require(
            validateSignature(msg.sender, _nft, _tokenId, _projectId, _price, _timestamp, _signature),
            "Invalid signature."
        );

        executeOrder(_nft, _tokenId, _projectId, _price);
    }

    function executeOrder(address _nft, uint256 _tokenId, uint256 _projectId, uint256 _price) private {
        require(
            bloodToken.walletsBalances(msg.sender) >= _price, 
            "Insufficient BLD on internal wallet."
        );
        
        if (_price > 0) {
            bloodToken.spend(msg.sender, _price);
        }
        INFT(_nft).transferFrom(address(this), msg.sender, _tokenId);

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

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }
}
