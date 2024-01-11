// SPDX-License-Identifier: MIT

// ██████╗ ███████╗████████╗██████╗  ██████╗                
// ██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗               
// ██████╔╝█████╗     ██║   ██████╔╝██║   ██║               
// ██╔══██╗██╔══╝     ██║   ██╔══██╗██║   ██║               
// ██║  ██║███████╗   ██║   ██║  ██║╚██████╔╝               
// ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝                
                                                         
// ██████╗  ██████╗ ██╗     ██╗     ███████╗██████╗ ███████╗
// ██╔══██╗██╔═══██╗██║     ██║     ██╔════╝██╔══██╗██╔════╝
// ██████╔╝██║   ██║██║     ██║     █████╗  ██████╔╝███████╗
// ██╔══██╗██║   ██║██║     ██║     ██╔══╝  ██╔══██╗╚════██║
// ██║  ██║╚██████╔╝███████╗███████╗███████╗██║  ██║███████║
// ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚══════╝
                                                         

pragma solidity ^0.8.0;

//Mimetic Metadata
import "./MimeticMetadata.sol";
import "./INonDilutive.sol";

//Lock Registry
import "./ILock.sol";
import "./LockRegistry.sol";

//ERC-Standards and OpenZeppelin
import "./MerkleProof.sol";
import "./AccessControl.sol";
import "./ERC721A.sol";
import "./MDDA.sol";
import "./Scorekeeper.sol";

contract RetroRollers is 
    ERC721A,
    INonDilutive,
    MimeticMetadata,
    LockRegistry,
    AccessControl,
    MDDA,
    Scorekeeper
{
    using Strings for uint256;

    address public ROLLERS_PAYOUT_ADDRESS = 0xb2584a9414c54D0DCe290CE85aD8Ae8C1CD8827F;
    bytes32 public merkleRoot;

    uint256 public mintPrice = 0.08 ether;

    uint256 public maxPublicMintPerAddress = 2;
    uint256 public MAX_SUPPLY = 8888;
    uint256 public lockedSupply = 3333;
    uint256 public reservedSupply = 3000;
    uint256 public totalReserveMinted;
    uint256 public publicSupply;
    uint64 public startTime;

    bool public mintActive = false;

    mapping(uint => uint) private tokenMatrix;
    mapping(uint => uint) private mappedTokenIds;

    /** Contract Functionality Variables */
    bytes4 private constant _INTERFACE_ID_LOCKABLE = 0xc1c8d4d6;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor(string memory _baseTokenURI) ERC721A("Retro Rollers", "RR") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // startTime = 1651770000; // May 5th, 1:00 PM EST
        startTime = 1648863683; //THIS IS FOR TESTING ONLY

        setPublicSupply();

        loadGeneration(
            0,              // layer
            true,           // enabled   (cannot be removed by project owner)
            true,           // locked    (cannot be removed by project owner)
            true,           // sticky    (cannot be removed by owner)
            _baseTokenURI
        );
    }

    modifier onlyOperator() {
        if(!(hasRole(OPERATOR_ROLE, msg.sender)||owner()==msg.sender)) revert CallerIsNotOperator();
        _;
    }

    modifier mintCompliance() {
        if(startTime > block.timestamp) revert SaleNotStarted();
        if(!mintActive) revert SaleNotStarted();
        _;
    }

    /** ensures the function caller is the user */
    modifier callerIsUser() {
        if(tx.origin != msg.sender) revert CallerIsContract();
        _;
    }

    function mintDutchAuction(uint8 _quantity) public payable callerIsUser {
        DAHook(_quantity, totalSupply());

        uint random = randomness();
        for(uint i = 0; i < _quantity; i++){
            _mintToken(msg.sender, mappedTokenFor((random+i)));
        }
    }

    /** Public Mint Function */
    function mint(uint64 quantity)
        external
        payable
        callerIsUser
        mintCompliance
    {
        uint totalSupply = totalSupply();

        if(_addressData[msg.sender].mintTime < startTime) {
            _addressData[msg.sender].reserveMinted = 0;
            _addressData[msg.sender].numberMinted = 0;
        }

        if(totalSupply - totalReserveMinted + quantity > publicSupply) revert MaxMintAmountReached();
        if(quantity == 0) revert InvalidMintAmount();
        if(quantity + _addressData[msg.sender].numberMinted - _addressData[msg.sender].reserveMinted > maxPublicMintPerAddress) revert MaxMintAmountReached();

        delete totalSupply;

        uint random = randomness();

        for(uint i = 0; i < quantity; i++){
            _mintToken(msg.sender, mappedTokenFor((random+i)));
        }

        refundIfOver(quantity * mintPrice);
    }

    /** Presale Mint Function */
    function reservedMint(bytes32[] calldata _merkleProof)
        external
        payable
        callerIsUser
        mintCompliance
    {
        if(totalSupply() == MAX_SUPPLY - lockedSupply) revert MaxSupplyReached();

        if(!verify(msg.sender, _merkleProof)) revert InvalidProof();

        if(_addressData[msg.sender].mintTime < startTime) {
            _addressData[msg.sender].reserveMinted = 0;
            _addressData[msg.sender].numberMinted = 0;
        } else { 
            if (_addressData[msg.sender].reserveMinted == 1) revert MaxMintAmountReached();
        }

        _mintToken(msg.sender, mappedTokenFor(randomness()));

        _addressData[msg.sender].reserveMinted = 1;
        refundIfOver(mintPrice);
    }

    function randomness() internal view returns (uint256) {
        return uint256(keccak256(
            abi.encodePacked(
                msg.sender,
                block.coinbase,
                block.difficulty,
                block.gaslimit,
                block.timestamp,
                totalSupply(),
                blockhash(block.number - 1)
            )
        ));
    }

    function mappedTokenFor(uint _randomSeed) internal returns (uint64) {

        uint maxIndex = MAX_SUPPLY - lockedSupply-_mintCounter;
        uint random = _randomSeed % (maxIndex);

        uint lastAvail = tokenMatrix[maxIndex];

        uint256 value = 0;
        if (tokenMatrix[random] == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = random;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = tokenMatrix[random];
        }

        // If the last available tokenID is still unused...
        if (lastAvail == 0) {
            // ...store that ID in the current matrix position.
            tokenMatrix[random] = maxIndex;
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            tokenMatrix[random] = lastAvail;
        }

        return uint64(value + _startTokenId());
    }

    /** Get the owner of a specific token from the tokenId */
    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    function getTokensOfOwner(address owner) external view returns(uint[] memory) {
        uint[] memory tokens = new uint[](balanceOf(owner));
        uint ct = 0;

        for(uint i = 1; i <= MAX_SUPPLY - lockedSupply; i++) {
            if(_ownerships[i].addr == owner) {
                tokens[ct] = i;
                ct++;
            }
        }

        return tokens;
    }

    /**  Refund function which requires the minimum amount for the transaction and returns any extra payment to the sender */
    function refundIfOver(uint256 price) private {
        if(msg.value < price) revert NotEnoughETH();
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function verify(address target, bytes32[] calldata _merkleProof) public view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(target));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    /**  Standard TokenURI ERC721A function. */
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        // Make sure that the token has been minted
        if(!_exists(_tokenId)) revert InvalidTokenId();
        return _tokenURI(_tokenId);
    }

    /** Mint Function only usable by contract owner. Use reserved for giveaways and promotions. */
    function ownerMint(address to, uint256 quantity) public callerIsUser onlyOperator {
        if(quantity + totalSupply() > MAX_SUPPLY) revert MaxSupplyReached();
            uint random = randomness();

        for(uint i = 0; i < quantity; i++){
            _mintToken(to, mappedTokenFor(random+i));
        }

    }

    function toggleMint() external onlyOperator {
        mintActive = !mintActive;
    }

    function setStartTime(uint64 _startTime) external onlyOperator {
        startTime = _startTime;
    }

    function setMintPrice(uint _mintPrice) external onlyOperator {
        mintPrice = _mintPrice;
    }

    function setReservedSupply(uint _reservedSupply) external onlyOperator {
        reservedSupply = _reservedSupply;
        setPublicSupply();
    }

    function setLockedSupply(uint _lockedSupply) external onlyOperator {
        lockedSupply = _lockedSupply;
        setPublicSupply();
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOperator {
        merkleRoot = _merkleRoot;
    }

    function setScoreSignerAddress(address _scoreSigner) external onlyOperator {
        scoreSigner = _scoreSigner;
    }

    function setRollScorePrice(uint64 _price) external onlyOperator {
        rollScorePrice = _price;
    }

    function setRollTokenAddress(address _rollAddress) external onlyOperator {
        rollToken = IROLL(_rollAddress);
    }

    function setPayoutAddress(address _payoutAddress) external onlyOperator {
        ROLLERS_PAYOUT_ADDRESS = _payoutAddress;
    }

    function setPublicSupply() internal {
        publicSupply = MAX_SUPPLY - reservedSupply - lockedSupply;
    } 

    /** MIMETIC METADATA FUNCTIONS **/

    /*
     * @notice Allows any user to see the layer that a token currently has enabled.
     */
    function getTokenGeneration(uint256 _tokenId) override public virtual view returns(uint256) {
        if(_exists(_tokenId) == false) revert InvalidTokenId();
        return _getTokenGeneration(_tokenId);
    }

    function focusGeneration(uint256 _layerId, uint256 _tokenId) override public virtual payable {
        if(!isUnlocked(_tokenId)) revert LockedToken();
        _focusGeneration(_layerId, _tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
        return interfaceId == _INTERFACE_ID_LOCKABLE || super.supportsInterface(interfaceId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        if(!isUnlocked(tokenId)) revert LockedToken();
        ERC721A.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        if(!isUnlocked(tokenId)) revert LockedToken();
        ERC721A.safeTransferFrom(from, to, tokenId, _data);
    }

    function lockId(uint256 _id) external override {
        if(!_exists(_id)) revert InvalidTokenId();
        _lockId(_id);
    }

    function unlockId(uint256 _id) external override {
        if(!_exists(_id)) revert InvalidTokenId();
        _unlockId(_id);
    }

    function freeId(uint256 _id, address _contract) external override {
        if(!_exists(_id)) revert InvalidTokenId();
        _freeId(_id, _contract);
    }

    function recordHighScore(uint8 v, bytes32 r, bytes32 s, UserData memory record) public override(Scorekeeper) {
        require(ownerOf(record.rollerId) == msg.sender, "NotOwner");
        super.recordHighScore(v,r,s,record);
    }

    /** Standard withdraw function for the owner to pull the contract */
    function withdraw() external onlyOperator {
        uint256 mintAmount = address(this).balance;
        address rollers = payable(ROLLERS_PAYOUT_ADDRESS); // SET UP MULTI-SIG WALLET
        bool success;

        (success, ) = rollers.call{value: mintAmount }("");
        if(!success) revert TransactionUnsuccessful();
    }

    function withdrawInitialFunds() public onlyOwner {
        require(!INITIAL_FUNDS_WITHDRAWN, "Initial funds have already been withdrawn.");
        require(DA_FINAL_PRICE > 0, "DA has not finished!");

        //Only pull the amount of ether that is the final price times how many were bought. This leaves room for refunds until final withdraw.
        uint256 initialFunds = DA_QUANTITY * DA_FINAL_PRICE;

        INITIAL_FUNDS_WITHDRAWN = true;

        (bool succ, ) = payable(msg.sender).call{value: initialFunds}("");

        require(succ, "transfer failed");
    }

    function withdrawFinalFunds() public onlyOwner {
        //Require this is 1 week after DA Start.
        require(block.timestamp >= DA_STARTING_TIMESTAMP + 604800);

        uint256 finalFunds = address(this).balance;

        (bool succ, ) = payable(msg.sender).call{value: finalFunds}("");
        require(succ, "transfer failed");
    }
}

error CallerIsContract();
error CallerIsNotOperator();
error InvalidMintAmount();
error InvalidProof();
error InvalidSignature();
error InvalidTokenId();
error LockedToken();
error MaxMintAmountReached();
error MaxSupplyReached();
error NotEnoughETH();
error SaleNotStarted();
error TransactionUnsuccessful();


