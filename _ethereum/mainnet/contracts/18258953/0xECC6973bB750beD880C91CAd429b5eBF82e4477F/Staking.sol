// SPDX-License-Identifier: MIT

    
pragma solidity 0.8.17;
 
import "./IERC721Upgradeable.sol";

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract Staking  is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    
    event TicketsTransfered(address sender, address recipient, uint256 amount);

    struct StakeInfo {
        bool staked; //list of all the tokens that are staked]
        uint256 startTime; //unix timestamp of end of staking
        address staker;
    }

    struct Reward {
        uint256 rewardId;
        address owner;
        address nftCollection;
        uint256 tokenId;
        uint256 ticketsPrice;
        bool claimed;
    }

    //get information for each token
    mapping(uint256 => StakeInfo) public idToStakedClown;
    mapping(uint256 => StakeInfo) public idToStakedJester;

    mapping(address => uint256[]) public stakedClowns;
    mapping(address => uint256[]) public stakedJesters;

    //get information for each reward
    mapping(uint256 => Reward) public idToReward;
    uint256 public lastRewardId;

    IERC721Upgradeable public ChaosClownz;
    IERC721Upgradeable public Jesters;

    uint256 public clownzPerDayTickets;
    uint256 public jestersPerDayTickets;

    mapping(address => uint256) public tickets;
    mapping(address => uint256) public ticketsSpent;

    mapping(address => uint256) internal lastClaimCall;

      function initialize(address clownz_interface, address jesters_interface) initializer public {
       __Ownable_init();
        __UUPSUpgradeable_init();
         ChaosClownz = IERC721Upgradeable(clownz_interface);
        Jesters = IERC721Upgradeable(jesters_interface);
        clownzPerDayTickets = 2;
        jestersPerDayTickets = 1;
    }

   function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    //set ERC721Enumerable
    function setChaosClownz(address newInterface) public onlyOwner {
        ChaosClownz = IERC721Upgradeable(newInterface);
    }

    function setJesters(address newInterface) public onlyOwner {
        Jesters = IERC721Upgradeable(newInterface);
    }

    function setclownzPerDayTickets(uint256 newAmount) external onlyOwner {
        clownzPerDayTickets = newAmount;
    }

    function setjestersPerDayTickets(uint256 newAmount) external onlyOwner {
        jestersPerDayTickets = newAmount;
    }

    function stake(
        uint256[] memory tokenIdsClownz,
        uint256[] memory tokenIdsJesters
    ) external {
        uint256 loopLength = tokenIdsClownz.length > tokenIdsJesters.length
            ? tokenIdsClownz.length
            : tokenIdsJesters.length;

        address sender = _msgSender();

        for (uint256 i = 0; i < loopLength; i++) {
            if (i < tokenIdsClownz.length) {
                uint256 clownzTokenId = tokenIdsClownz[i];
                require(
                    !idToStakedClown[clownzTokenId].staked,
                    "Token is already Staked!"
                );

                require(
                    sender == ChaosClownz.ownerOf(clownzTokenId),
                    "Sender must be owner"
                );

                ChaosClownz.transferFrom(sender, address(this), clownzTokenId);

                stakedClowns[sender].push(clownzTokenId);

                idToStakedClown[clownzTokenId].staked = true;
                idToStakedClown[clownzTokenId].staker = sender;
                idToStakedClown[clownzTokenId].startTime = block.timestamp;
            }
            if (i < tokenIdsJesters.length) {
                uint256 jestersTokenId = tokenIdsJesters[i];
                require(
                    !idToStakedJester[jestersTokenId].staked,
                    "Token is already Staked!"
                );

                require(
                    sender == Jesters.ownerOf(jestersTokenId),
                    "Sender must be owner"
                );

                // Transfer the Jesters token to this contract
                Jesters.transferFrom(sender, address(this), jestersTokenId);

                stakedJesters[sender].push(jestersTokenId);

                idToStakedJester[jestersTokenId].staked = true;
                idToStakedJester[jestersTokenId].staker = sender;
                idToStakedJester[jestersTokenId].startTime = block.timestamp;
            }
        }
    }

    function removeStakedClownsItem(address user, uint256 valueToRemove)
        internal
    {
        uint256[] storage userArray = stakedClowns[user];
        uint256 length = userArray.length;

        for (uint256 i = 0; i < length; i++) {
            if (userArray[i] == valueToRemove) {
                // Found the value to remove; replace it with the last value in the array
                userArray[i] = userArray[length - 1];
                userArray.pop();
                return; // Exit the function after removing the value
            }
        }
    }

    function removeStakedJesterssItem(address user, uint256 valueToRemove)
        internal
    {
        uint256[] storage userArray = stakedJesters[user];
        uint256 length = userArray.length;

        for (uint256 i = 0; i < length; i++) {
            if (userArray[i] == valueToRemove) {
                // Found the value to remove; replace it with the last value in the array
                userArray[i] = userArray[length - 1];
                userArray.pop();
                return; // Exit the function after removing the value
            }
        }
    }

    //unstake all nfts somebody has
    function unstake(
        uint256[] calldata tokenIdsClownz,
        uint256[] calldata tokenIdsJesters
    ) external {
        uint256 loopLength = tokenIdsClownz.length > tokenIdsJesters.length
            ? tokenIdsClownz.length
            : tokenIdsJesters.length;

        address sender = _msgSender();

        for (uint256 i = 0; i < loopLength; i++) {
            if (i < tokenIdsClownz.length) {
                uint256 clownzTokenId = tokenIdsClownz[i];

                require(
                    sender == idToStakedClown[clownzTokenId].staker,
                    "Sender must be owner"
                );
                require(
                    idToStakedClown[clownzTokenId].staked,
                    "Token is not Staked!"
                );

                ChaosClownz.transferFrom(address(this), sender, clownzTokenId);
                removeStakedClownsItem(sender, clownzTokenId);
                //set the info for the stake
                // idToStakedClown[clownzTokenId].staked = false;
                delete idToStakedClown[clownzTokenId];
            }
            if (i < tokenIdsJesters.length) {
                uint256 jestersTokenId = tokenIdsJesters[i];

                require(
                    sender == idToStakedJester[jestersTokenId].staker,
                    "Sender must be owner"
                );
                require(
                    idToStakedJester[jestersTokenId].staked,
                    "Token is not Staked!"
                );

                Jesters.transferFrom(address(this), sender, jestersTokenId);
                removeStakedJesterssItem(sender, jestersTokenId);

                //set the info for the stake
                // idToStakedJester[jestersTokenId].staked = false;
                delete idToStakedJester[jestersTokenId];
            }
        }
    }

    // @TODO: the tickets are added every time you run this function: this is not the intended functionality
    function claim(
        uint256[] calldata tokenIdsClownz,
        uint256[] calldata tokenIdsJesters
    ) external {
        address sender = _msgSender();

        uint256 lastClaimTime = lastClaimCall[sender];

        require(
            block.timestamp - lastClaimTime >= 1 minutes,
            "Can't claim tickets twice per week."
        );

        uint256 newTickets;
        uint256 loopLength = tokenIdsClownz.length > tokenIdsJesters.length
            ? tokenIdsClownz.length
            : tokenIdsJesters.length;

        for (uint256 i = 0; i < loopLength; i++) {
            if (i < tokenIdsClownz.length) {
                uint256 tokenId = tokenIdsClownz[i];
                require(
                    sender == idToStakedClown[tokenId].staker,
                    "Sender must be owner"
                );
                require(
                    idToStakedClown[tokenId].staked,
                    "Token is not Staked!"
                );

                uint256 weeksPassed = (block.timestamp -
                    (idToStakedClown[tokenId].startTime)) / 1 minutes;

                require(
                    weeksPassed >= 1,
                    "It has been less than one week since staking was initiated"
                );

                newTickets += getTicketsClownz(tokenId);
            }
            if (i < tokenIdsJesters.length) {
                uint256 tokenId = tokenIdsJesters[i];
                require(
                    sender == idToStakedJester[tokenId].staker,
                    "Sender must be owner"
                );
                require(
                    idToStakedJester[tokenId].staked,
                    "Token is not Staked!"
                );

                uint256 weeksPassed = (block.timestamp -
                    (idToStakedJester[tokenId].startTime)) / 1 minutes;

                require(
                    weeksPassed >= 1,
                    "It has been less than one week since staking was initiated"
                );

                newTickets += getTicketsJesters(tokenId);
            }
        }

        lastClaimCall[sender] = block.timestamp;
        tickets[sender] += newTickets;
    }

    function getStakedClowns(address staker)
        external
        view
        returns (uint256[] memory)
    {
        return stakedClowns[staker];
    }

    function getStakedClownsInfo(uint256 id)
        external
        view
        returns (StakeInfo memory)
    {
        return idToStakedClown[id];
    }

    function getStakedJestersInfo(uint256 id)
        external
        view
        returns (StakeInfo memory)
    {
        return idToStakedJester[id];
    }

    function getStakedJesters(address staker)
        external
        view
        returns (uint256[] memory)
    {
        return stakedJesters[staker];
    }

    function ClownStakedWeeks(uint256 tokenId) public view returns (uint256) {
        if (idToStakedClown[tokenId].startTime == 0) {
            return 0;
        }
        uint256 weeksPassed = (block.timestamp -
            (idToStakedClown[tokenId].startTime)) / 1 minutes;
        return weeksPassed;
    }

    function JesterStakedWeeks(uint256 tokenId) public view returns (uint256) {
        if (idToStakedJester[tokenId].startTime == 0) {
            return 0;
        }
        uint256 weeksPassed = (block.timestamp -
            idToStakedJester[tokenId].startTime) / 1 minutes;

        return weeksPassed;
    }

    function getTicketsClownz(uint256 tokenId) public view returns (uint256) {
        if (idToStakedClown[tokenId].startTime == 0) {
            return 0;
        }
        uint256 weeksPassed = (block.timestamp -
            (idToStakedClown[tokenId].startTime)) / 1 minutes;
        if (weeksPassed >= 1) {
            return clownzPerDayTickets * weeksPassed;
        } else {
            return 0; // No tickets until at least one week has passed.
        }
    }

    function getTicketsJesters(uint256 tokenId) public view returns (uint256) {
        if (idToStakedJester[tokenId].startTime == 0) {
            return 0;
        }
        uint256 weeksPassed = (block.timestamp -
            idToStakedJester[tokenId].startTime) / 1 minutes;
        if (weeksPassed >= 1) {
            return jestersPerDayTickets * weeksPassed;
        } else {
            return 0; // No tickets until at least one week has passed.
        }
    }

    function totalTickets(address staker) public view returns (uint256) {
        return tickets[staker] - ticketsSpent[staker];
    }

    ///
    /// REWARDS
    ///

    function addRewards(
        address nftCollection,
        uint256[] calldata tokenIds,
        uint256[] calldata ticketsPrice
    ) external onlyOwner {
        require(tokenIds.length == ticketsPrice.length, "Invalid Arrays!");
        address sender = _msgSender();

        IERC721Upgradeable collection = IERC721Upgradeable(nftCollection);

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                collection.ownerOf(tokenId) == sender,
                "Not Owner of Token!"
            );

            collection.transferFrom(sender, address(this), tokenId);

            lastRewardId++;

            idToReward[lastRewardId] = Reward(
                lastRewardId,
                sender,
                nftCollection,
                tokenId,
                ticketsPrice[i],
                false
            );
        }
    }

    function removeRewards(uint256 rewardId) external onlyOwner {
        require(rewardId <= lastRewardId, "Invalid Reward Id!");
        require(idToReward[rewardId].claimed, "Reward has not been claimed!");
        //  idToReward[rewardId].claimed = false;
        delete idToReward[rewardId];
    }

    function claimReward(uint256 rewardId) external {
        Reward memory reward = idToReward[rewardId];
        require(rewardId <= lastRewardId, "Invalid Reward Id!");
        require(!reward.claimed, "Reward has already been claimed!");

        address sender = _msgSender();

        require(
            totalTickets(sender) >= reward.ticketsPrice,
            "Insufficient Tickets!"
        );

        IERC721Upgradeable rota = IERC721Upgradeable(reward.nftCollection);
        rota.transferFrom(address(this), sender, reward.tokenId);

        ticketsSpent[sender] += reward.ticketsPrice;
        idToReward[rewardId].claimed = true; 
        
        delete idToReward[rewardId];

    }

    function transferTickets(address recipient, uint256 amount) external {
        address sender = _msgSender();
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        require(tickets[sender] >= amount, "Insufficient tickets");

        tickets[sender] -= amount;
        tickets[recipient] += amount;

        emit TicketsTransfered(sender, recipient, amount);
    }

    function addTickets(address staker, uint256 amount) external onlyOwner {
        require(staker != address(0), "Invalid staker address");
        require(amount > 0, "Amount must be greater than 0");
        tickets[staker] += amount;
    }

    function spentTickets(address staker, uint256 amount) external onlyOwner {
        require(staker != address(0), "Invalid staker address");
        require(amount > 0, "Amount must be greater than 0");
        ticketsSpent[staker] += amount;
    }

    function addSpentTickets(address staker, uint256 amount)
        external
        onlyOwner
    {
        require(staker != address(0), "Invalid staker address");
        require(amount > 0, "Amount must be greater than 0");
        ticketsSpent[staker] += amount;
    }

    function setStakedClown(uint256 tokenId, uint256 startTime)
        external
        onlyOwner
    {
        require(!idToStakedClown[tokenId].staked, "Token is already staked");
        idToStakedClown[tokenId].staked = true;
        idToStakedClown[tokenId].startTime = startTime;
    }

    function setStakedJester(uint256 tokenId, uint256 startTime)
        external
        onlyOwner
    {
        require(!idToStakedJester[tokenId].staked, "Token is already staked");
        idToStakedJester[tokenId].staked = true;
        idToStakedJester[tokenId].startTime = startTime;
    }

    function updateLastRewardId(uint256 id) external onlyOwner {
        require(
            id > lastRewardId,
            "new last reward id should be greater than existing reward id"
        );
        lastRewardId = id;
    }
}
