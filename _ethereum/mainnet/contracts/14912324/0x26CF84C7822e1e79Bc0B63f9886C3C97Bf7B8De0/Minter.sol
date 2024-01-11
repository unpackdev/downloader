// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;


import "./PaymentSplitterUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC721Enumerable.sol";
import "./ECDSAUpgradeable.sol";
import "./SignatureCheckerUpgradeable.sol";
import "./Initializable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Provenance.sol";
import "./IBaseToken.sol";
import "./IRegistry.sol";
import "./IMintable.sol";
import "./Minting.sol";


contract Minter is AccessControlEnumerableUpgradeable, Provenance, PaymentSplitterUpgradeable, IMintable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SERVER_MINTER_ROLE = keccak256("SERVER_MINTER_ROLE");

    address public registry;           // Registry contract for shared state.
    address public tokenContract;      // Token to be minted.
    address public mintSigner;         // Signer who may approve addresses to mint.
    address public projectTokenNeeded; // address to baseToken that is needed in users wallet for whitelist
    uint256 public mintsPerToken;      // number tokens given per mint pass token
    address public paymentToken;       // Token to pay for NFTs with. Addres 0 indicates ether.
    uint256 public marketTaxTimesTen;          // tax when buying from game market

    mapping (address => uint256) lastBlock;    // Track per minter which block they last minted.
    mapping (address => uint256) totalMinted;  // Track per minter total they minted.
    mapping (bytes32 => bool) nonces;          // Track consumed non-sequential nonces.
    mapping (address => mapping(uint256 => bool)) tokenWhitelist;  //track whitelist tokens for each project, if using a project to whitelist

    address public imx;
    mapping(uint256 => bytes) public blueprints;
    event AssetMinted(address to, uint256 id, bytes blueprint);

    string public tokenMintPassType;
    //bool public tokenMintPassActive;
    mapping (bytes32 => mapping(uint256 => bool)) tokenMintPass;  //permit minting new tokens for some specific use case using old tokens
    mapping (bytes32 => mapping(uint256 => uint256)) tokenMintPassTracker;  //track minting of new tokens for some specific use case using old tokens
    mapping (bytes32 => uint256) supplyAtStartTime; //to prevent extra minting via recently minted tokens of same contract
    mapping (bytes32 => bool) tokenMintPassActive;

    bool public minterActive;



    /* -------------------------------- Modifiers ------------------------------- */

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, _msgSender()),
            "onlyAdmin: caller is not the admin");
        _;
    }

    modifier onlyServerMinter() {
        require(
            hasRole(SERVER_MINTER_ROLE, _msgSender()),
            "onlyServerMinter: caller is not the server minter");
        _;
    }

    modifier onlyIMX() {
        require(msg.sender == imx, "Function can only be called by owner or IMX");
        _;
    }


    /* ------------------------------- Constructor ------------------------------ */

    function initialize(
        address _tokenContract,
        address[] memory payees,
        uint256[] memory shares_
    )
        public
        initializer
    {

        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();

        __PaymentSplitter_init_unchained(payees, shares_);

        tokenContract = _tokenContract;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        registry = _msgSender();
        projectTokenNeeded = address(0);
        minterActive = true;
    }


    /* ------------------------------ Admin Methods ----------------------------- */

    function setProvenance(bytes32 provenanceHash) public onlyAdmin {
        _setProvenance(provenanceHash);
    }

    function setRevealTime(uint256 timestamp) public onlyAdmin {
        _setRevealTime(timestamp);
    }

    function setMintSigner(address signer) public onlyAdmin {
        mintSigner = signer;
    }

    function setMinterActive(bool status) public onlyAdmin {
        minterActive = status;
    }

    function setImx(address imxAddress) public onlyAdmin {
        imx = imxAddress;
    }

    function setTax(uint256 tax) public onlyAdmin {
        marketTaxTimesTen = tax;
    }

    function setPaymentToken(address token) public onlyAdmin {
        paymentToken = token;
    }

    function setTokenMintPassType(string memory tokenMintPassTypeStr, bool turnOffLastPass) public onlyAdmin {
        if(turnOffLastPass){
          tokenMintPassActive[keccak256(abi.encode(tokenMintPassType))] = false;
        }
        tokenMintPassType = tokenMintPassTypeStr;
    }

    function setTokenMintPassActive(string memory tokenMintPassTypeStr, bool status) public onlyAdmin {
        tokenMintPassActive[keccak256(abi.encode(tokenMintPassTypeStr))] = status;
    }

    function setSupplyAtStartTime(string memory tokenMintPassTypeStr, uint256 currentSupply) public onlyAdmin {
        if(currentSupply == 0){
          supplyAtStartTime[keccak256(abi.encode(tokenMintPassTypeStr))] = IBaseToken(tokenContract).totalMinted();
        }else{
          supplyAtStartTime[keccak256(abi.encode(tokenMintPassTypeStr))] = currentSupply;
        }
    }

    function setMintPass(address whitelistAddress, uint256 tokenMintVal) public onlyAdmin {
        projectTokenNeeded = whitelistAddress;
        mintsPerToken = tokenMintVal;
    }

    function reserveTokens(uint256 num) public onlyAdmin {
      require(minterActive, "not active");
        for (uint256 i = 0; i < num; i++) {
            IBaseToken(tokenContract).mint(_msgSender());
        }
    }

    /* ------------------------------- Immutable X Integration ------------------ */

    function mintFor(
        address user,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external override onlyIMX {
        require(minterActive, "not active");
        require(quantity == 1, "invalid quantity");
        (uint256 id, bytes memory blueprint) = Minting.split(mintingBlob);
        _mintFor(user, id, blueprint);
        blueprints[id] = blueprint;
        emit AssetMinted(user, id, blueprint);
    }

    function _mintFor(
      address to,
      uint256 id,
      bytes memory blueprint
    ) internal {
        IBaseToken(tokenContract).mint(to);
    }

    /* ------------------------------ Server Minter ----------------------------- */

    function mintTo(address[] calldata recipients, uint256[] calldata numEach) public onlyServerMinter {
        require(recipients.length == numEach.length, "array length mismatch");
        require(minterActive, "minter is not active");

        uint256 currentTotal = IBaseToken(tokenContract).totalMinted();

        for (uint256 i = 0; i < recipients.length; i++) {

            currentTotal += numEach[i];
            require(currentTotal <= IBaseToken(tokenContract).maxSupply(), "Minting would exceed max supply");

            for (uint256 j = 0; j < numEach[i]; j++) {
                IBaseToken(tokenContract).mint(recipients[i]);
            }
        }
    }

    function signedByServerMint(
        uint256 numberOfTokens,
        uint256 maxPermitted,
        bytes memory signature,
        bytes32 nonce,
        string memory purpose
    )
        public
    {
        require(minterActive, "minter is not active");

        bool signatureIsValid = SignatureCheckerUpgradeable.isValidSignatureNow(
            mintSigner,
            hashTransactionWithPurpose(msg.sender, maxPermitted, nonce, purpose),
            signature
        );
        require(signatureIsValid, "Minter: invalid signature");
        require(!nonces[nonce], "Minter: nonce already used");

        nonces[nonce] = true;

        uint256 currentTotal = IBaseToken(tokenContract).totalMinted();
        require(currentTotal + numberOfTokens <= IBaseToken(tokenContract).maxSupply(), "Minter: Purchase would exceed max supply");

        for (uint i = 0; i < numberOfTokens; i++) {
            IBaseToken(tokenContract).mint(msg.sender);
        }

    }


    /* ------------------------------ Public Reveal ----------------------------- */

    function finalizeReveal() public {
        _finalizeStartingIndex(IBaseToken(tokenContract).maxSupply());
    }


    /* ----------------------------- Whitelist Mint ----------------------------- */

    function signedMint(
        uint256 numberOfTokens,
        uint256 maxPermitted,
        bytes memory signature,
        bytes32 nonce
    )
        public
        payable
    {
        require(minterActive, "minter is not active");
        require(
            IRegistry(registry).getProjectStatus(tokenContract) == IRegistry.ProjectStatus.Whitelist,
            "Minter: signedMint is not active"
        );
        require(numberOfTokens <= maxPermitted, "Minter: numberOfTokens exceeds maxPermitted");

        bool signatureIsValid = SignatureCheckerUpgradeable.isValidSignatureNow(
            mintSigner,
            hashTransaction(msg.sender, maxPermitted, nonce),
            signature
        );
        require(signatureIsValid, "Minter: invalid signature");
        require(!nonces[nonce], "Minter: nonce already used");

        nonces[nonce] = true;

        sharedMintBehavior(numberOfTokens);
    }


    /* ------------------------------- Whitelist Mint by Holdings ------------------------------------------------ */

    function whiteListByTokenMint(
        uint256 numberOfTokens
    )
        public
        payable
    {
        require(minterActive, "minter is not active");
        require(
            IRegistry(registry).getProjectStatus(tokenContract) == IRegistry.ProjectStatus.WhitelistByToken,
            "Minter: whitelist by token is not active"
        );
        require(projectTokenNeeded != address(0), "Project with NFTs needed for whitelist status has not been set");
        require(projectTokenNeeded != tokenContract, "This will lead to an endless mint opportunities for the user");

        ERC721Enumerable nft = ERC721Enumerable(projectTokenNeeded);
        uint256 userBalance = nft.balanceOf(msg.sender);
        require(userBalance > 0, "You do not own any NFTs from the project needed for the whitelist");

        uint unusedTokenCount = 0;
        for (uint i = 0; i < userBalance; i++) {
          if(!tokenWhitelist[projectTokenNeeded][nft.tokenOfOwnerByIndex(msg.sender, i)]){
            unusedTokenCount += mintsPerToken;
            tokenWhitelist[projectTokenNeeded][nft.tokenOfOwnerByIndex(msg.sender, i)] = true;
            if(unusedTokenCount >= numberOfTokens){
              sharedMintBehavior(numberOfTokens);
              break;
            }
          }
        }
        require(numberOfTokens <= unusedTokenCount, "You dont have enough of the whitelisted NFTs to mint this many tokens");

    }

    function mintTokenUsingToken(
        uint256 numberOfTokens
    )
        public
    {
        require(minterActive, "minter is not active");
        require(tokenMintPassActive[keccak256(abi.encode(tokenMintPassType))], "mint pass via prior tokens not active");

        ERC721Enumerable nft = ERC721Enumerable(tokenContract);
        uint256 userBalance = nft.balanceOf(msg.sender);
        require(userBalance > 0, "You do not own any NFTs from the project needed for the whitelist");

        uint unusedTokenCount = 0;
        for (uint i = 0; i < userBalance; i++) {
          uint256 tokenIndex = nft.tokenOfOwnerByIndex(msg.sender, i);
          //can only permit prior tokens to mint, otherwise endless minting via new tokens
          if(!tokenMintPass[keccak256(abi.encode(tokenMintPassType))][tokenIndex] && tokenIndex <= supplyAtStartTime[keccak256(abi.encode(tokenMintPassType))]){
            unusedTokenCount += 1;
            tokenMintPass[keccak256(abi.encode(tokenMintPassType))][tokenIndex] = true;
            tokenMintPassTracker[keccak256(abi.encode(tokenMintPassType))][tokenIndex] = IBaseToken(tokenContract).totalMinted()+unusedTokenCount;
            if(unusedTokenCount >= numberOfTokens){
              for (uint j = 0; j < numberOfTokens; j++) {
                  IBaseToken(tokenContract).mint(msg.sender);
              }
              break;
            }
          }
        }
        require(numberOfTokens <= unusedTokenCount, "You dont have enough of the whitelisted NFTs to mint this many tokens");
    }

    function getTokenWhitelistStatus(address projectAddress, uint256 tokenIndex) public view returns(bool){
      return tokenWhitelist[projectAddress][tokenIndex];
    }

    function getTokenMintPassStatus(string memory tokenMintPassTypeStr, uint256 tokenIndex) public view returns(bool){
      return tokenMintPass[keccak256(abi.encode(tokenMintPassTypeStr))][tokenIndex];
    }

    function getTokenMintPassTracker(string memory tokenMintPassTypeStr, uint256 tokenIndex) public view returns(uint256){
      return tokenMintPassTracker[keccak256(abi.encode(tokenMintPassType))][tokenIndex];
    }

    function getTokenMintPassActive(string memory tokenMintPassTypeStr) public view returns(bool) {
        return tokenMintPassActive[keccak256(abi.encode(tokenMintPassTypeStr))];
    }

    function getSupplyAtStartTime(string memory tokenMintPassTypeStr) public view returns(uint256){
      return supplyAtStartTime[keccak256(abi.encode(tokenMintPassTypeStr))];
    }

    function getWhitelistTokens(address projectAddress, address user) public view returns(uint256){

      ERC721Enumerable nft = ERC721Enumerable(projectAddress);
      uint256 userBalance = nft.balanceOf(user);
      uint unusedTokenCount = 0;
      if(userBalance > 0){
        for (uint i = 0; i < userBalance; i++) {
          if(!tokenWhitelist[projectAddress][nft.tokenOfOwnerByIndex(user, i)]){
            unusedTokenCount += mintsPerToken;
          }
        }
      }
      return unusedTokenCount;
    }

    function getMintByTokenPasses(address projectAddress, address user, string memory tokenMintPassTypeStr) public view returns(uint256){

      ERC721Enumerable nft = ERC721Enumerable(projectAddress);
      uint256 userBalance = nft.balanceOf(user);
      uint unusedTokenCount = 0;
      if(userBalance > 0){
        for (uint i = 0; i < userBalance; i++) {
          uint256 tokenIndex = nft.tokenOfOwnerByIndex(user, i);
          if(!tokenMintPass[keccak256(abi.encode(tokenMintPassTypeStr))][tokenIndex] && tokenIndex <= supplyAtStartTime[keccak256(abi.encode(tokenMintPassTypeStr))]){
            unusedTokenCount += 1;
          }
        }
      }
      return unusedTokenCount;
    }

    /* ------------------------------- Public Mint ------------------------------ */

    function mint(uint256 numberOfTokens) public payable {

      require(minterActive, "minter is not active");
        require(
            IRegistry(registry).getProjectStatus(tokenContract) == IRegistry.ProjectStatus.Active,
            "Minter: Sale is not active"
        );

        sharedMintBehavior(numberOfTokens);

        _setStartingBlock(
            IBaseToken(tokenContract).totalMinted(),
            IBaseToken(tokenContract).maxSupply()
        );
    }


    /* --------------------------------- Signing -------------------------------- */

    function hashTransaction(
        address sender,
        uint256 numberOfTokens,
        bytes32 nonce
    )
        public
        view
        returns(bytes32)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return ECDSAUpgradeable.toEthSignedMessageHash(
            keccak256(abi.encode(chainId, address(this), sender, numberOfTokens, nonce))
        );
    }

    function hashTransactionWithPurpose(
        address sender,
        uint256 numberOfTokens,
        bytes32 nonce,
        string memory purpose
    )
        public
        view
        returns(bytes32)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return ECDSAUpgradeable.toEthSignedMessageHash(
            keccak256(abi.encode(chainId, address(this), sender, numberOfTokens, nonce, purpose))
        );
    }

    /* ------------------------------ Internal ----------------------------- */

    function maxPurchaseBehavior(uint256 numberOfTokens, uint256 maxPerBlock, uint256 maxPerWallet) internal {
        // Reentrancy check.
        require(lastBlock[msg.sender] != block.number, "Minter: Sender already minted this block");
        lastBlock[msg.sender] = block.number;

        if(maxPerBlock != 0) {
            require(numberOfTokens <= maxPerBlock, "Minter: maxBlockPurchase exceeded");
        }

        if(maxPerWallet != 0) {
            totalMinted[msg.sender] += numberOfTokens;
            require(totalMinted[msg.sender] <= maxPerWallet, "Minter: Sender reached mint max");
        }
    }

    function sharedMintBehavior(uint256 numberOfTokens)
        internal
    {
        // Get from Registry.
        uint256 maxBlockPurchase = IRegistry(registry).getProjectMaxBlockPurchase(tokenContract);
        uint256 maxWalletPurchase = IRegistry(registry).getProjectMaxWalletPurchase(tokenContract);
        uint256 price = IRegistry(registry).getProjectPrice(tokenContract);
        bool isFreeMint = IRegistry(registry).getProjectFreeStatus(tokenContract);

        require(numberOfTokens > 0, "Minter: numberOfTokens is 0");
        require(price != 0 || isFreeMint, "Minter: price not set in registry or is not a free mint");

        uint256 expectedValue = price * numberOfTokens;
        address paymentTokenCached = paymentToken;
        if (paymentTokenCached == address(0)) {
            require(expectedValue <= msg.value, "Minter: Sent ether value is incorrect");
        } else {
            IERC20Upgradeable(paymentTokenCached).safeTransferFrom(msg.sender, address(this), expectedValue);
        }

        // Save gas by failing early.
        uint256 currentTotal = IBaseToken(tokenContract).totalMinted();
        require(currentTotal + numberOfTokens <= IBaseToken(tokenContract).maxSupply(), "Minter: Purchase would exceed max supply");

        // Reentrancy check DO NOT MOVE.
        maxPurchaseBehavior(numberOfTokens, maxBlockPurchase, maxWalletPurchase);

        for (uint i = 0; i < numberOfTokens; i++) {
            IBaseToken(tokenContract).mint(msg.sender);
        }

        // Return the change.
        if(paymentTokenCached == address(0) && expectedValue < msg.value) {
            payable(_msgSender()).call{value: msg.value-expectedValue}("");
        }
    }

}
