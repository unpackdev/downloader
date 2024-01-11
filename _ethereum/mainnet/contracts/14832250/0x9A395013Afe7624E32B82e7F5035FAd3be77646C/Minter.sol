// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**************************************

    security-contact:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io

**************************************/

// OpenZeppelin
import "./Ownable.sol";
import "./Address.sol";

// Local
import "./IAbNFT.sol";
import "./Configurable.sol";

/**************************************

    Minter for AB NFT

 **************************************/

contract Minter is Ownable, Configurable {

    // using
    using Address for address payable;

    // enum
    enum RevealAction {
        FOLLOW, // pass unsold nfts to next batch
        CLAIM // mint not sold NFTs in batch to owner
    }
    enum BatchState {
        BLIND,
        REVEALED
    }

    // constants
    uint256 public constant TOTAL_SUPPLY_LIMIT = 6900;
    uint256 public constant INITIAL_MINT = 50;
    uint256 public constant MIN_BATCH_PRICE = 0.001 ether;

    // structs
    struct MintingBatch {
        uint256 mintingDate;
        uint256 mintingCap;
        uint256 mintingPrice;
        RevealAction actionWhenReveal;
        BatchState state;
    }

    // contracts
    IAbNFT public immutable nftContract;
    address public vesting;

    // storage
    uint256 public mintLimitPerWallet;
    uint256 public immutable totalBatches;
    MintingBatch[] public mintingBatches;
    mapping (address => uint256) public minted;

    // errors
    error MintingLimitReached(uint256 alreadyMinted, uint256 toMint, uint256 mintLimit);
    error MintingNotStarted(uint256 mintingBatch);
    error MintingAboveSupply(uint256 nftSupply, uint256 toMint, uint256 supplyLimit);
    error BatchLimitReached(uint256 totalBatches);
    error NotEnoughNFTAvailableToMint(uint256 toMint, uint256 available);
    error AlreadyInitialised();
    error InvalidPayment(address owner, uint256 value, uint256 numberToMint);
    error AlreadyRevealed(uint256 batchNo);
    error NotYetRevealed();
    error NothingToWithdraw();
    error MintingDateNotInFuture(uint256 mintingDate, uint256 timeNow);
    error InvalidMintingCap();
    error BatchNotStarted(uint256 batchNo);
    error InvalidPriceForBatch(uint256 price);

    // events
    event NewBatchAdded(MintingBatch batch);
    event RevealActionPerformed(uint256 batchNo, RevealAction action);
    event Withdrawal(address owner, uint256 amount);

    /**************************************
    
        Constructor

     **************************************/

    constructor(
        address _abNFT,
        address _vesting,
        uint256 _mintLimitPerWallet,
        uint256 _totalBatches,
        MintingBatch memory _firstBatch
    )
    Ownable() {
        
        // nft contract
        nftContract = IAbNFT(_abNFT);

        // vesting
        vesting = _vesting;

        // mint limit per wallet
        mintLimitPerWallet = _mintLimitPerWallet;

        // batch size
        totalBatches = _totalBatches;

        // batch
        mintingBatches.push(_firstBatch);

        // event
        emit Initialised(abi.encode(
            _abNFT,
            _vesting,
            _mintLimitPerWallet,
            _totalBatches,
            _firstBatch
        ));

    }

    /**************************************

        Set as configured

     **************************************/

    function setConfigured() public virtual override
    onlyInState(State.UNCONFIGURED)
    onlyOwner {

        // tx.members
        address owner_ = msg.sender;

        // batch mint
        nftContract.mint(_prepMint(INITIAL_MINT), owner_);

        // super
        super.setConfigured();

        // event
        emit Configured(abi.encode(
            msg.sender,
            INITIAL_MINT
        ));

    }

    /**************************************

        Add new batch

     **************************************/

    function addNewBatch(MintingBatch calldata _batch) external
    onlyOwner {

        // tx.members
        uint256 now_ = block.timestamp;

        // check if under limit
        if (mintingBatches.length + 1 > totalBatches) {
            revert BatchLimitReached(totalBatches);
        }

        // check if date in future
        if (_batch.mintingDate <= now_) {
            revert MintingDateNotInFuture(_batch.mintingDate, now_);
        }

        // check minting size
        if (_batch.mintingCap == 0) {
            revert InvalidMintingCap();
        }

        // check minting price
        if (_batch.mintingPrice < MIN_BATCH_PRICE) {
            revert InvalidPriceForBatch(_batch.mintingPrice);
        }

        // storage
        mintingBatches.push(_batch);

        // event
        emit NewBatchAdded(_batch);

    }

    /**************************************

        Get batch count

     **************************************/

    function getActiveBatchCount() external view
    returns (uint256) {

        // return
        return mintingBatches.length;

    }

    /**************************************

        Get latest batch

     **************************************/

    function getLatestBatch() public view
    returns (int256) {

        // tx.members
        uint256 now_ = block.timestamp;

        // loop through batches from end
        for (uint256 i = mintingBatches.length; i > 0; i--) {

            // return if already started
            if (now_ >= mintingBatches[i - 1].mintingDate) return int256(i - 1);

        }

        // no active batch yet
        return -1;

    }

    /**************************************

        Get latest active batch

     **************************************/

    function getLatestActiveBatch() public view
    returns (uint256) {

        // get latest batch
        int256 batchNo_ = getLatestBatch();

        // check latest batch number
        if (batchNo_ < 0) revert MintingNotStarted(0);

        // return
        return uint256(batchNo_);

    }

    /**************************************
    
        Get time left to next batch

     **************************************/

    function getTimeLeft() external view
    returns (uint256) {

        // tx.members
        uint256 now_ = block.timestamp;

        // length
        uint256 length_ = mintingBatches.length;

        // loop through batches
        for (uint256 i = 0; i < length_; i++) {

            // batch from start
            MintingBatch memory batch_ = mintingBatches[i];
            if (batch_.mintingDate > now_) return batch_.mintingDate - now_;

        }

        // return
        return 0;

    }

    /**************************************

        Get tokens left in current batch

     **************************************/

    function getTokensLeftInLatestBatch() public view
    returns (uint256) {

        // batch number
        int256 batchNo_ = getLatestBatch();

        // check batch number
        if (batchNo_ >= 0) {

            return getTokensLeftInBatch(uint256(batchNo_));

        }

        // return
        return 0;

    }

    /**************************************

        Get tokens left in specified batch

     **************************************/

    function getTokensLeftInBatch(uint256 _batchNo) public view
    returns (uint256) {

        // batch
        MintingBatch memory batch_ = mintingBatches[_batchNo];

        // supply
        uint256 currentSupply_ = nftContract.totalSupply();

        // return tokens left
        if (currentSupply_ >= batch_.mintingCap) return 0;
        else return batch_.mintingCap - currentSupply_;

    }

    /**************************************

        Get tokens left to mint

     **************************************/

    function getTokensLeft() external view
    returns (uint256) {

        // return
        return TOTAL_SUPPLY_LIMIT - nftContract.totalSupply();

    }

    /**************************************
    
        Mint new NFT

     **************************************/

    function mint(uint256 _numberToMint) external payable
    onlyInState(State.CONFIGURED) {

        // tx.members
        address owner_ = msg.sender;

        // assert
        _assertMint(_numberToMint);

        // storage
        minted[owner_] += _numberToMint;

        // mint
        nftContract.mint(_prepMint(_numberToMint), owner_);

    }

    /**************************************

        Internal: assert for public mint

     **************************************/

    function _assertMint(uint256 _numberToMint) internal view {

        // tx.members
        address owner_ = msg.sender;
        uint256 value_ = msg.value;

        // get latest batch
        uint256 batchNo_ = getLatestActiveBatch();
        
        // batch
        MintingBatch memory batch_ = mintingBatches[batchNo_];

        // check if batch not revealed
        if (batch_.state == BatchState.REVEALED) {
            revert AlreadyRevealed(batchNo_);
        }

        // check if tokens can be minted
        uint256 availableToMint_ = getTokensLeftInBatch(batchNo_);
        if (_numberToMint > availableToMint_) {
            revert NotEnoughNFTAvailableToMint(
                _numberToMint,
                availableToMint_
            );
        }

        // check funds
        if (value_ != _numberToMint * batch_.mintingPrice) {
            revert InvalidPayment(
                owner_,
                value_,
                _numberToMint
            );
        }

        // check nft supply
        uint256 nftSupply_ = nftContract.totalSupply();
        if (nftSupply_ + _numberToMint > TOTAL_SUPPLY_LIMIT) {
            revert MintingAboveSupply(
                nftSupply_,
                _numberToMint,
                TOTAL_SUPPLY_LIMIT
            );
        }

        // check limit for minting
        if (minted[owner_] + _numberToMint > mintLimitPerWallet) {
            revert MintingLimitReached(
                minted[owner_],
                _numberToMint,
                mintLimitPerWallet
            );
        }

    }

    /**************************************

        Internal: prep mint

     **************************************/

    function _prepMint(uint256 _numberToMint) internal view returns (uint256[] memory) {

        // alloc
        uint256[] memory toBeMinted_ = new uint256[](_numberToMint);

        // supply
        uint256 totalSupply_ = nftContract.totalSupply();

        // populate
        for (uint256 i = 0; i < _numberToMint; i++) {
            toBeMinted_[i] = totalSupply_ + i;
        }

        // return
        return toBeMinted_;

    }

    /**************************************

        Reveal

     **************************************/

    function reveal(
        uint256 _batchNo,
        string memory _revealedURI
    ) external
    onlyInState(State.CONFIGURED)
    onlyOwner {

        // get latest batch
        uint256 batchNo_ = getLatestActiveBatch();

        // check if batch started
        if (batchNo_ < _batchNo) revert BatchNotStarted(_batchNo);

        // batch
        MintingBatch storage batch_ = mintingBatches[_batchNo];

        // check if not revealed
        if (batch_.state == BatchState.REVEALED) {
            revert AlreadyRevealed(_batchNo);
        }

        // claim
        uint256 toVest_ = 0;

        // check if there are tokens in batch
        uint256 tokensLeft_ = getTokensLeftInBatch(_batchNo);

        // check if there are remaining NFTs
        if (tokensLeft_ > 0) {

            // decrease available tokens for mint
            batch_.mintingCap -= tokensLeft_;

            // check action on reveal
            if (batch_.actionWhenReveal == RevealAction.CLAIM) {

                // move tokens to vesting
                toVest_ += tokensLeft_;

            }

        }

        // storage
        batch_.state = BatchState.REVEALED;

        // fallback to total supply if latest batch
        uint256 cap_ = batch_.mintingCap;
        if (_batchNo == totalBatches - 1) {
            cap_ = TOTAL_SUPPLY_LIMIT;
        }

        // reveal
        nftContract.reveal(
            cap_,
            _revealedURI,
            toVest_
        );

        // event
        emit RevealActionPerformed(
            batchNo_,
            batch_.actionWhenReveal
        );

    }

    /**************************************

        Vested claim NFT

     **************************************/

    function vestedClaim(uint256 _numberToMint) external
    onlyInState(State.CONFIGURED)
    onlyOwner {

        // claim
        nftContract.vestedClaim(_prepMint(_numberToMint), vesting);

    }

    /**************************************

        Withdraw

     **************************************/

    function withdraw() external
    onlyInState(State.CONFIGURED)
    onlyOwner {

        // tx.members
        address sender_ = msg.sender;
        uint256 balance_ = address(this).balance;

        // check balance
        if (balance_ == 0) {
            revert NothingToWithdraw();
        }

        // withdraw
        payable(sender_).sendValue(balance_);

        // event
        emit Withdrawal(sender_, balance_);

    }

}
