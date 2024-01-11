// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IHyewonNft.sol";

contract HyewonNft is IHyewonNft, ERC721A, Ownable, ReentrancyGuard, Pausable {
    /**
     * Maximum number of supply
     */
    uint256 public maximumSupply;

    /**
     *  To make token uri immutable permanently
     */
    bool public permanent;

    /**
     *  Minting rounds
     */
    mapping(uint16 => Round) rounds;

    uint256 public revealBlockOffset = 3000;

    /**
     *  Record how many tokens claimed for each whitelist
     */
    mapping(uint16 => mapping(address => uint16)) whitelists;

    /**
     *  Current round number
     */
    uint16 public currentRoundNumber;

    address private _receiver;
    address private _signer;

    /**
     * Base uri for token uri
     */
    string public baseURI;

    /**
     * Default unrevealed uri
     */
    string private defaultUnrevealedURI;

    /**
     * Modifier for onlyOwnerAndAdmin
     * Each round could have different admin
     */
    modifier onlyOwnerOrAdmin(uint16 roundNumber) {
        Round memory r = rounds[roundNumber];

        address admin = rounds[roundNumber].admin;

        if (admin == address(0)) {
            revert BadRequest("Not allowed address");
        }

        if (msg.sender != owner() && msg.sender != admin) {
            revert NotOwnerNorAdmin(msg.sender);
        }
        _;
    }

    constructor(
        address receiver,
        uint256 maxSupply,
        string memory _baseUri,
        string memory _defaultUnrevealedURI
    )
        ERC721A("Hyewon's Album of Genre Paintings", "HyewonPaintings")
        Ownable()
        Pausable()
    {
        _receiver = receiver;
        maximumSupply = maxSupply;
        baseURI = _baseUri;
        defaultUnrevealedURI = _defaultUnrevealedURI;
    }

    /**
     *  Get the STATE of the contract
     */
    function getState() public view returns (State) {
        if (currentRoundNumber == 0) {
            return State.DEPLOYED;
        }

        Round memory currentRound = rounds[currentRoundNumber];

        uint256 startTime = currentRound.startTime;
        uint256 endTime = currentRound.endTime;
        uint256 currentTime = block.timestamp;

        State currentState;

        if (currentTime < startTime) {
            currentState = State.PREPARE_MINTING;
        } else if (currentTime < endTime) {
            if (currentRound.maxMintingId > totalSupply()) {
                currentState = State.ON_MINTING;
            } else {
                currentState = State.END_MINTING;
            }
        } else {
            currentState = State.END_MINTING;
        }

        return currentState;
    }

    /**
     * Normal account minting
     */
    function mint(uint256 quantity)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        Round memory currentRound = getRound(currentRoundNumber);

        // check if whitelist only round
        if (currentRound.whitelisted) {
            revert WhitelistOnlyRound();
        }

        _sanityCheckForMinting(currentRound, quantity);

        require(safeMint(msg.sender, quantity));
    }

    /**
     *  Minting for whitelisted accounts only
     */
    function whitelistMint(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint16 quantity
    ) external payable nonReentrant whenNotPaused {
        Round memory currentRound = getRound(currentRoundNumber);

        // check if whitelist only round
        if (!currentRound.whitelisted) {
            revert NotWhitelistOnlyRound();
        }

        _sanityCheckForMinting(currentRound, quantity);

        // check if the address has enough allowance
        uint16 claimed = whitelists[currentRoundNumber][_msgSender()];
        uint16 maxAllowedQuantity = currentRound.maxAllowedMintingQuantity;

        if (claimed + quantity > maxAllowedQuantity) {
            revert ExceedAllowedQuantity(maxAllowedQuantity);
        }

        _updateWhitelistUsed(currentRoundNumber, quantity, v, r, s);

        require(safeMint(msg.sender, quantity));
    }

    function safeMint(address receiver, uint256 quantity)
        public
        returns (bool)
    {
        _safeMint(receiver, quantity);
        return true;
    }

    /**
     * Minting for admin account
     */
    function adminMint(uint256 quantity)
        external
        onlyOwnerOrAdmin(currentRoundNumber)
        nonReentrant
    {
        Round memory currentRound = rounds[currentRoundNumber];
        // check if minting does not exceed the maximum tokens for the round
        uint256 maxMintingId = currentRound.maxMintingId;
        if (!_isTokenAvailable(quantity, maxMintingId)) {
            revert ExceedMaximumForTheRound();
        }

        require(safeMint(msg.sender, quantity));
    }

    /**
     * Minting and transfer tokens
     * Only for owner
     */
    function adminMintTo(address[] calldata tos, uint256[] calldata quantities)
        external
        payable
        onlyOwner
    {
        uint256 length = tos.length;
        if (length != quantities.length) {
            revert BadRequest("Input size not match");
        }

        uint256 totalQuantity = 0;

        for (uint256 i = 0; i < tos.length; i++) {
            totalQuantity += quantities[i];
        }

        Round memory currentRound = rounds[currentRoundNumber];
        // check if minting does not exceed the maximum tokens for the round
        uint256 maxMintingId = currentRound.maxMintingId;

        if (!_isTokenAvailable(totalQuantity, maxMintingId)) {
            revert ExceedMaximumForTheRound();
        }

        for (uint256 i = 0; i < length; i++) {
            require(safeMint(tos[i], quantities[i]));
        }
    }

    /**
     * Transfer multiple tokens to an account
     */
    function transferBatch(uint256[] calldata tokenIds, address to)
        external
        nonReentrant
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom(_msgSender(), to, tokenIds[i]);
        }
    }

    /**
     * Get token uri
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        Round memory round = _getRoundByTokenId(tokenId);

        if (
            round.revealed &&
            keccak256(abi.encodePacked(round.tokenURIPrefix)) !=
            keccak256(abi.encodePacked(""))
        ) {
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        round.tokenURIPrefix,
                        "/",
                        _toString(tokenId),
                        ".json"
                    )
                );
        } else {
            return
                string(
                    abi.encodePacked(
                        defaultUnrevealedURI,
                        _toString(tokenId),
                        ".json"
                    )
                );
        }
    }

    /**
     *  Create a new minting round
     *  For owner only
     */
    function newRound(
        uint256 maxMintingId, // largest minting id for the round
        uint256 mintingFee, // minting fee
        uint16 maxAllowedMintingQuantity, // maximum number of minting quantity per account
        bool whitelisted, // use whitelist or not
        bool revealed, // reveal image or not
        uint256 startTime, // round starting time
        uint256 endTime, // round ending time
        bool onlyAdminRound, // only owner and admin can mint
        address admin // admin for the round
    ) external onlyOwner {
        // wrap-up the existing round
        if (currentRoundNumber > 0) {
            endRound();
        }

        // the maxMintingId of new round can NOT exceed the maximumSupply
        if (maxMintingId > maximumSupply) {
            revert BadRequest("maxMintingId exceed the maximumSupply");
        }

        if (startTime >= endTime) {
            revert BadRequest("endTime should be bigger");
        }

        uint16 newRoundNumber = ++currentRoundNumber;

        rounds[newRoundNumber] = Round({
            roundNumber: newRoundNumber,
            maxMintingId: maxMintingId,
            startId: _nextTokenId(),
            lastMintedId: 0,
            tokenURIPrefix: "",
            mintingFee: mintingFee,
            maxAllowedMintingQuantity: maxAllowedMintingQuantity,
            whitelisted: whitelisted,
            revealed: revealed,
            revealBlockNumber: 0,
            randomSelection: 0,
            startTime: startTime,
            endTime: endTime,
            onlyAdminRound: onlyAdminRound,
            admin: admin
        });

        emit NewRoundCreated();
    }

    /**
     * End the current round
     * For owner and admin
     */
    function endRound() public onlyOwnerOrAdmin(currentRoundNumber) {
        Round storage currentRound = rounds[currentRoundNumber];
        currentRound.lastMintedId = _nextTokenId() - 1;
        currentRound.endTime = block.timestamp;
    }

    /**
     *  Get round detail
     */
    function getRound(uint16 roundNumber) public view returns (Round memory) {
        return rounds[roundNumber];
    }

    /**
     *  Get the detail of the current round
     */
    function getCurrentRound() public view returns (Round memory) {
        return getRound(currentRoundNumber);
    }

    /**
     *  Set the maximum minting id for the current round
     *  For owner and admin
     */
    function setMaxMintingId(uint256 maxId) external {
        setMaxMintingId(currentRoundNumber, maxId);
    }

    /**
     *  Set the maximum minting id for the specified round
     *  For owner and admin
     */
    function setMaxMintingId(uint16 roundNumber, uint256 maxId)
        public
        onlyOwnerOrAdmin(roundNumber)
    {
        if (maxId < _nextTokenId()) {
            revert MaxMintingIdLowerThanCurrentId();
        }

        if (maxId > maximumSupply) {
            revert ExceedMaximumSupply();
        }

        Round storage round = rounds[roundNumber];
        round.maxMintingId = maxId;

        emit MaxMintingIdUpdated(roundNumber, maxId);
    }

    /**
     *  Set the token uri prefix for the current round
     *  For owner and admin
     */
    function setTokenURIPrefix(string memory prefix) external {
        setTokenURIPrefix(currentRoundNumber, prefix);
    }

    /**
     *  Set the token uri prefix for the specified round
     *  For owner and admin
     */
    function setTokenURIPrefix(uint16 roundNumber, string memory prefix)
        public
        onlyOwnerOrAdmin(roundNumber)
    {
        if (permanent) {
            revert ImmutableState();
        }

        Round storage round = rounds[roundNumber];
        round.tokenURIPrefix = prefix;

        emit TokenURIPrefixUpdated(roundNumber, prefix);
    }

    /**
     *  Set the minting for the current round
     *  OnlyOwner functions
     */
    function setMintingFee(uint256 fee) external {
        setMintingFee(currentRoundNumber, fee);
    }

    /**
     *  Set the minting for the specified round
     *  OnlyOwner functions
     */
    function setMintingFee(uint16 roundNumber, uint256 fee)
        public
        onlyOwnerOrAdmin(roundNumber)
    {
        Round storage round = rounds[roundNumber];
        round.mintingFee = fee;

        emit MintingFeeUpdated(roundNumber, fee);
    }

    /**
     *  Set maximum minting quantity for an account
     *  For owner and admin
     */
    function setMaxAllowedMintingQuantity(uint16 quantity) external {
        setMaxAllowedMintingQuantity(currentRoundNumber, quantity);
    }

    /**
     *  Set maximum minting quantity for an account
     *  For owner and admin
     */
    function setMaxAllowedMintingQuantity(uint16 roundNumber, uint16 quantity)
        public
        onlyOwnerOrAdmin(roundNumber)
    {
        Round storage round = rounds[roundNumber];
        round.maxAllowedMintingQuantity = quantity;

        emit MaxAllowedMintingCountUpdated(roundNumber, quantity);
    }

    /**
     *  On/off the whitelisted for the current round
     *  For owner and admin
     */
    function setWhitelisted(bool whitelisted) external {
        setWhitelisted(currentRoundNumber, whitelisted);
    }

    /**
     *  On/off the whitelisted for the specified round
     *  For owner and admin
     */
    function setWhitelisted(uint16 roundNumber, bool whitelisted)
        public
        onlyOwnerOrAdmin(roundNumber)
    {
        Round storage round = rounds[roundNumber];
        round.whitelisted = whitelisted;

        emit WhitelistRequiredChanged(roundNumber, whitelisted);
    }

    /**
     *  Trigger reveal process for the current round
     *  For owner and admin
     */
    function setRevealBlock() external {
        setRevealBlock(currentRoundNumber);
    }

    /**
     *  Trigger reveal process for the specified round
     *  For owner and admin
     */
    function setRevealBlock(uint16 roundNumber)
        public
        onlyOwnerOrAdmin(roundNumber)
    {
        Round storage round = rounds[roundNumber];

        if (round.lastMintedId == 0) {
            revert BadRequest("Round should be closed");
        }

        round.revealBlockNumber = block.number + revealBlockOffset;

        emit SetRevealBlock(round.revealBlockNumber);
    }

    /**
     *  Set random selection number based on entropy
     *  It set the reveal on
     */
    function setRandomSelection(uint16 roundNumber) public {
        Round storage round = rounds[roundNumber];

        if (round.revealed) {
            revert AlreadyRevealed();
        }

        uint256 revealBlockNumber = round.revealBlockNumber;

        if (revealBlockNumber > block.number) {
            revert BadRequest("Random selection is not ready");
        }

        bytes32 entropy;

        if (blockhash(revealBlockNumber - 1) != 0) {
            entropy = keccak256(
                abi.encodePacked(
                    blockhash(revealBlockNumber),
                    blockhash(revealBlockNumber - 1),
                    block.timestamp
                )
            );
        } else {
            entropy = keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    blockhash(block.number - 2),
                    block.timestamp
                )
            );
        }

        round.revealed = true;

        uint256 selected = _getRandomInRange(
            entropy,
            round.startId,
            round.lastMintedId
        );

        round.randomSelection = selected;

        emit Revealed(roundNumber);
    }

    /**
     * Set revealed
     * For owner and admin
     */
    function setRevealed() external {
        setRevealed(currentRoundNumber);
    }

    function setRevealed(uint16 roundNumber)
        public
        onlyOwnerOrAdmin(roundNumber)
    {
        Round storage round = rounds[roundNumber];

        if (round.lastMintedId == 0) {
            revert BadRequest("Round is still open");
        }

        round.revealed = true;

        emit Revealed(roundNumber);
    }

    /**
     *  Set minting start time for the current round
     *  Only for owner and admin
     */
    function setStartTime(uint256 time) external {
        setStartTime(currentRoundNumber, time);
    }

    /**
     *  Set minting start time for the specified round
     *  Only for owner and admin
     */
    function setStartTime(uint16 roundNumber, uint256 time)
        public
        onlyOwnerOrAdmin(roundNumber)
    {
        Round storage round = rounds[roundNumber];
        round.startTime = time;

        emit StartTimeUpdated(roundNumber, time);
    }

    /**
     *  Set minting end time for the current round
     *  Only for owner and admin
     */
    function setEndTime(uint256 time) external {
        setEndTime(currentRoundNumber, time);
    }

    /**
     *  Set minting end time for the specified round
     *  Only for owner and admin
     */
    function setEndTime(uint16 roundNumber, uint256 time)
        public
        onlyOwnerOrAdmin(roundNumber)
    {
        Round storage round = rounds[roundNumber];
        round.endTime = time;

        emit EndTimeUpdated(roundNumber, time);
    }

    /**
     *  On/off admin only round for the current round
     *  OnlyOwner
     */
    function setOnlyAdminRound(bool onlyAdmin) external {
        setOnlyAdminRound(currentRoundNumber, onlyAdmin);
    }

    /**
     *  On/off admin only round for the specified round
     *  OnlyOwner
     */
    function setOnlyAdminRound(uint16 roundNumber, bool onlyAdmin)
        public
        onlyOwner
    {
        Round storage round = rounds[roundNumber];
        round.onlyAdminRound = onlyAdmin;

        emit OnlyAdminRoundChanged(roundNumber, onlyAdmin);
    }

    /**
     *  Set the admin for the current round
     *  OnlyOwner
     */
    function setAdmin(address admin) external {
        setAdmin(currentRoundNumber, admin);
    }

    /**
     * Set the admin for the specified round
     * OnlyOwner
     */
    function setAdmin(uint16 roundNumber, address admin) public onlyOwner {
        Round storage round = rounds[roundNumber];
        round.admin = admin;

        emit AdminUpdated(roundNumber, admin);
    }

    /**
     *  Internal function to override the ERC721A _baseURI()
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     *  Get the base uri
     */
    function getBaseURI() external view returns (string memory) {
        return _baseURI();
    }

    /**
     * Set the base uri
     * Only for the owner
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        if (permanent) {
            revert ImmutableState();
        }

        baseURI = _newBaseURI;
        emit BaseURIUpdated(_newBaseURI);
    }

    /**
     * Set the default unrevealed uri
     * Only for the owner
     */
    function setDefaultUnrealedURI(string memory _defaultUnrevealedURI)
        external
        onlyOwner
    {
        defaultUnrevealedURI = _defaultUnrevealedURI;
        emit DefaultUnrevealedURIUpdated(_defaultUnrevealedURI);
    }

    /**
     *  Paused the contract
     *  Only for the owner
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     *  Unpause the contract
     *  Only for the owner
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     *  Set the receiver
     *  Only for the owner
     */
    function setReceiver(address receiver) external onlyOwner {
        _receiver = receiver;
    }

    /**
     * Withdraw the balance in the contract
     */
    function withdraw() external payable onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = _receiver.call{value: amount}("");
        if (!success) {
            revert FailedToSendBalance();
        }
        emit Withdraw(_receiver, amount);
    }

    /**
     *  Fallback function
     */
    fallback() external payable {
        emit Received(_msgSender(), msg.value);
    }

    /**
     *  Fallback function
     */
    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }

    /**
     * Set the 'perment' to true to prevent token uri change
     */
    function setPermanent() external onlyOwner {
        permanent = true;
    }

    /**
     *  Update signer
     *  For only owner
     */
    function updateSigner(address newSigner) external onlyOwner {
        _signer = newSigner;
    }

    function updateRevealBlockOffset(uint256 newOffset) external onlyOwner {
        revealBlockOffset = newOffset;
    }

    /**
     *  Sanity check before transfer tokens
     */
    function _sanityCheckForMinting(Round memory currentRound, uint256 quantity)
        private
    {
        // check if onlyAdminRound
        if (currentRound.onlyAdminRound) {
            revert AdminOnlyRound();
        }

        State currentState = getState();

        if (currentState != State.ON_MINTING) {
            revert MintingNotAllowed();
        }

        // check if not exceeding the maxAllowedMintingQuantity
        if (
            currentRound.maxAllowedMintingQuantity != 0 &&
            currentRound.maxAllowedMintingQuantity < quantity
        ) {
            revert ExceedAllowedQuantity(
                currentRound.maxAllowedMintingQuantity
            );
        }

        // check if minting does not exceed the maximum tokens for the round
        if (!_isTokenAvailable(quantity, currentRound.maxMintingId)) {
            revert ExceedMaximumForTheRound();
        }

        // check if proper fee is received
        uint256 neededFee = currentRound.mintingFee * quantity;
        if (neededFee != msg.value) revert NoMatchingFee();
    }

    /**
     *  Check the availability of tokens mintable for the round
     */
    function _isTokenAvailable(uint256 quantity, uint256 maxId)
        private
        view
        returns (bool)
    {
        // check if minting does not exceed the maximum tokens for the round
        if (_nextTokenId() + quantity > (maxId + 1)) {
            return false;
        }

        return true;
    }

    /**
     *  Private function to get the round number with token id
     */
    function _getRoundByTokenId(uint256 tokenId)
        private
        view
        returns (Round memory r)
    {
        if (!_exists(tokenId)) revert NonExistingToken(tokenId);

        uint16 roundNumber = 1;

        while (roundNumber <= currentRoundNumber) {
            r = rounds[roundNumber];
            uint256 roundMax = r.lastMintedId != 0
                ? r.lastMintedId
                : r.maxMintingId;
            if (tokenId > roundMax) {
                roundNumber++;
                continue;
            }
            return r;
        }
    }

    function _updateWhitelistUsed(
        uint16 round,
        uint16 quantity,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private {
        // verify the signature
        bytes32 hash = _getHash(round, _msgSender(), "whitelistClaim");
        if (!_verifySig(hash, v, r, s)) {
            revert SignatureNotMatch();
        }

        // add the claimed quantity
        whitelists[round][_msgSender()] += quantity;
    }

    function _getHash(
        uint16 round,
        address sender,
        string memory message
    ) private view returns (bytes32) {
        return
            keccak256(abi.encodePacked(address(this), round, sender, message));
    }

    function _verifySig(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view returns (bool) {
        return ecrecover(hash, v, r, s) == _signer;
    }

    function _getRandomInRange(
        bytes32 hash,
        uint256 begin,
        uint256 end
    ) private pure returns (uint256) {
        uint256 diff = end - begin + 1;
        return (uint256(hash) % diff) + begin;
    }
}
