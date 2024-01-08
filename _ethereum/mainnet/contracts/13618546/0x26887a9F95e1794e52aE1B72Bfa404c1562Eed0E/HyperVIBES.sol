//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*


    ██╗  ██╗██╗   ██╗██████╗ ███████╗██████╗ ██╗   ██╗██╗██████╗ ███████╗███████╗
    ██║  ██║╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗██║   ██║██║██╔══██╗██╔════╝██╔════╝
    ███████║ ╚████╔╝ ██████╔╝█████╗  ██████╔╝██║   ██║██║██████╔╝█████╗  ███████╗
    ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══╝  ██╔══██╗╚██╗ ██╔╝██║██╔══██╗██╔══╝  ╚════██║
    ██║  ██║   ██║   ██║     ███████╗██║  ██║ ╚████╔╝ ██║██████╔╝███████╗███████║
    ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═════╝ ╚══════╝╚══════╝


    The possibilities are endless in the realms of your imagination.
    What would you do with that power?

                            Dreamt up & built at
                                Rarible DAO

                                  * * * *

    HyperVIBES is a public and free protocol from Rarible DAO that lets you
    infuse any ERC-20 token into ERC-721 NFTs from any minting platform.

    Infused tokens can be mined and claimed by the NFT owner over time.

    Create a fully isolated and independently configured HyperVIBES realm to run
    your own experiments or protocols without having to deploy a smart contract.

    HyperVIBES is:
    - 🎁 Open Source
    - 🥳 Massively Multiplayer
    - 🌈 Public Infrastructure
    - 🚀 Unstoppable and Censor-Proof
    - 🌎 Multi-chain
    - 💖 Free Forever

    Feel free to use HyperVIBES in any way you want.

    https://hypervibes.xyz
    https://app.hypervibes.xyz
    https://docs.hypervibes.xyz

*/

import "./IHyperVIBES.sol";
import "./ReentrancyGuard.sol";

contract HyperVIBES is IHyperVIBES, ReentrancyGuard {
    bool constant public FEEL_FREE_TO_USE_HYPERVIBES_IN_ANY_WAY_YOU_WANT = true;

    // ---
    // storage
    // ---

    // realm ID -> realm data
    mapping(uint256 => RealmConfig) public realmConfig;

    // realm ID -> address -> (is admin flag)
    mapping(uint256 => mapping(address => bool)) public isAdmin;

    // realm ID -> address -> (is infuser flag)
    mapping(uint256 => mapping(address => bool)) public isInfuser;

    // realm ID -> address -> (is claimer flag)
    mapping(uint256 => mapping(address => bool)) public isClaimer;

    // realm ID -> erc721 -> (is allowed collection flag)
    mapping(uint256 => mapping(IERC721 => bool)) public isCollection;

    // realm ID -> nft -> token ID -> token data
    mapping(uint256 => mapping(IERC721 => mapping(uint256 => TokenData)))
        public tokenData;

    // realm ID -> operator -> infuser -> (is allowed proxy flag)
    mapping(uint256 => mapping(address => mapping(address => bool))) public isProxy;

    uint256 public nextRealmId = 1;

    // ---
    // admin mutations
    // ---

    // setup a new realm
    function createRealm(CreateRealmInput memory create) override external returns (uint256) {
        require(create.config.token != IERC20(address(0)), "invalid token");
        require(create.config.constraints.maxTokenBalance > 0, "invalid max token balance");
        require(
            create.config.constraints.minClaimAmount <= create.config.constraints.maxTokenBalance,
            "invalid min claim amount");

        uint256 realmId = nextRealmId++;
        realmConfig[realmId] = create.config;

        emit RealmCreated(realmId, create.name, create.description);

        for (uint256 i = 0; i < create.admins.length; i++) {
            _addAdmin(realmId, create.admins[i]);
        }

        for (uint256 i = 0; i < create.infusers.length; i++) {
            _addInfuser(realmId, create.infusers[i]);
        }

        for (uint256 i = 0; i < create.claimers.length; i++) {
            _addClaimer(realmId, create.claimers[i]);
        }

        for (uint256 i = 0; i < create.collections.length; i++) {
            _addCollection(realmId, create.collections[i]);
        }

        return realmId;
    }

    // update mutable configuration for a realm
    function modifyRealm(ModifyRealmInput memory input) override external {
        require(_realmExists(input.realmId), "invalid realm");
        require(isAdmin[input.realmId][msg.sender], "not realm admin");

        // adds

        for (uint256 i = 0; i < input.adminsToAdd.length; i++) {
            _addAdmin(input.realmId, input.adminsToAdd[i]);
        }

        for (uint256 i = 0; i < input.infusersToAdd.length; i++) {
            _addInfuser(input.realmId, input.infusersToAdd[i]);
        }

        for (uint256 i = 0; i < input.claimersToAdd.length; i++) {
            _addClaimer(input.realmId, input.claimersToAdd[i]);
        }

        for (uint256 i = 0; i < input.collectionsToAdd.length; i++) {
            _addCollection(input.realmId, input.collectionsToAdd[i]);
        }

        // removes

        for (uint256 i = 0; i < input.adminsToRemove.length; i++) {
            _removeAdmin(input.realmId, input.adminsToRemove[i]);
        }

        for (uint256 i = 0; i < input.infusersToRemove.length; i++) {
            _removeInfuser(input.realmId, input.infusersToRemove[i]);
        }

        for (uint256 i = 0; i < input.claimersToRemove.length; i++) {
            _removeClaimer(input.realmId, input.claimersToRemove[i]);
        }

        for (uint256 i = 0; i < input.collectionsToRemove.length; i++) {
            _removeCollection(input.realmId, input.collectionsToRemove[i]);
        }
    }

    function _addAdmin(uint256 realmId, address admin) internal {
        require(admin != address(0), "invalid admin");
        isAdmin[realmId][admin] = true;
        emit AdminAdded(realmId, admin);
    }

    function _removeAdmin(uint256 realmId, address admin) internal {
        require(admin != address(0), "invalid admin");
        delete isAdmin[realmId][admin];
        emit AdminRemoved(realmId, admin);
    }

    function _addInfuser(uint256 realmId, address infuser) internal {
        require(infuser != address(0), "invalid infuser");
        isInfuser[realmId][infuser] = true;
        emit InfuserAdded(realmId, infuser);
    }

    function _removeInfuser(uint256 realmId, address infuser) internal {
        require(infuser != address(0), "invalid infuser");
        delete isInfuser[realmId][infuser];
        emit InfuserRemoved(realmId, infuser);
    }

    function _addClaimer(uint256 realmId, address claimer) internal {
        require(claimer != address(0), "invalid claimer");
        isClaimer[realmId][claimer] = true;
        emit ClaimerAdded(realmId, claimer);
    }

    function _removeClaimer(uint256 realmId, address claimer) internal {
        require(claimer != address(0), "invalid claimer");
        delete isClaimer[realmId][claimer];
        emit ClaimerRemoved(realmId, claimer);
    }

    function _addCollection(uint256 realmId, IERC721 collection) internal {
        require(collection != IERC721(address(0)), "invalid collection");
        isCollection[realmId][collection] = true;
        emit CollectionAdded(realmId, collection);
    }

    function _removeCollection(uint256 realmId, IERC721 collection) internal {
        require(collection != IERC721(address(0)), "invalid collection");
        delete isCollection[realmId][collection];
        emit CollectionRemoved(realmId, collection);
    }

    // ---
    // infuser mutations
    // ---

    // nonReentrant wrapper
    function infuse(InfuseInput memory input) override external nonReentrant returns (uint256) {
        return _infuse(input);
    }

    function _infuse(InfuseInput memory input) private returns (uint256) {
        TokenData storage data = tokenData[input.realmId][input.collection][input.tokenId];
        RealmConfig memory realm = realmConfig[input.realmId];

        _validateInfusion(input, data, realm);

        // initialize token storage if first infusion
        if (data.lastClaimAt == 0) {
            data.lastClaimAt = block.timestamp;
        }
        // re-set last claim to now if this is empty, else it will pre-mine the
        // time since the last claim
        else if (data.balance == 0) {
            data.lastClaimAt = block.timestamp;
        }

        // determine if we need to clamp the amount based on maxTokenBalance
        uint256 nextBalance = data.balance + input.amount;
        uint256 clampedBalance = nextBalance > realm.constraints.maxTokenBalance
            ? realm.constraints.maxTokenBalance
            : nextBalance;
        uint256 amountToTransfer = clampedBalance - data.balance;

        // jit assert that this amount is valid within constraints
        require(amountToTransfer > 0, "nothing to transfer");
        require(amountToTransfer >= realm.constraints.minInfusionAmount, "amount too low");

        // pull tokens from msg sender into the contract
        data.balance += amountToTransfer;
        realm.token.transferFrom(msg.sender, address(this), amountToTransfer);

        emit Infused(
            input.realmId,
            input.collection,
            input.tokenId,
            input.infuser,
            input.amount,
            input.comment
        );

        return amountToTransfer;
    }

    function _validateInfusion(InfuseInput memory input, TokenData memory data, RealmConfig memory realm) internal view {
        require(_isTokenValid(input.collection, input.tokenId), "invalid token");
        require(_realmExists(input.realmId), "invalid realm");

        bool isOwnedByInfuser = input.collection.ownerOf(input.tokenId) == input.infuser;
        bool isOnInfuserAllowlist = isInfuser[input.realmId][msg.sender];
        bool isOnCollectionAllowlist = isCollection[input.realmId][input.collection];
        bool isValidProxy = isProxy[input.realmId][msg.sender][input.infuser];

        require(isOwnedByInfuser || !realm.constraints.requireNftIsOwned, "nft not owned by infuser");
        require(isOnInfuserAllowlist || realm.constraints.allowPublicInfusion, "invalid infuser");
        require(isOnCollectionAllowlist || realm.constraints.allowAllCollections, "invalid collection");
        require(isValidProxy || msg.sender == input.infuser, "invalid proxy");

        // if already infused...
        if (data.lastClaimAt != 0) {
            require(realm.constraints.allowMultiInfuse, "multi infuse disabled");
        }
    }

    // ---
    // proxy mutations
    // ---

    // allower operator to infuse or claim on behalf of msg.sender for a specific realm
    function allowProxy(uint256 realmId, address proxy) override external {
        require(_realmExists(realmId), "invalid realm");
        isProxy[realmId][proxy][msg.sender] = true;
        emit ProxyAdded(realmId, proxy);
    }

    // deny operator the ability to infuse or claim on behalf of msg.sender for a specific realm
    function denyProxy(uint256 realmId, address proxy) override external {
        require(_realmExists(realmId), "invalid realm");
        delete isProxy[realmId][proxy][msg.sender];
        emit ProxyRemoved(realmId, proxy);
    }

    // ---
    // claimer mutations
    // ---

    // nonReentrant wrapper
    function claim(ClaimInput memory input) override external nonReentrant returns (uint256) {
        return _claim(input);
    }

    function _claim(ClaimInput memory input) private returns (uint256) {
        require(_isTokenValid(input.collection, input.tokenId), "invalid token");
        require(_isValidClaimer(input.realmId, input.collection, input.tokenId), "invalid claimer");

        TokenData storage data = tokenData[input.realmId][input.collection][input.tokenId];
        require(data.lastClaimAt != 0, "token not infused");

        // compute mined / claimable
        uint256 secondsToClaim = block.timestamp - data.lastClaimAt;
        uint256 mined = (secondsToClaim * realmConfig[input.realmId].dailyRate) / 1 days;
        uint256 availableToClaim = mined > data.balance ? data.balance : mined;

        // only pay attention to amount if its less than available
        uint256 toClaim = input.amount < availableToClaim ? input.amount : availableToClaim;
        require(toClaim >= realmConfig[input.realmId].constraints.minClaimAmount, "amount too low");
        require(toClaim > 0, "nothing to claim");

        // claim only as far up as we need to get our amount... basically "advances"
        // the lastClaim timestamp the exact amount needed to provide the amount
        // claim at = last + (to claim / rate) * 1 day, rewritten for div last
        uint256 claimAt = data.lastClaimAt + (toClaim * 1 days) / realmConfig[input.realmId].dailyRate;

        // update balances and execute ERC-20 transfer
        data.balance -= toClaim;
        data.lastClaimAt = claimAt;
        realmConfig[input.realmId].token.transfer(msg.sender, toClaim);

        emit Claimed(input.realmId, input.collection, input.tokenId, toClaim);

        return toClaim;
    }

    // returns true if msg.sender can claim for a given (realm/collection/tokenId) tuple
    function _isValidClaimer(uint256 realmId, IERC721 collection, uint256 tokenId) internal view returns (bool) {
        address owner = collection.ownerOf(tokenId);

        bool isOwned = owner == msg.sender;
        bool isValidProxy = isProxy[realmId][msg.sender][owner];

        // no matter what, msg sender must be owner or have authorized a proxy.
        // ensures that claiming can never happen without owner approval of some
        // sort
        if (!isOwned && !isValidProxy) {
            return false;
        }

        // if public claim is valid, we're good to go
        if (realmConfig[realmId].constraints.allowPublicClaiming) {
            return true;
        }

        // otherwise, must be on claimer list
        return isClaimer[realmId][msg.sender];
    }


    // ---
    // batch utils
    // ---

    function batchClaim(ClaimInput[] memory batch)
        override external nonReentrant
        returns (uint256)
    {
        uint256 totalClaimed = 0;
        for (uint256 i = 0; i < batch.length; i++) {
            totalClaimed += _claim(batch[i]);
        }
        return totalClaimed;
    }

    function batchInfuse(InfuseInput[] memory batch)
        override external nonReentrant
        returns (uint256)
    {
        uint256 totalInfused = 0;
        for (uint256 i; i < batch.length; i++) {
            totalInfused += _infuse(batch[i]);
        }
        return totalInfused;
    }


    // ---
    // views
    // ---

    function name() override external pure returns (string memory) {
        return "HyperVIBES";
    }


    // total amount of mined tokens
    // will return 0 if the token is not infused instead of reverting
    // will return 0 if the does not exist (burned, invalid contract or id)
    // will return amount mined even if not claimable (minClaimAmount constraint)
    function currentMinedTokens(uint256 realmId, IERC721 collection, uint256 tokenId)
        override external view returns (uint256)
    {
        require(_realmExists(realmId), "invalid realm");

        TokenData memory data = tokenData[realmId][collection][tokenId];

        // if non-existing token
        if (!_isTokenValid(collection, tokenId)) {
            return 0;
        }

        // not infused
        if (data.lastClaimAt == 0) {
            return 0;
        }

        uint256 miningTime = block.timestamp - data.lastClaimAt;
        uint256 mined = (miningTime * realmConfig[realmId].dailyRate) / 1 days;
        uint256 clamped = mined > data.balance ? data.balance : mined;
        return clamped;
    }

    // ---
    // utils
    // ---

    // returns true if a realm has been setup
    function _realmExists(uint256 realmId) internal view returns (bool) {
        return realmConfig[realmId].token != IERC20(address(0));
    }

    // returns true if token exists (and is not burnt)
    function _isTokenValid(IERC721 collection, uint256 tokenId)
        internal view returns (bool)
    {
        try collection.ownerOf(tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }
}
