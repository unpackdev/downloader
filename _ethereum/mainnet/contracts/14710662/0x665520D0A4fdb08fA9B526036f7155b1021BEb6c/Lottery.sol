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
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

interface IBloodToken {
  function spend(address wallet_, uint256 amount_) external;
  function walletsBalances(address wallet_) external view returns (uint256);
}

contract Lottery is VRFConsumerBaseV2, Ownable {

    uint256 private constant MAX_CHANCE = 1_000_000;
    uint256 private constant MAX_UINT256 = type(uint256).max;

    IBloodToken public bloodToken;

    struct ListItem {
        uint256 roundStart; // timestamp
        uint8 status; // 0 = not listed, 1 = don't allow tickets, 2 = allow tickets
        uint256 price; // price of ticket in BLD
        uint32 chance; // number between 1 - MAX_CHANCE, if tickets are limited than 0, should be 1 of N (N = chance)
        /* 
        100% chance = 1
        50% chance = 2
        33.3% chance = 3
        10% chance = 10
        5% chance = 20
        1% chance = 100
        0.1% chance = 1000
        */
        uint256 tickets; // max tickets available, 0 = unlimited
        uint256 maxPerAddress; // max tickets per address, 0 = unlimited
        address winner; // only gets set if user wins it with chance ticket
        address winnerBLD; // only gets set if user wins it with chance ticket
    }

    struct InputItem {
        /* InputItem only used as input parameter */
        uint256 projectId;
        uint8 status;
        uint256 price;
        uint32 chance;
        uint256 tickets;
        uint256 maxPerAddress;
    }

    mapping(uint256 => ListItem) public listDetails; // projectId => ListItem 
    mapping(uint256 => mapping(uint256 => address[])) public projectTickets;
    mapping(bytes32 => uint256) public projectTicketsUser; // bytes32 = projectId + roundStart + address

    mapping(uint256 => uint256[]) private vrfRequest; // requestId => projectIds

    // VRF Settings
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    address vrfCoordinator;
    bytes32 s_keyHash;

    uint32 callbackGasLimit = 200000;
    uint16 requestConfirmations = 3;

    event ChanceBought(address wallet, uint256 project, uint256 price, uint256 tickets);
    event DrawComplete(uint256 project, address winner, address winnerBLD);
    event ItemAdded(
        uint256 project, 
        uint256 roundStart, 
        uint8 status, 
        uint256 price, 
        uint32 chance, 
        uint256 tickets, 
        uint256 maxPerAddress
    );
    event ItemUpdated(
        uint256 project, 
        uint8 status, 
        uint256 price, 
        uint32 chance, 
        uint256 tickets, 
        uint256 maxPerAddress
    );
    event ItemRemoved(uint256 project);
    event ItemRestarted(uint256 project, uint256 roundStart);

    constructor(
        address _bloodToken,
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _sKeyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        bloodToken = IBloodToken(_bloodToken);
        vrfCoordinator = _vrfCoordinator;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = _subscriptionId;
        s_keyHash = _sKeyHash;
    }

    /**
    * @dev Add items.
    * @param _items: [InputItem, InputItem, ...]
    */
    function addItems(InputItem[] calldata _items) external onlyOwner {
        for (uint8 i = 0; i < _items.length; i++) {
            require(
                listDetails[_items[i].projectId].status == 0, 
                "Item already listed."
            );
            require(
                _items[i].chance >= 0 && _items[i].chance < MAX_CHANCE, 
                "Chance needs to be in range 0 - MAX_CHANCE."
            );
            require(
                _items[i].status == 1 || _items[i].status == 2, 
                "Status needs to be 1 or 2."
            );

            listDetails[_items[i].projectId] = ListItem({
                roundStart: block.timestamp,
                status: _items[i].status,
                price: _items[i].price,
                chance: _items[i].chance,
                tickets: _items[i].tickets,
                maxPerAddress: _items[i].maxPerAddress,
                winner: address(0),
                winnerBLD: address(0)
            });

            emit ItemAdded(
                _items[i].projectId, 
                listDetails[_items[i].projectId].roundStart, 
                listDetails[_items[i].projectId].status, 
                listDetails[_items[i].projectId].price, 
                listDetails[_items[i].projectId].chance, 
                listDetails[_items[i].projectId].tickets,
                listDetails[_items[i].projectId].maxPerAddress
            );
        }
    }

    /**
    * @dev Remove items.
    * @param _items: [projectId, projectId, projectId, ...]
    */
    function removeItems(uint256[] calldata _items) external onlyOwner {
        for (uint8 i = 0; i < _items.length; i++) {
            require(
                listDetails[_items[i]].status != 0, 
                "Item NOT listed."
            );
            require(
                listDetails[_items[i]].winner == address(0), 
                "Item already won."
            );
            delete listDetails[_items[i]];
            emit ItemRemoved(_items[i]);
        }
    }

    /**
    * @dev Update items.
    * @param _items: [InputItem, InputItem, ...]
    */
    function updateItems(InputItem[] calldata _items) external onlyOwner {
        for (uint8 i = 0; i < _items.length; i++) {
            require(
                listDetails[_items[i].projectId].status != 0, 
                "Item NOT listed."
            );
            require(
                listDetails[_items[i].projectId].winner == address(0), 
                "Item already won."
            );
            require(
                _items[i].chance >= 0 && _items[i].chance < MAX_CHANCE, 
                "Chance needs to be in range 0 - MAX_CHANCE."
            );
            require(
                _items[i].status == 1 || _items[i].status == 2, 
                "Status needs to be 1 or 2."
            );

            listDetails[_items[i].projectId].status = _items[i].status;
            listDetails[_items[i].projectId].price = _items[i].price;
            listDetails[_items[i].projectId].chance = _items[i].chance;
            listDetails[_items[i].projectId].tickets = _items[i].tickets;
            listDetails[_items[i].projectId].maxPerAddress = _items[i].maxPerAddress;

            emit ItemUpdated(
                _items[i].projectId, 
                listDetails[_items[i].projectId].status, 
                listDetails[_items[i].projectId].price, 
                listDetails[_items[i].projectId].chance, 
                listDetails[_items[i].projectId].tickets,
                listDetails[_items[i].projectId].maxPerAddress
            );
        }
    }

    /**
    * @dev Restart items.
    * @param _projectIds: [projectId, projectId, ...]
    */
    function restartItems(uint256[] calldata _projectIds) external onlyOwner {
        for (uint8 i = 0; i < _projectIds.length; i++) {
            require(
                listDetails[_projectIds[i]].status == 1, 
                "Item with incorrect status."
            );
            require(
                listDetails[_projectIds[i]].winner == address(0), 
                "Item already won."
            );

            listDetails[_projectIds[i]].status = 2;
            listDetails[_projectIds[i]].roundStart = block.timestamp;
            listDetails[_projectIds[i]].winnerBLD = address(0);

            emit ItemRestarted(_projectIds[i], listDetails[_projectIds[i]].roundStart);
        }
    }

    /**
    * @dev Buy chance to participate.
    * @param _items: [[projectId, tickets], [projectId, tickets], ...]
    */
    function buyChance(uint256[][] calldata _items, address _user) external {
        uint256 projectId;
        uint256 tickets;
        uint256 amtTotal;
        for (uint8 i = 0; i < _items.length; i++) {
            projectId = _items[i][0];
            tickets = _items[i][1];

            if (tickets > 0) {
                require(listDetails[projectId].status == 2, "Cannot buy item tickets.");
                require(
                    listDetails[projectId].tickets == 0 || 
                    listDetails[projectId].tickets >= noProjTickets(projectId) + tickets, 
                    "Not enough tickets available."
                );

                require(
                    getAvailableTickets(projectId, _user) >= tickets,
                    "Too many tickets requested."
                );

                amtTotal += listDetails[projectId].price * tickets;

                // add tickets for user
                for (uint256 j = 0; j < tickets; j ++) {
                    projectTickets[projectId][listDetails[projectId].roundStart].push(_user);
                }
                projectTicketsUser[getUserHash(projectId, _user)] += tickets;

                emit ChanceBought(_user, projectId, listDetails[projectId].price, tickets);
            }
        }

        if (msg.sender != owner()) {
            require(
                bloodToken.walletsBalances(msg.sender) >= amtTotal, 
                "Insufficient BLD on internal wallet."
            );
            bloodToken.spend(msg.sender, amtTotal);
        }
    }

    /**
    * @dev Draw results to get winners.
    * @param _items: [projectId, projectId, projectId, ...]
    */
    function draw(uint256[] calldata _items) external onlyOwner {
        // Will revert if subscription is not set and funded.
        uint256 _requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            uint32(_items.length)
        );

        uint256 projectId;
        for (uint8 i = 0; i < _items.length; i++) {
            projectId = _items[i];

            require(
                listDetails[projectId].status != 0, 
                "Item NOT listed."
            );
            require(
                listDetails[projectId].winner == address(0), 
                "Item already won."
            );

            vrfRequest[_requestId].push(projectId);
        }
    }

    function noProjTickets(uint256 _projectId) public view returns (uint256) {
        return projectTickets[_projectId][listDetails[_projectId].roundStart].length;
    }

    function getProjTicket(uint256 _projectId, uint256 _idx) public view returns (address) {
        return projectTickets[_projectId][listDetails[_projectId].roundStart][_idx];
    }

    function getUserHash(uint256 _projectId, address _user) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(_projectId, listDetails[_projectId].roundStart, _user)
        );
    }

    function getAvailableTickets(uint256 _projectId, address _user) public view returns (uint256) {
        return listDetails[_projectId].maxPerAddress - projectTicketsUser[getUserHash(_projectId, _user)];
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 projectId;
        uint256 winnerIdx;
        uint256 cntProjTickets;
        for (uint256 i = 0; i < randomWords.length; i++) {
            projectId = vrfRequest[requestId][i];

            if (listDetails[projectId].status == 2) {
                // fail safe in case of multiple draw events

                cntProjTickets = noProjTickets(projectId);
                listDetails[projectId].status = 1; // disable submitting tickets

                if (listDetails[projectId].tickets > 0) {
                    // guaranteed winner
                    winnerIdx = randomWords[i] % cntProjTickets;

                } else {
                    // non-guaranteed winner
                    winnerIdx = randomWords[i] % (listDetails[projectId].chance * cntProjTickets);
                    if (winnerIdx > cntProjTickets - 1) {
                        winnerIdx = MAX_UINT256;
                    }
                }

                if (winnerIdx != MAX_UINT256) {
                    listDetails[projectId].winner = getProjTicket(projectId, winnerIdx);
                }

                // get BLD winner
                listDetails[projectId].winnerBLD = getProjTicket(
                    projectId, (randomWords[i] + block.timestamp) % cntProjTickets
                );
                
                emit DrawComplete(projectId, listDetails[projectId].winner, listDetails[projectId].winnerBLD);
            }
        }
    }
}
