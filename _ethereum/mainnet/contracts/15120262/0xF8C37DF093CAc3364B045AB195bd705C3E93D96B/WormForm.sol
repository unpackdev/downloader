// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./UUPSUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IWormForm.sol";

contract WormForm is ERC721Upgradeable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, IWormForm {
    using StringsUpgradeable for uint256;

    address private oldNFTContract;
    address private burnAddress;
    address public backend;

    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 private index;
    uint256 public maxTicketsPerUser;
    uint256 public price;
    uint256 public stakedTotal;
    uint256 private stakingTime4;
    uint256 private stakingTime3;
    uint256 private stakingTime2;
    uint256 private maxTicketsPerWallet;

    string private baseURI;
    string private secondBaseURI;
    string private cocoonURI;
    string public extension;

    bool public revealed;
    bool public secondRevealed;
    bool public ticketSale;
    bool public stakingStarted;
    bool public limitedIdsAreSet;

    uint256[] public toBeClaimed;
    uint256[] public ids;

    struct Stake {
        bool staked;
        uint256 stakedAt;
        uint256[] stakedIds;
    }

    mapping(uint256 => bool) public isLimited;
    mapping(uint256 => bool) public limitedGaveBirth;
    mapping(uint256 => bool) private tokenIdClaimable;
    mapping(uint256 => uint256) private tokenIdStamina;
    mapping(address => Stake) private stakes;
    mapping(uint256 => string) private tokenURIs;
    mapping(uint256 => bool) private cocoonHatched;
    mapping(bytes32 => bool) public usedMessageHashes;

    event LimitedIdsAreSet(uint256[] indexed _Ids);
    event TokenExchanged(address indexed _owner, uint256 indexed _tokenId);
    event MetaDataURIChanged(string indexed _oldURI, string indexed _newURI);
    event SecondMetaDataURIChanged(string indexed _oldURI, string indexed _newURI);
    event TicketPurchased(address indexed _purchaser, uint256 indexed _tokenId, uint256 _purchasedAt);
    event NewCocoonBorn(address _owner, uint256 indexed _id, uint256 indexed _parentA, uint256 indexed _parentB);
    event CocoonHatched(uint256 indexed _tokenId, address _owner);
    event TicketGifted(address indexed to, uint256 _tokenId, uint256 _timestamp);
    event UserStaked(
        address indexed _staker,
        uint256 indexed _TokenA,
        uint256 indexed _TokenB,
        bool _limitedTokenStaked
    );
    event UserUnstaked(
        address indexed _user,
        uint256 indexed _TokenA,
        uint256 indexed _TokenB,
        uint256 _offspringCount,
        bool _limitedTokenStaked
    );

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _secondBaseUri,
        string memory _ticketURI,
        string memory _cocoonURI,
        address _oldNFTContract,
        address _backendAddress,
        uint256 _mintPrice,
        uint256 _maxSupply,
        uint32[] memory _stakingTime,
        uint32[] memory _claimables,
        uint32[] memory _uint256Arr
    ) external initializer {
        __ERC721_init_unchained(_name, _symbol);
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();

        burnAddress = 0x000000000000000000000000000000000000dEaD;
        oldNFTContract = _oldNFTContract;
        backend = _backendAddress;
        baseURI = _ticketURI;
        secondBaseURI = _secondBaseUri;
        cocoonURI = _cocoonURI;
        maxTicketsPerUser = 2;
        extension = ".json";
        price = _mintPrice;
        toBeClaimed = _claimables;
        stakingTime4 = _stakingTime[0];
        stakingTime3 = _stakingTime[1];
        stakingTime2 = _stakingTime[2];
        index = 1001;
        ids = _uint256Arr;
        ticketSale = true;
        maxSupply = _maxSupply;

        maxTicketsPerWallet = 2;

        uint256 i;
        for (i; i < toBeClaimed.length; i++) {
            tokenIdClaimable[toBeClaimed[i]] = true;
            uint256 ind = toBeClaimed[i] - 1;
            ids[ind] = ids[ids.length - 1];
            ids.pop();
        }
    }

    /**
     * @dev Owner function to mint any `_id` to any user.
     * @param _to Address of the receiver.
     * @param _id ID of the token to be minted.
     */
    function mintTo(address _to, uint256 _id) external onlyOwner {
        require(!_exists(_id), "Token with this ID already exists.");
        require(_id < 10000, "There can only be 10,000 NFTs");

        if (_idIsClaimable(_id)) {
            tokenIdClaimable[_id] == false;
            _safeMint(_to, _id);
        } else {
            if (_id < 501) {
                ids[_id - 1] = ids[ids.length - 1];
                ids.pop();
            }
            _safeMint(_to, _id);
        }
    }

    /**
     * @dev Function to switch `revealed` boolean. Depending on that variable
     * different values will be returned by `tokenURI()`.
     */
    function switchRevealed() external onlyOwner {
        revealed = !revealed;
    }

    /**
     * @dev Function to switch `secondRevealed` boolean. Depending on that variable
     * different values will be returned by `tokenURI()`.
     */
    // function switchSecondRevealed() external onlyOwner {
    //     secondRevealed = !secondRevealed;
    // }

    /**
     * @dev Function to switch `ticketSale` boolean. This variable turns on/off `purchaseOldNFT()`.
     */
    function switchTicketSale() external onlyOwner {
        ticketSale = !ticketSale;
    }

    /**
     * @dev Sets new value to `extension`.
     * @param _ext New extension string value.
     */
    function setExtension(string memory _ext) external onlyOwner {
        extension = _ext;
    }

    /**
     * @dev This function burns a NFT with provided `_tokenId`
     * from previous contract and mints a new one on current contract
     * with the same ID.
     * @param _tokenId ID of the token to be exchanged.
     */
    function exchangeOldNFT(uint256 _tokenId) external virtual whenNotPaused {
        address owner = IERC721Upgradeable(oldNFTContract).ownerOf(_tokenId);
        require(
            owner == _msgSender(),
            "You are not the owner of this NFT."
        );
        require(
            _idIsClaimable(_tokenId),
            "This token ID is not claimable."
        );
        require(
            tokenIdClaimable[_tokenId] == true,
            "This token ID is already claimed."
        );
        
        tokenIdClaimable[_tokenId] == false;
        IERC721Upgradeable(oldNFTContract).transferFrom(_msgSender(), burnAddress, _tokenId);
        _safeMint(_msgSender(), _tokenId);
        emit TokenExchanged(_msgSender(), _tokenId);
    }

    /**
     * @dev Function for owner that sets some of the NFT IDs as limited.
     * @param _limitedIds Array of ids that are limited.
     */
    function setIdsAsLimited(uint256[] memory _limitedIds) external virtual onlyOwner {
        require(_limitedIds.length > 0, "No ids were provided.");

        uint i;
        for (i; i < _limitedIds.length; i++) {
            if (isLimited[_limitedIds[i]] != true) {
                isLimited[_limitedIds[i]] = true;
            }
        }
        emit LimitedIdsAreSet(_limitedIds);
        limitedIdsAreSet = true;
    }

    /**
     * @dev Function to switch `limitedIdsAreSet`.
     */
    function switchLimitedIdsAreSet() external virtual onlyOwner {
        limitedIdsAreSet = !limitedIdsAreSet;
    }

    /**
     * @dev Function to set backend address that will be checked as a signer for cocoon hatching.
     */
    function setBackendAddress(address _newBackendAddress) external virtual onlyOwner {
        backend = _newBackendAddress;
    }

    /**
     * @dev External function to check stamina amount of the NFT with given `_tokenId`.
     * @param _tokenId ID of the NFT whose stamina is requested.
     */
    function checkStamina(uint256 _tokenId) external virtual view returns(uint256) {
        return _checkStamina(_tokenId);
    }

    /**
     * @dev Internal function that checks stamina of the NFT with given `_tokenId`.
     * @param _tokenId ID of the NFT whose stamina is requested.
     */
    function _checkStamina(uint256 _tokenId) internal virtual view returns(uint256) {
        require(
            _exists(_tokenId),
            "This token ID do not exist."
        );

        return tokenIdStamina[_tokenId];
    }

    /**
     * @dev Function to purchase a ticket/NFT.
     * @notice An address can not hold more than 2 tokens at a time.
     */
    function purchaseTicket(uint256 _amount) external payable virtual whenNotPaused nonReentrant{
        require(ticketSale, "Ticket sale is over.");
        _purchaseChecks(_amount, _msgSender());
        require(_amount == 1 || _amount == 2, "You can only purchase 1 or 2 tickets.");
        uint256 _price = _amount == 1 ? price : price * 2;
        require(msg.value >= _price, "Not enought ETH provided to pay for mint.");

        uint256 i;
        uint256 id;
        
        for (i; i < _amount; i++) {
            id = _getRandomId();
            _safeMint(_msgSender(), id);
            emit TicketPurchased(_msgSender(), id, block.timestamp);
        }

        if (msg.value > _price) {
            (bool success, )= _msgSender().call{value: msg.value - _price}("");
            require(success, "Error while returning extra ETH");
        }

        if (ids.length == 0) {
            ticketSale = false;
        }
    }

    // function startSecondSaleRound() external onlyOwner {
        // set `ids` as a new array of 500 items starting with 501.
        // This array will serve as available indexes for NFTs that will be sold.
    // }

    /**
     * @dev OnlyOwner function to gift someone a ticket.
     * @param _to Address to which a ticket will be gifted.
     */
    function giftTicket(address _to, uint256 _amount) external virtual onlyOwner nonReentrant{
        require(ticketSale, "Ticket sale is over.");
        _purchaseChecks(_amount, _to);

        uint256 i;
        uint256 id;

        for (i; i < _amount; i++) {
            id = _getRandomId();
            _safeMint(_to, id);
            emit TicketGifted(_to, id, block.timestamp);
        }

        if (ids.length == 0) {
            ticketSale = false;
        }
    }

    /**
     * @dev Function to switch start staking boolean. Available only to owner.
     */
    function switchStaking() external virtual onlyOwner {
        stakingStarted = !stakingStarted;
    }

    /**
     * @dev Function to set new baseURI.
     * @param _uri New base URI string.
     */
    function setBaseTokenURI(string memory _uri) external virtual onlyOwner {
        baseURI = _uri;
    }

    /**
     * @dev Function to set new secondBaseURI.
     * @param _uri New second base URI string.
     */
    function setSecondBaseTokenURI(string memory _uri) external virtual onlyOwner {
        secondBaseURI = _uri;
    }

    /**
     * @dev Function to reveal metadata for tokens with ids 1 - 500.
     * @param _uri New URI string.
     */
    function revealMetadataURI(string memory _uri) external virtual onlyOwner {
        require(!revealed, "Revealing can happen only once.");
        string memory oldUri = baseURI;
        baseURI = _uri;
        revealed = true;

        emit MetaDataURIChanged(oldUri, _uri);
    }

    /**
     * @dev Function to reveal metadata for tokens with ids 501 - 1000.
     * @param _uri New URI string.
     */
    function revealSecondMetadataURI(string memory _uri) external virtual onlyOwner {
        require(!secondRevealed, "Revealing can happen only once.");
        string memory oldUri = secondBaseURI;
        secondBaseURI = _uri;
        secondRevealed = true;

        emit SecondMetaDataURIChanged(oldUri, _uri);
    }

    /**
     * @dev Function to get URI of a token/NFT with given `tokenId`.
     * @param tokenId ID of the requested token.
     * @notice Will return an empty string if base URI is not yet set.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721Upgradeable, IWormForm) returns(string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory _baseUri;

        // if (tokenId < 1001) {
        if (tokenId < 501) {
            _baseUri = _baseURI();
            if (!revealed) {
                return bytes(_baseUri).length > 0 ? string(abi.encodePacked(_baseUri)) : "";
            } else {
                return bytes(_baseUri).length > 0 ? string(abi.encodePacked(_baseUri, tokenId.toString(), extension)) : "";
            }
        // } else {
        } else if (tokenId < 1001) {
            _baseUri = _secondBaseURI();
            if (!secondRevealed) {
                return bytes(_baseUri).length > 0 ? string(abi.encodePacked(_baseUri)) : "";
            } else {
                return bytes(_baseUri).length > 0 ? string(abi.encodePacked(_baseUri, tokenId.toString(), extension)) : "";
            }
        } else if (tokenId > 1000) {
            if (!cocoonHatched[tokenId]) return string(abi.encodePacked(cocoonURI));
            else return tokenURIs[tokenId];
        } else return secondBaseURI;
    }

    /**
     * @dev Returns cocoon URI.
     */
    function getCocoonURI() external view virtual returns(string memory) {
        return cocoonURI;
    }

    /**
     * @dev Sets new URI string for cocoon.
     * @param _cocoonURI New cocoon URI string.
     */
    function setCocoonURI(string memory _cocoonURI) external virtual onlyOwner {
        cocoonURI = _cocoonURI;
    }

    /**
     * @dev Base URI for computing tokenURI.
     */
    function _baseURI() internal view virtual override returns(string memory) {
        return baseURI;
    }

    /**
     * @dev Second base URI for computing tokenURI.
     */
    function _secondBaseURI() internal view virtual returns(string memory) {
        return secondBaseURI;
    }

    /**
     * @dev Function to stake two tokens.
     * @param _ATokenId First parent token ID.
     * @param _BTokenId Second parent token ID.
     */
    function stakeToBreed(uint256 _ATokenId, uint256 _BTokenId) external virtual whenNotPaused nonReentrant{
        Stake storage stake = stakes[_msgSender()];
        bool limitedTokenStaked;

        require(_exists(_ATokenId), "Token A does not exist.");
        require(_exists(_BTokenId), "Token B does not exist.");
        require(limitedIdsAreSet, "Breeding can only start when limited ids are set.");
        require(!ticketSale, "Ticket sale must end.");
        require(stakingStarted, "Staking has not started.");
        require(!stake.staked, "User is already breeding.");
        if (isLimited[_ATokenId]) {
            require(!limitedGaveBirth[_ATokenId], "Limited token has already gave birth.");
            limitedTokenStaked = true;
        }
        if (isLimited[_BTokenId]) {
            require(!limitedGaveBirth[_BTokenId], "Limited token has already gave birth.");
            if (!limitedTokenStaked) limitedTokenStaked = true;
        }
        require(
            ownerOf(_ATokenId) == _msgSender() &&
            ownerOf(_BTokenId) == _msgSender(),
            "One of the token IDs do not belong to the caller."
        );
        require(
            _checkStamina(_ATokenId) != 0 &&
            _checkStamina(_BTokenId) != 0,
            "One of thetoken ID's stamina is 0."
        );

        stake.staked = true;
        stake.stakedAt = block.timestamp;
        stake.stakedIds.push(_ATokenId);
        stake.stakedIds.push(_BTokenId);

        _safeTransfer(_msgSender(), address(this), _ATokenId, "");
        _safeTransfer(_msgSender(), address(this), _BTokenId, "");

        emit UserStaked(_msgSender(), _ATokenId, _BTokenId, limitedTokenStaked);
    }

    /**
     * @dev Function to unstake tokens from breeding. It distributes
     * cocoons according to quality of parents, stamin amount and time staked.
     */
    function unstakeFromBreeding() external virtual nonReentrant whenNotPaused {
        Stake storage stake = stakes[_msgSender()];
        require(stake.staked, "Nothing is staked by this user.");

        uint256 tokenA = stake.stakedIds[0];
        uint256 tokenB = stake.stakedIds[1];

        uint256 totalStamina = _checkStamina(tokenA) + _checkStamina(tokenB);
        uint256 timePassed = block.timestamp - stake.stakedAt;
        uint256 offspringCount;
        bool limitedTokenStaked;

        if (isLimited[tokenA]) {
            limitedGaveBirth[tokenA] = true;
            limitedTokenStaked = true;
        }
        if (isLimited[tokenB]) {
            limitedGaveBirth[tokenB] = true;
            if (!limitedTokenStaked) limitedTokenStaked = true;
        }

        if (limitedTokenStaked) {
            if (totalStamina == 4) if (timePassed >= stakingTime4) offspringCount = 1;
            if (totalStamina == 3) if (timePassed >= stakingTime3) offspringCount = 1;
        } else {
            if (totalStamina == 4) {
                if (timePassed >= stakingTime4 + stakingTime2) offspringCount = 2;
                else if (timePassed >= stakingTime4) offspringCount = 1;
            }
            if (totalStamina == 3) if (timePassed >= stakingTime3) offspringCount = 1;
            if (totalStamina == 2) if (timePassed >= stakingTime2) offspringCount = 1;
        }

        if (offspringCount > 0) {
            if (offspringCount == 2) {
                tokenIdStamina[tokenA] = 0;
                tokenIdStamina[tokenB] = 0;
            } else {
                tokenIdStamina[tokenA]--;
                tokenIdStamina[tokenB]--;
            }

            uint i;
            for (i; i < offspringCount; i++) {
                uint256 id = _getNextIndex();

                _safeMint(_msgSender(), id);
                emit NewCocoonBorn(_msgSender(), id, tokenA, tokenB);
            }
        }

        stake.staked = false;
        stake.stakedAt = 0;
        stake.stakedIds.pop();
        stake.stakedIds.pop();

        _safeTransfer(address(this), _msgSender(), tokenA, "");
        _safeTransfer(address(this), _msgSender(), tokenB, "");

        emit UserUnstaked(_msgSender(), tokenA, tokenB, offspringCount, limitedTokenStaked);
    }

    /**
     * @dev Function to hatch the cocoon and set it's token URI.
     * @param _tokenId Token ID of the cocoon to be hatched.
     * @param _uri URI string to be set for a given cocoon ID.
     * @param _hash Hashed message to test signature against.
     * @param _signature Signature derived from sigining the message.
     */
    function hatchCocoon(uint256 _tokenId, string memory _uri, bytes32 _hash, bytes memory _signature) external virtual whenNotPaused {
        require(_tokenId >= 1001, "IDs lower than tickets amount are not cocoons.");
        require(!cocoonHatched[_tokenId], "Cocoon has already hatched.");
        require(usedMessageHashes[_hash] == false, "Message hash is already used.");
        require(_isSignedByBackend(_hash, _signature), "Message must be signed by backend.");

        usedMessageHashes[_hash] = true;
        cocoonHatched[_tokenId] = true;
        tokenURIs[_tokenId] = _uri;

        emit CocoonHatched(_tokenId, _msgSender());

    }

    /**
     * @dev Function that returns stake status, time at whicg stake occured and staked toke IDs.
     * @param _user Address of the user whose stake is requested.
     * @return _isStaked Bool representing whether user is currently staking.
     * @return _tokenA Token ID of token A.
     * @return _tokenB Token ID of token B.
     * @return _stakedAt Timestamp at which stake occured.
     */
    function getUserStakeInfo(address _user) external view virtual returns(
        bool _isStaked,
        uint256 _tokenA,
        uint256 _tokenB,
        uint256 _stakedAt
    ) {
        Stake storage stake = stakes[_user];
        // require(stake.staked == true, "User does not stake.");

        _isStaked = stake.staked;
        _stakedAt = stake.stakedAt;

        if (stake.staked) {
            _tokenA = stake.stakedIds[0];
            _tokenB = stake.stakedIds[1];
        } else {
            _tokenA = 0;
            _tokenB = 0;
        }

    }

    /**
     * @dev Function for owner to withdraw collected ETH.
     */
    function withdraw() external payable onlyOwner {
        require(address(this).balance != 0, "Nothing to withdraw.");

        (bool success, )= _msgSender().call{value: address(this).balance}("");
        require(success, "Error while withdrawing ETH.");
    }

    /**
     * @dev Function to pause the contract.
     */
    function pause() external virtual onlyOwner {
        _pause();
    }

    /**
     * @dev Function to unpause the contract.
     */
    function unpause() external virtual onlyOwner {
        _unpause();
    }

    /**
     * @dev Function that returns amount of tickets left.
     */
    function ticketsLeft() external view virtual returns(uint256) {
        return ids.length;
    }

    /** TO BE DELETED */
    function changeTokenStamina(uint256 _id, uint256 _stamina) external onlyOwner {
        tokenIdStamina[_id] = _stamina;
    }

    /**
     * @dev Mint function that also sets stamina for the token with
     * provided `tokenId`.
     * @param to Address that will receive minted NFT.
     * @param tokenId ID of the minted token.
     */
    function _mint(address to, uint256 tokenId) internal virtual override {
        require(totalSupply <= maxSupply, "Maximum supply is reached.");
        super._mint(to, tokenId);
        tokenIdStamina[tokenId] = 2;
        totalSupply++;
    }

    /**
     * @dev Internal function that returns a pseudo random ID from `ids` array.
     */
    function _getRandomId() private returns(uint256) {
        uint256 pseudoRandNum = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, ids.length)));
        uint256 i =  pseudoRandNum % (ids.length);
        uint256 id = ids[i];
        ids[i] = ids[ids.length - 1];
        require(ids.length > 0, "Underflow if `_getRandomId()`");
        ids.pop();
        return id;
    }

    /**
        @dev Internal function that checks if signature was created by the correct address.
        @param _hash Mesage hash.
        @param _signature Signature of the backend address.
     */
    function _isSignedByBackend(bytes32 _hash, bytes memory _signature) internal view returns(bool) {
        address signer = _recoverSigner(_hash, _signature);
        return signer == backend;
    }
    
    /**
        @dev Internal function that checks that recovers the signer of the message.
        @param _hash Mesage hash.
        @param _signature Signature of the backend address.
     */
    function _recoverSigner(bytes32 _hash, bytes memory _signature) internal pure returns(address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", 
                _hash
            )
        );
        return ECDSAUpgradeable.recover(messageDigest, _signature);
    }

    /**
     * @dev Returns next available index strating from 1001 up to 9999.
     */
    function _getNextIndex() internal virtual returns(uint256) {
        uint256 id;
        do {
            if(!_exists(index)) {
                id = index++;
            } else index++;
        } while(id == 0);
        return id;
    }

    // function 
    
    function changeOldNFTContract(address _new) external onlyOwner {
        oldNFTContract = _new;
    }

    /**
     * @dev Checks whether a token with given `_id` can be claimed from old contract.
     * @param _id The ID of the token to be claimed.
     */
    function _idIsClaimable(uint256 _id) internal virtual returns(bool) {
        uint i;
        bool claimable_;
        for (i; i < toBeClaimed.length; i++) {
            if(toBeClaimed[i] == _id) {
                claimable_ = true;
                return claimable_;
            }
        }
        return claimable_;
    }

    function _purchaseChecks(uint256 _amount, address _to) private view {
        if (_amount == 1) require(ids.length > 0, "All tokens were minted.");
        if (_amount == 2) require(ids.length > 1, "Only 1 more token is available.");
        require(
            balanceOf(_to) + 
            ERC721Upgradeable(oldNFTContract).balanceOf(_to) + 
            _amount <= maxTicketsPerWallet,
            "You can only get 2 NFTs."
        );
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}
}