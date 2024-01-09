// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
// import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";


import "./IFleet.sol";
import "./ICACAO.sol";
import "./IPnG.sol";

import "./Accessable.sol";
import "./Wnitelist.sol";


contract PirateGame is Accessable, Whitelist, ReentrancyGuard, Pausable {

    event MintCommitted(address indexed owner, uint256 indexed amount);
    event MintRevealed(address indexed owner, uint256 indexed amount);

    //$CACAO cost 
    uint256[3] private _cacaoCost = [20000 ether, 40000 ether, 80000 ether];
    uint16 public maxBunchSize = 10;

    bool public allowCommits = true;

    bool public isWhitelistSale = true;
    bool public isPublicSale = false;
    uint256 public presalePrice = 0.06 ether;
    uint256 public treasureChestTypeId;


    uint256 public startedTime = 0;

    uint256 private maxPrice = 0.3266 ether;
    uint256 private minPrice = 0.0666 ether;
    uint256 private priceDecrementAmt = 0.01 ether;
    uint256 private timeToDecrementPrice = 30 minutes;



    mapping(address => uint16) public whitelistMinted;
    uint16 public whitelistAmountPerUser = 5;

    struct MintCommit {
        bool exist;
        uint16 amount;
        uint256 blockNumber;
        bool stake;
    }
    mapping(address => MintCommit) private _mintCommits;
    uint16 private _commitsAmount;

    struct MintCommitReturn {
        bool exist;
        bool notExpired;
        bool nextBlockReached;
        uint16 amount;
        uint256 blockNumber;
        bool stake;
    }


    IFleet public fleet;
    ICACAO public cacao;
    IPnG public nftContract;



    constructor() {
        _pause();
    }

    /** CRITICAL TO SETUP */

    function setContracts(address _cacao, address _nft, address _fleet) external onlyAdmin {
        cacao = ICACAO(_cacao);
        nftContract = IPnG(_nft);
        fleet = IFleet(_fleet);
    }



    function currentEthPriceToMint() view public returns(uint256) {        
        uint16 minted = nftContract.minted();
        uint256 paidTokens = nftContract.getPaidTokens();

        if (minted >= paidTokens) {
            return 0;
        }
        
        uint256 numDecrements = (block.timestamp - startedTime) / timeToDecrementPrice;
        uint256 decrementAmt = (priceDecrementAmt * numDecrements);
        if(decrementAmt > maxPrice) {
            return minPrice;
        }
        uint256 adjPrice = maxPrice - decrementAmt;
        return adjPrice;
    }

    function whitelistPrice() view public returns(uint256) {
        uint16 minted = nftContract.minted();
        uint256 paidTokens = nftContract.getPaidTokens();

        if (minted >= paidTokens) {
            return 0;
        }
        return presalePrice;
    }


    function avaliableWhitelistTokens(address user, bytes32[] memory whitelistProof) external view returns (uint256) {
        if (!inWhitelist(user, whitelistProof) || !isWhitelistSale)
            return 0;
        return whitelistAmountPerUser - whitelistMinted[user];
    }


    function mintCommitWhitelist(uint16 amount, bool isStake, bytes32[] memory whitelistProof) 
        external payable
        nonReentrant
        publicSaleStarted
    {   
        require(isWhitelistSale, "Whitelist sale disabled");
        require(whitelistMinted[_msgSender()] + amount <= whitelistAmountPerUser, "Too many mints");
        require(inWhitelist(_msgSender(), whitelistProof), "Not in whitelist");
        whitelistMinted[_msgSender()] += amount;
        return _commit(amount, isStake, presalePrice);
    }

    function mintCommit(uint16 amount, bool isStake) 
        external payable 
        nonReentrant
        publicSaleStarted
    {
        return _commit(amount, isStake, currentEthPriceToMint());
    }

    function _mintCommitAirdrop(uint16 amount) 
        external payable 
        nonReentrant
        onlyAdmin
    {
        return _commit(amount, false, 0);
    }


    function _commit(uint16 amount, bool isStake, uint256 price) internal
        whenNotPaused 
        onlyEOA
        commitsEnabled
    {
        require(amount > 0 && amount <= maxBunchSize, "Invalid mint amount");
        require( !_hasCommits(_msgSender()), "Already have commit");

        uint16 minted = nftContract.minted() + _commitsAmount;
        uint256 maxTokens = nftContract.getMaxTokens();
        require( minted + amount <= maxTokens, "All tokens minted");

        uint256 paidTokens = nftContract.getPaidTokens();

        if (minted < paidTokens) {
            require(minted + amount <= paidTokens, "All tokens on-sale already sold");
            uint256 price_ = amount * price;
            require(msg.value >= price_, "Invalid payment amount");

            if (msg.value > price_) {
                payable(_msgSender()).transfer(msg.value - price_);
            }
        } 
        else {
            require(msg.value == 0, "");
            uint256 totalCacaoCost = 0;
             // YCDB
            for (uint16 i = 1; i <= amount; i++) {
                totalCacaoCost += mintCost(minted + i, maxTokens);
            }
            if (totalCacaoCost > 0) {
                cacao.burn(_msgSender(), totalCacaoCost);
                cacao.updateInblockGuard();
            }           
        }

        _mintCommits[_msgSender()] = MintCommit(true, amount, block.number, isStake);
        _commitsAmount += amount;
        emit MintCommitted(_msgSender(), amount);
    }


    function mintReveal() external 
        whenNotPaused 
        nonReentrant 
        onlyEOA
    {
        return reveal(_msgSender());
    }

    function _mintRevealAirdrop(address _to)  external
        whenNotPaused 
        nonReentrant
        onlyAdmin
        onlyEOA
    {
        return reveal(_to);
    }


    function reveal(address addr) internal {
        require(_hasCommits(addr), "No pending commit");
        uint16 minted = nftContract.minted();
        uint256 paidTokens = nftContract.getPaidTokens();
        MintCommit memory commit = _mintCommits[addr];

        uint16[] memory tokenIds = new uint16[](commit.amount);
        uint16[] memory tokenIdsToStake = new uint16[](commit.amount);

        uint256 seed = uint256(blockhash(commit.blockNumber));
        for (uint k = 0; k < commit.amount; k++) {
            minted++;
            // scramble the random so the steal / treasure mechanic are different per mint
            seed = uint256(keccak256(abi.encode(seed, addr)));
            address recipient = selectRecipient(seed, minted, paidTokens);
            tokenIds[k] = minted;
            if (!commit.stake || recipient != addr) {
                nftContract.mint(recipient, seed);
            } else {
                nftContract.mint(address(fleet), seed);
                tokenIdsToStake[k] = minted;
            }
        }
        // nftContract.updateOriginAccess(tokenIds);
        if(commit.stake) {
            fleet.addManyToFleet(addr, tokenIdsToStake);
        }

        _commitsAmount -= commit.amount;
        delete _mintCommits[addr];
        emit MintRevealed(addr, tokenIds.length);
    }



    /** 
     * @param tokenId the ID to check the cost of to mint
     * @return the cost of the given token ID
     */
    function mintCost(uint256 tokenId, uint256 maxTokens) public view returns (uint256) {
        if (tokenId <= nftContract.getPaidTokens()) return 0;
        if (tokenId <= maxTokens * 2 / 5) return _cacaoCost[0];
        if (tokenId <= maxTokens * 4 / 5) return _cacaoCost[1];
        return _cacaoCost[2];
    }





    /** ADMIN */

    function _setPaused(bool _paused) external requireContractsSet onlyAdmin {
        if (_paused) _pause();
        else _unpause();
    }

    function _setCacaoCost(uint256[3] memory costs) external onlyAdmin {
        _cacaoCost = costs;
    }

    function _setAllowCommits(bool allowed) external onlyAdmin {
        allowCommits = allowed;
    }

    function _setPublicSaleStart(bool started) external onlyAdmin {
        isPublicSale = started;
        if(isPublicSale) {
            startedTime = block.timestamp;
        }
    }

    function setWhitelistSale(bool isSale) external onlyAdmin {
        isWhitelistSale = isSale;
    }

    function _setMaxBunchSize(uint16 size) external onlyAdmin {
        maxBunchSize = size;
    }

    function _setWhitelistAmountPerUser(uint16 amount) external onlyAdmin {
        whitelistAmountPerUser = amount;
    }

    function _cancelCommit(address user) external onlyAdmin {
        _commitsAmount -= _mintCommits[user].amount;
        delete _mintCommits[user];
    }



    /************************************* */


    /**
     * the first 20% (ETH purchases) go to the minter
     * the remaining 80% have a 10% chance to be given to a random staked pirate
     * @param seed a random value to select a recipient from
     * @return the address of the recipient (either the minter or the Pirate thief's owner)
     */
    function selectRecipient(uint256 seed, uint256 minted, uint256 paidTokens) internal view returns (address) { //TODO
        if (minted <= paidTokens || ((seed >> 245) % 10) != 0) // top 10 bits haven't been used
            return _msgSender(); 

        address thief = address(fleet) == address(0) ? address(0) : fleet.randomPirateOwner(seed >> 144); // 144 bits reserved for trait selection
        if (thief == address(0)) 
            return _msgSender();
        else
            return thief;
    }



    /**----------------------------- */

    function getTotalPendingCommits() external view returns (uint256) {
        return _commitsAmount;
    }

    function getCommit(address addr) external view returns (MintCommitReturn memory) {
        MintCommit memory m = _mintCommits[addr];
        (bool ex, bool ne, bool nb) = _commitStatus(m);
        return MintCommitReturn(ex, ne, nb, m.amount, m.blockNumber, m.stake);
    }

    function hasMintPending(address addr) external view returns (bool) {
        return _hasCommits(addr);
    }

    function canMint(address addr) external view returns (bool) {
        return _hasCommits(addr);
    }



    function _hasCommits(address addr) internal view returns (bool) {
        MintCommit memory m = _mintCommits[addr];
        (bool a, bool b, bool c) = _commitStatus(m);
        return a && b && c;
    }

    function _commitStatus(MintCommit memory m) 
        internal view 
        returns (bool exist, bool notExpired, bool nextBlockReached) 
    {        
        exist = m.blockNumber != 0;
        notExpired = blockhash(m.blockNumber) != bytes32(0);
        nextBlockReached = block.number > m.blockNumber;
    }




    /**
     * allows owner to withdraw funds from minting
     */
    function _withdrawAll() external onlyTokenClaimer {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function _withdraw(uint256 amount) external onlyTokenClaimer {
        payable(_msgSender()).transfer(amount);
    }



    modifier requireContractsSet() {
        require(
            address(cacao) != address(0) && address(nftContract) != address(0) && address(fleet) != address(0),
            "Contracts not set"
        );
        _;
    }

    modifier onlyEOA() {
        require(_msgSender() == tx.origin, "Only EOA");
        _;
    }

    modifier commitsEnabled() {
        require(allowCommits, "Adding minting commits disalolwed");
        _;
    }

    modifier publicSaleStarted() {
        require(isPublicSale, "Public sale not started yet");
        _;
    }
}