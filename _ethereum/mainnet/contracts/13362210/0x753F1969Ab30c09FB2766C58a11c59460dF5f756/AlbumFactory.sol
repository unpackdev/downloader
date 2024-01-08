//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20PresetMinterPauser.sol";
import "./Create2.sol";

import "./Album.sol";
import "./AllowList.sol";
import "./IENS.sol";
import "./IENSResolver.sol";
import "./IERC721.sol";
import "./IFactorySafeHelper.sol";

contract AlbumFactory {
    event AlbumCreated(
        string name,
        address album,
        address safe,
        address realityModule,
        address token
    );

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 public constant SZNS_DAO_RAKE_DIVISOR = 100;

    AllowList public immutable ALLOW_LIST;
    IFactorySafeHelper public immutable FACTORY_SAFE_HELPER;
    IENS public immutable ENS;
    address public immutable ENS_PUBLIC_RESOLVER_ADDRESS;
    bytes32 public immutable BASE_ENS_NODE;
    address public immutable SZNS_DAO;

    struct TokenParams {
        string symbol;
        uint256 totalTokens;
    }

    constructor(
        address allowListAddress,
        address factorySafeHelperAddress,
        address ensAddress,
        address ensPublicResolverAddress,
        bytes32 baseEnsNode,
        address sznsDao
    ) {
        ALLOW_LIST = AllowList(allowListAddress);
        FACTORY_SAFE_HELPER = IFactorySafeHelper(factorySafeHelperAddress);
        ENS = IENS(ensAddress);
        BASE_ENS_NODE = baseEnsNode;
        ENS_PUBLIC_RESOLVER_ADDRESS = ensPublicResolverAddress;
        SZNS_DAO = sznsDao;
    }

    function createAlbum(
        string memory name,
        TokenParams memory tokenParams,
        Album.TokenSaleParams memory tokenSaleParams,
        // AlbumFactory contract has to be approved to transfer all of these NFTs!
        address[] calldata nftAddresses,
        uint256[] calldata nftIds,
        bytes[] calldata ensResolverData,
        uint256 minReservePrice
    ) external {
        require(
            ALLOW_LIST.getIsAllowed(msg.sender),
            "Sender not allowed to create album!"
        );
        require(
            nftAddresses.length == nftIds.length,
            "NFT address and ID arrays must have same lengths"
        );
        require(
            tokenParams.totalTokens >= 100 ether,
            "Total tokens must be at least 100 full tokens"
        );
        require(
            tokenParams.totalTokens - tokenSaleParams.numTokens >=
                tokenParams.totalTokens / SZNS_DAO_RAKE_DIVISOR,
            "Enough tokens for the szns dao rake must be left out of the (sale"
        );
        address safe;
        address realityModule;
        {
            bytes32 nameHash = keccak256(abi.encodePacked(name));
            bytes32 ensSubNode = keccak256(
                abi.encodePacked(BASE_ENS_NODE, nameHash)
            );
            require(
                ENS.owner(ensSubNode) == address(0),
                "ENS subname is already owned"
            );
            (safe, realityModule) = FACTORY_SAFE_HELPER.createAndSetupSafe(
                ensSubNode
            );
            ENS.setSubnodeOwner(BASE_ENS_NODE, nameHash, address(this));
            ENS.setResolver(ensSubNode, ENS_PUBLIC_RESOLVER_ADDRESS);
            IENSResolver(ENS_PUBLIC_RESOLVER_ADDRESS).multicall(
                ensResolverData
            );
            ENS.setOwner(ensSubNode, safe);
        }
        address token = createAndSetupToken(name, tokenParams.symbol, safe);
        address album = createAndSetupAlbum(
            safe,
            token,
            tokenSaleParams,
            nftAddresses,
            nftIds,
            minReservePrice
        );
        distributeAlbumTokens(
            token,
            tokenParams.totalTokens,
            tokenSaleParams.numTokens,
            album
        );
        emit AlbumCreated(name, album, safe, realityModule, token);
    }

    function createAndSetupToken(
        string memory name,
        string memory symbol,
        address safeAddress
    ) internal returns (address) {
        ERC20PresetMinterPauser token = new ERC20PresetMinterPauser{salt: ""}(
            name,
            symbol
        );
        token.grantRole(DEFAULT_ADMIN_ROLE, safeAddress);
        token.grantRole(MINTER_ROLE, safeAddress);
        token.grantRole(PAUSER_ROLE, safeAddress);
        return address(token);
    }

    function createAndSetupAlbum(
        address safeAddress,
        address tokenAddress,
        Album.TokenSaleParams memory tokenSaleParams,
        address[] calldata nftAddresses,
        uint256[] calldata nftIds,
        uint256 minReservePrice
    ) internal returns (address) {
        bytes memory creationCode = abi.encodePacked(
            type(Album).creationCode,
            abi.encode(
                safeAddress,
                tokenAddress,
                msg.sender,
                tokenSaleParams,
                nftAddresses,
                nftIds,
                minReservePrice
            )
        );
        address albumAddr = Create2.computeAddress("", keccak256(creationCode));
        for (uint256 i = 0; i < nftAddresses.length; i++) {
            IERC721(nftAddresses[i]).safeTransferFrom(
                msg.sender,
                albumAddr,
                nftIds[i]
            );
        }
        return Create2.deploy(0, "", creationCode);
    }

    function distributeAlbumTokens(
        address _token,
        uint256 totalTokens,
        uint256 amountSold,
        address album
    ) internal {
        require(totalTokens >= amountSold);
        require(totalTokens > 0);
        ERC20PresetMinterPauser token = ERC20PresetMinterPauser(_token);
        // Send tokens to be sold to the Album, which manages the sale.
        token.mint(album, amountSold);
        uint256 sznsDaoRake = totalTokens / SZNS_DAO_RAKE_DIVISOR;
        // Send a small amount of the Album tokens as a rake to the szns dao.
        token.mint(SZNS_DAO, sznsDaoRake);
        // Send the rest of the tokens to the Album creator.
        token.mint(msg.sender, (totalTokens - amountSold) - sznsDaoRake);
    }
}
