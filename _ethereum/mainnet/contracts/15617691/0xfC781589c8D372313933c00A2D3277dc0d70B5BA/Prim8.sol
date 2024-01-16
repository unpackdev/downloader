// SPDX-License-Identifier: MIT
/**                           
                .......                          
               =(,.,(/,=,.                       
            ((,((((((((((((.                     
            /(((((((((((((((=       ./(/,.   ..  
               ,((((((((((((((,(((((((((((((((.  
               ,=====/(((((((((/((((((((((((.    
              =,/(((==============((,,           
        /((((((((((((/==============             
   .(((((((((((((((((,================           
 ,((((((((((((((((,(/====================        
 ,,  ,((((((=.   ==========================      
                 .=======================/       
                  ===================/(((((.     
                   ===========/(   .(((((((((    
                      ((((((((.        ,(((((((( 
                      (((((((            (((((   
                /((((((((((.           ,(((.     
                  .(((((((                       
                       ,,                        
                                              
======================================================
====       ===       ===    ==  =====  ====     ======
====  ====  ==  ====  ===  ===   ===   ===  ===  =====
====  ====  ==  ====  ===  ===  =   =  ==  =====  ====
====  ====  ==  ===   ===  ===  == ==  ===  ===  =====
====       ===      =====  ===  =====  ====     ======
====  ========  ====  ===  ===  =====  ===  ===  =====
====  ========  ====  ===  ===  =====  ==  =====  ====
====  ========  ====  ===  ===  =====  ===  ===  =====
====  ========  ====  ==    ==  =====  ====     ======
======================================================
 */
pragma solidity 0.8.7;

import "./ERC721PsiUpgradeable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Base64.sol";

contract Prim8 is
    OwnableUpgradeable,
    ERC721PsiUpgradeable,
    ReentrancyGuardUpgradeable
{
    ////////////
    // events //
    ////////////

    event SetState(States previous, States current);
    event ReservedCommunityMint(
        address indexed to,
        uint256 indexed tokenId,
        uint256 quantity
    );
    event PublicMint(
        address indexed minter,
        uint256 indexed tokenId,
        uint256 quantity
    );
    event AllowAirdrop(address to);
    event AllowAirdrops(address[] to);
    event SetAirdropAllownace(address to, uint256 amount);
    event Airdrop(address[] to);
    event SetBeneficiary(address previous, address current);
    event SetMaxSupply(uint256 previous, uint256 current);
    event SetBaseTokenURI(string previous, string current);
    event SetSeed(uint256 previous, uint256 current);
    event SetRevealBlock(uint256 previous, uint256 current);
    event SetSeedGeneratorContract(address previous, address current);

    ////////////
    // states //
    ////////////

    uint256 private _maxBatchSize;
    address private _beneficiary;

    // contract minted limit
    uint256 private _maxSupply;
    uint256 private _reservedForDev;
    uint256 private _reservedForCommunity;

    // individual minted limit
    uint256 private _limitAmountPerWallet;

    // current minted
    uint256 private _reservedCommunityMinted;
    uint256 private _airdropMinted;

    mapping(address => bool) private _airdropAllows;
    mapping(address => uint256) private _airdropAllowances;

    // metadata
    string private _baseTokenURI;
    string private _defaultTokenURI;
    uint256 private _revealBlock;
    uint256 private _seed;
    address private _seedGeneratorContract;
    bool private _randomSeedSetted;

    enum States {
        // 1. mint setup state for dev mint
        MintSetup,
        // 2. reservedCommunity mint state for whitlists mint
        ReservedCommunityMintStarted,
        ReservedCommunityMintEnded,
        // 3. public mint state for public mint
        PublicMintStarted,
        PublicMintEnded,
        // 4. airdrop state for airdrop mint
        Airdrop
    }
    States private _currentState;

    /////////////////
    // initializer //
    /////////////////

    function initialize(
        string memory title,
        string memory symbolValue,
        uint256 maxSupplyValue,
        uint256 reservedForDevValue,
        uint256 reservedForCommunityValue,
        uint256 limitAmountPerWalletValue,
        uint256 maxBatchSizeValue,
        string memory defaultTokenURIValue,
        address beneficiaryValue,
        address seedGeneratorContractValue
    ) external initializer {
        require(
            beneficiaryValue != address(0),
            "The beneficiary can not be null address"
        );
        require(
            seedGeneratorContractValue != address(0),
            "The seed generator can not be null address"
        );
        __ERC721Psi_init(title, symbolValue);
        __Ownable_init();
        __ReentrancyGuard_init();

        _maxSupply = maxSupplyValue;
        _maxBatchSize = maxBatchSizeValue;
        _reservedForDev = reservedForDevValue;
        _reservedForCommunity = reservedForCommunityValue;
        _limitAmountPerWallet = limitAmountPerWalletValue;
        _defaultTokenURI = defaultTokenURIValue;
        _beneficiary = beneficiaryValue;
        _seedGeneratorContract = seedGeneratorContractValue;
        _reservedCommunityMinted = 0;
        _airdropMinted = 0;
        _revealBlock = 0;
        _seed = 0;
        _randomSeedSetted = false;

        _currentState = States.MintSetup;
    }

    ////////////////////
    // set mint state //
    ////////////////////

    function setState(States state) external onlyOwner {
        States previous = _currentState;
        _currentState = state;
        emit SetState(previous, _currentState);
    }

    function getState() external view returns (States) {
        return _currentState;
    }

    //////////////////
    // 1. MintSetup //
    //////////////////
    function reservedForDev() external view returns (uint256) {
        return _reservedForDev;
    }

    function reservedDevMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= _reservedForDev,
            "too many already minted before dev mint"
        );
        require(
            quantity % _maxBatchSize == 0,
            "Can only mint a multiple of the _maxBatchSize"
        );
        uint256 numChunks = quantity / _maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, _maxBatchSize);
        }
    }

    ////////////////////////////////
    // 2. reserved community mint //
    ////////////////////////////////

    function reservedForCommunity() external view returns (uint256) {
        return _reservedForCommunity;
    }

    function reservedCommunityMint(address to, uint256 quantity)
        external
        onlyOwner
        isMintAllowed
    {
        require(
            _currentState == States.ReservedCommunityMintStarted,
            "Not during reserved community mint"
        );
        require(to != address(0), "Reciever can not be null address");
        require(
            quantity % _maxBatchSize == 0,
            "Can only mint a multiple of the _maxBatchSize"
        );

        uint256 newMintedToken = _reservedCommunityMinted + quantity;
        require(
            newMintedToken <= _reservedForCommunity,
            "Reached reserved community mint limit"
        );

        _reservedCommunityMinted = newMintedToken;

        uint256 startTokenId = _minted;

        emit ReservedCommunityMint(to, startTokenId, quantity);

        uint256 numChunks = quantity / _maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(to, _maxBatchSize);
        }
    }

    function reservedCommunityMinted() external view returns (uint256) {
        return _reservedCommunityMinted;
    }

    ////////////////////
    // 3. public mint //
    ////////////////////

    function limitAmountPerWallet() external view returns (uint256) {
        return _limitAmountPerWallet;
    }

    function publicMint(uint256 quantity)
        external
        nonReentrant
        callerIsUser
        isMintAllowed
    {
        require(
            _currentState == States.PublicMintStarted,
            "Not during public mint"
        );

        uint256 newTotalSupply = totalSupply() + quantity;
        require(newTotalSupply < maxSupply(), "Reached max supply");

        require(quantity <= _maxBatchSize, "Can not mint this many");

        uint256 newWalletBalance = balanceOf(msg.sender) + quantity;
        require(
            newWalletBalance <= _limitAmountPerWallet,
            "Reached mint limit per wallet"
        );

        uint256 startTokenId = _minted;
        emit PublicMint(msg.sender, startTokenId, quantity);

        _safeMint(msg.sender, quantity);
    }

    /////////////////////
    // 4. airdrop mint //
    /////////////////////

    function allowAirdrop(address to) external onlyOwner {
        require(to != address(0), "Can not allow to null address");
        _airdropAllows[to] = true;
        emit AllowAirdrop(to);
    }

    function allowAirdrops(address[] memory tos) external onlyOwner {
        uint256 count = tos.length;
        for (uint256 i = 0; i < count; i++) {
            require(tos[i] != address(0), "Can not allow to null address");
        }
        require(count <= _maxBatchSize, "Can not allow to this many");
        for (uint256 i = 0; i < count; i++) {
            _airdropAllows[tos[i]] = true;
        }
        emit AllowAirdrops(tos);
    }

    function setAirdropAllowance(address to, uint256 quantity)
        external
        onlyOwner
    {
        require(to != address(0), "Can not set allowance to null address");
        require(_airdropAllows[to], "Allow airdrop first");
        _airdropAllowances[to] = quantity;
        emit SetAirdropAllownace(to, quantity);
    }

    function airdrop(address[] memory tos, uint256[] memory quantities)
        external
        airdropAllowed
    {
        require(_currentState == States.Airdrop, "Not during airdrop mint");

        uint256 addressesCount = tos.length;
        require(
            addressesCount <= _maxBatchSize,
            "Only airdrop to address upto maxBatchSize in one call"
        );
        uint256 quantitiesCount = quantities.length;
        require(addressesCount == quantitiesCount, "Invalid params");

        for (uint256 i = 0; i < addressesCount; i++) {
            require(tos[i] != address(0), "Can not airdrop to null address");
        }

        uint256 totalQuantity;
        for (uint256 i = 0; i < quantitiesCount; i++) {
            require(quantities[i] > 0, "Invalid quantity params");
            totalQuantity += quantities[i];
        }

        uint256 airdropLimit = _airdropAllowances[msg.sender];
        require(airdropLimit >= totalQuantity, "Exceed the airdrop allowance");

        require(
            totalSupply() + totalQuantity < maxSupply(),
            "Reached max supply"
        );

        for (uint256 i = 0; i < addressesCount; i++) {
            _safeMint(tos[i], quantities[i]);
        }

        _airdropAllowances[msg.sender] -= totalQuantity;
        _airdropMinted += totalQuantity;

        emit Airdrop(tos);
    }

    function airdropMinted() external view onlyOwner returns (uint256) {
        return _airdropMinted;
    }

    //////////////////
    // reveal token //
    //////////////////

    function defaultTokenURI() external view onlyOwner returns (string memory) {
        return _defaultTokenURI;
    }

    function baseTokenURI() external view onlyOwner returns (string memory) {
        return _baseTokenURI;
    }

    function seed() external view returns (uint256) {
        return _seed;
    }

    function seedGeneratorContract() external view returns (address) {
        return _seedGeneratorContract;
    }

    function revealBlock() external view returns (uint256) {
        return _revealBlock;
    }

    function isRevealed() public view returns (bool) {
        return _seed > 0 && _revealBlock > 0 && block.number > _revealBlock;
    }

    function metadata(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token not exists.");

        if (!isRevealed()) return Strings.toString(tokenId);

        uint256[] memory _metadata = new uint256[](_maxSupply);

        for (uint256 i = 0; i < _maxSupply; i += 1) {
            _metadata[i] = i;
        }

        for (uint256 i = 0; i < _maxSupply; i += 1) {
            uint256 j = (uint256(keccak256(abi.encode(_seed, i))) %
                (_maxSupply));
            (_metadata[i], _metadata[j]) = (_metadata[j], _metadata[i]);
        }

        return Strings.toString(_metadata[tokenId]);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721PsiUpgradeable)
        returns (string memory)
    {
        require(_exists(tokenId), "Token not exists.");

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "#',
                        Strings.toString(tokenId),
                        '", "description": "Prim8 is an NFT collection created with the intention to emphasize the importance of collaborative, life-long learning and growth mindset", "image": "',
                        _defaultTokenURI,
                        '", "attributes": [ ] }'
                    )
                )
            )
        );
        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return
            isRevealed()
                ? string(
                    abi.encodePacked(_baseTokenURI, metadata(tokenId), ".json")
                )
                : output;
    }

    function setBaseTokenURI(string memory newBaseTokenURI) external onlyOwner {
        string memory previous = _baseTokenURI;
        _baseTokenURI = newBaseTokenURI;
        emit SetBaseTokenURI(previous, _baseTokenURI);
    }

    function setSeed(uint256 randomNumber) external {
        require(
            msg.sender == _seedGeneratorContract,
            "The caller is not authorized"
        );
        require(!_randomSeedSetted, "Seed already setted");
        _randomSeedSetted = true;
        uint256 previous = _seed;
        _seed = randomNumber;
        emit SetSeed(previous, _seed);
    }

    function setRevealBlock(uint256 blockNumber) external onlyOwner {
        uint256 previous = _revealBlock;
        _revealBlock = blockNumber;
        emit SetRevealBlock(previous, _revealBlock);
    }

    function setSeedGeneratorContract(address newSeedGeneratorContract)
        external
        onlyOwner
    {
        address previous = _seedGeneratorContract;
        _seedGeneratorContract = newSeedGeneratorContract;
        emit SetSeedGeneratorContract(previous, _seedGeneratorContract);
    }

    /////////////
    // configs //
    /////////////

    // supply
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
        uint256 previous = _maxSupply;
        _maxSupply = newMaxSupply;
        emit SetMaxSupply(previous, _maxSupply);
    }

    // beneficiary
    function beneficiary() external view returns (address) {
        return _beneficiary;
    }

    function setBeneficiary(address beneficiaryValue) external onlyOwner {
        require(beneficiaryValue != address(0), "Invalid beneficiary address");
        address previous = _beneficiary;
        _beneficiary = beneficiaryValue;
        emit SetBeneficiary(previous, _beneficiary);
    }

    function withdraw() external beneficiaryOnly {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // batch size
    function maxBatchSize() external view returns (uint256) {
        return _maxBatchSize;
    }

    //////////////
    // modifier //
    //////////////

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier beneficiaryOnly() {
        require(_beneficiary == msg.sender, "Beneficiary only");
        _;
    }

    modifier isMintAllowed() {
        require(_currentState != States.MintSetup, "Mint is not open");
        require(
            _currentState != States.ReservedCommunityMintEnded,
            "Reserved community mint ended"
        );
        require(_currentState != States.PublicMintEnded, "Public mint ended");
        _;
    }

    modifier airdropAllowed() {
        require(_airdropAllows[msg.sender], "Only eligible address");
        _;
    }
}
