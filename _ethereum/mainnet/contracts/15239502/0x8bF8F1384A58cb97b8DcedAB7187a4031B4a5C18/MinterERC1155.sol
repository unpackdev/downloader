// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;


import "./PaymentSplitterUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ERC721Enumerable.sol";
import "./ECDSAUpgradeable.sol";
import "./SignatureCheckerUpgradeable.sol";
import "./Initializable.sol";
import "./Provenance.sol";
import "./IBaseTokenERC1155.sol";
import "./IRegistry.sol";


contract MinterERC1155 is AccessControlEnumerableUpgradeable, PaymentSplitterUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant SERVER_MINTER_ROLE = keccak256("SERVER_MINTER_ROLE");

    address public registry;           // Registry contract for shared state.
    address public tokenContract;      // Token to be minted.
    address public mintSigner;         // Signer who may approve addresses to mint.
    address public projectTokenNeeded; // address to baseToken that is needed in users wallet for whitelist
    uint256 public mintsPerToken;      //number tokens given per mint pass token
    address public paymentToken;       // Token to pay for NFTs with. Address 0 indicates ether.

    mapping (address => uint256) lastBlock;    // Track per minter which block they last minted.
    mapping (address => uint256) totalMinted;  // Track per minter total they minted.
    mapping (bytes32 => bool) nonces;          // Track consumed non-sequential nonces.
    mapping (uint256 => uint256) prices;       // Price per token id.
    mapping (address => mapping(uint256 => bool)) tokenWhitelist;  //track whitelist tokens for each project, if using a project to whitelist



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
    }


    /* ------------------------------ Admin Methods ----------------------------- */

    function setPrice(uint256 id, uint256 price) public onlyAdmin {
        prices[id] = price;
    }

    function setMintSigner(address signer) public onlyAdmin {
        mintSigner = signer;
    }

    function setPaymentToken(address token) public onlyAdmin {
        paymentToken = token;
    }

    function setMintPass(address whitelistAddress, uint256 tokenMintVal) public onlyAdmin {
        projectTokenNeeded = whitelistAddress;
        mintsPerToken = tokenMintVal;
    }

    function reserveTokens(uint256 id, uint256 num) public onlyAdmin {
        IBaseTokenERC1155(tokenContract).mint(msg.sender, id, num, "");
    }

    function sweep(address token, address to, uint256 amount)
        external
        onlyAdmin
        returns (bool)
    {
        return IERC20Upgradeable(token).transfer(to, amount);
    }


    /* ------------------------------ Server Minter ----------------------------- */

    function mintTo(
        address[] calldata recipients,
        uint256[] calldata ids,
        uint256[] calldata numEach
    ) public onlyServerMinter {
        require(recipients.length == numEach.length, "Minter: array length mismatch");

        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 currentTotal = IBaseTokenERC1155(tokenContract).minted(ids[i]);

            currentTotal += numEach[i];
            require(currentTotal <= IBaseTokenERC1155(tokenContract).maxSupply(ids[i]), "Minter: Minting would exceed max supply");

            IBaseTokenERC1155(tokenContract).mint(recipients[i], ids[i], numEach[i], "");
        }
    }

    function signedByServerMint(
        uint256 id,
        uint256 numberOfTokens,
        uint256 maxPermitted,
        bytes memory signature,
        bytes32 nonce
    )
        public
        payable
    {

        bool signatureIsValid = SignatureCheckerUpgradeable.isValidSignatureNow(
            mintSigner,
            hashTransaction(msg.sender, id, maxPermitted, nonce),
            signature
        );
        require(signatureIsValid, "Minter: invalid signature");
        require(!nonces[nonce], "Minter: nonce already used");

        nonces[nonce] = true;

        uint256 currentTotal = IBaseTokenERC1155(tokenContract).minted(id);
        require(currentTotal + numberOfTokens <= IBaseTokenERC1155(tokenContract).maxSupply(id), "Minter: Purchase would exceed max supply");


        IBaseTokenERC1155(tokenContract).mint(msg.sender, id, numberOfTokens, "");

    }


    /* ----------------------------- Whitelist Mint ----------------------------- */

    function signedMint(
        uint256 id,
        uint256 numberOfTokens,
        uint256 maxPermitted,
        bytes memory signature,
        bytes32 nonce
    )
        public
        payable
    {

        require(
            IRegistry(registry).getProjectStatus(tokenContract) == IRegistry.ProjectStatus.Whitelist,
            "Minter: signedMint is not active"
        );
        require(numberOfTokens <= maxPermitted, "Minter: numberOfTokens exceeds maxPermitted");

        bool signatureIsValid = SignatureCheckerUpgradeable.isValidSignatureNow(
            mintSigner,
            hashTransaction(msg.sender, id, maxPermitted, nonce),
            signature
        );
        require(signatureIsValid, "Minter: invalid signature");
        require(!nonces[nonce], "Minter: nonce already used");

        nonces[nonce] = true;

        sharedMintBehavior(id, numberOfTokens);
    }

    function whiteListByTokenMint(
        uint256 id,
        uint256 numberOfTokens
    )
        public
        payable
    {

        require(
            IRegistry(registry).getProjectStatus(tokenContract) == IRegistry.ProjectStatus.WhitelistByToken,
            "Minter: whitelist by token is not active"
        );
        require(projectTokenNeeded != address(0), "Project with NFTs needed for whitelist status has not been set");

        ERC721Enumerable nft = ERC721Enumerable(projectTokenNeeded);
        uint256 userBalance = nft.balanceOf(msg.sender);
        require(userBalance > 0, "You do not own any NFTs from the project needed for the whitelist");

        uint unusedTokenCount = 0;
        for (uint i = 0; i < userBalance; i++) {
          if(!tokenWhitelist[projectTokenNeeded][nft.tokenOfOwnerByIndex(msg.sender, i)]){
            unusedTokenCount += mintsPerToken;
            tokenWhitelist[projectTokenNeeded][nft.tokenOfOwnerByIndex(msg.sender, i)] = true;
            if(unusedTokenCount >= numberOfTokens){
              sharedMintBehavior(id, numberOfTokens);
              break;
            }
          }
        }
        require(numberOfTokens <= unusedTokenCount, "You dont have enough of the whitelisted NFTs to mint this many tokens");

    }

    function getTokenWhitelistStatus(address projectAddress, uint256 tokenIndex) public view returns(bool){
      return tokenWhitelist[projectAddress][tokenIndex];
    }

    //change 1 to mintpass
    function getWhitelistTokens(address projectAddress, address user) public view returns(uint256){
      require(
          IRegistry(registry).getProjectStatus(tokenContract) == IRegistry.ProjectStatus.WhitelistByToken,
          "Minter: whitelist by token is not active"
      );
      require(projectTokenNeeded != address(0), "Project with NFTs needed for whitelist status has not been set");

      ERC721Enumerable nft = ERC721Enumerable(projectTokenNeeded);
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


    /* ------------------------------- Public Mint ------------------------------ */

    function mint(uint256 id, uint256 numberOfTokens) public payable {

        require(
            IRegistry(registry).getProjectStatus(tokenContract) == IRegistry.ProjectStatus.Active,
            "Minter: Sale is not active"
        );

        sharedMintBehavior(id, numberOfTokens);

    }


    /* --------------------------------- Signing -------------------------------- */

    function hashTransaction(
        address sender,
        uint256 id,
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
            keccak256(abi.encode(chainId, address(this), sender, id, numberOfTokens, nonce))
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

    function sharedMintBehavior(uint256 id, uint256 numberOfTokens)
        internal
    {
        // Get from Registry.
        uint256 maxBlockPurchase = IRegistry(registry).getProjectMaxBlockPurchase(tokenContract);
        uint256 maxWalletPurchase = IRegistry(registry).getProjectMaxWalletPurchase(tokenContract);
        uint256 price = prices[id];
        bool isFreeMint = IRegistry(registry).getProjectFreeStatus(tokenContract);

        require(numberOfTokens > 0, "Minter: numberOfTokens is 0");
        require(price != 0 || isFreeMint, "Minter: price not set in registry or is not a free mint");

        uint256 expectedValue = price * numberOfTokens;

        // Save gas by failing early.
        uint256 currentTotal = IBaseTokenERC1155(tokenContract).minted(id);
        require(currentTotal + numberOfTokens <= IBaseTokenERC1155(tokenContract).maxSupply(id), "Minter: Purchase would exceed max supply");

        // Reentrancy check DO NOT MOVE.
        maxPurchaseBehavior(numberOfTokens, maxBlockPurchase, maxWalletPurchase);
        address paymentTokenCached = paymentToken;
        if (paymentTokenCached == address(0)) {
            require(expectedValue <= msg.value, "Minter: Sent ether value is incorrect");
        } else {
            IERC20Upgradeable(paymentTokenCached).transferFrom(msg.sender, address(this), expectedValue);
        }
        IBaseTokenERC1155(tokenContract).mint(msg.sender, id, numberOfTokens, "");

        // Return the change.
        if(expectedValue < msg.value) {
            payable(_msgSender()).call{value: msg.value-expectedValue}("");
        }
    }

}
