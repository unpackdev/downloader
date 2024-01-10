// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

pragma experimental ABIEncoderV2;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeERC20.sol";

import "./IPolicyRegistryV2.sol";
import "./IPolicyBookRegistryV2.sol";
import "./IContractsRegistryV2.sol";
import "./IPolicyBookFabricV2.sol";
import "./IPolicyBookV2.sol";
import "./IPolicyQuoteV2.sol";
import "./IClaimingRegistryV2.sol";
import "./IDistributor.sol";
import "./AbstractDistributor.sol";

contract BridgeDistributorV2 is
    AbstractDistributor,
    IDistributor,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IPolicyRegistryV2 public policyRegistry;
    IPolicyBookRegistryV2 public policyBookRegistry;
    IContractsRegistryV2 public contractsRegistry;
    IClaimingRegistryV2 public claimRegistry;
    IPolicyQuoteV2 public policyQuote;

    struct PolicyInfo {
        uint256 policiesCount;
        address[] polBooksArr;
        IPolicyRegistryV2.PolicyInfo[] policiesInfo;
        IClaimingRegistryV2.ClaimStatus[] status;
    }

    function __BridgeDistributor_init(address _contractsRegistry)
        public
        initializer
    {
        __Ownable_init();
        __ReentrancyGuard_init();
        contractsRegistry = IContractsRegistryV2(_contractsRegistry);
        policyRegistry = IPolicyRegistryV2(
            contractsRegistry.getPolicyRegistryContract()
        );
        policyBookRegistry = IPolicyBookRegistryV2(
            contractsRegistry.getPolicyBookRegistryContract()
        );
        claimRegistry = IClaimingRegistryV2(
            contractsRegistry.getClaimingRegistryContract()
        );
        policyQuote = IPolicyQuoteV2(
            contractsRegistry.getPolicyQuoteContract()
        );
    }

    function getCoverCount(address _userAddr, bool _isActive)
        external
        view
        override
        returns (uint256)
    {
        uint256 _ownersCoverCount = policyRegistry.getPoliciesLength(_userAddr);

        PolicyInfo memory pol;
        (
            pol.policiesCount,
            pol.polBooksArr,
            pol.policiesInfo,
            pol.status
        ) = policyRegistry.getPoliciesInfo(
            _userAddr,
            _isActive,
            0,
            _ownersCoverCount
        );
        return pol.policiesCount;
    }

    function getCover(
        address _userAddr,
        uint256 _coverId,
        bool _isActive,
        uint256 _limitLoop
    ) external view override returns (IDistributor.Cover memory) {
        uint256 _ownersCoverCount = policyRegistry.getPoliciesLength(_userAddr);

        PolicyInfo memory pol;
        (
            pol.policiesCount,
            pol.polBooksArr,
            pol.policiesInfo,
            pol.status
        ) = policyRegistry.getPoliciesInfo(
            _userAddr,
            _isActive,
            0,
            _ownersCoverCount
        );

        require(
            _coverId < pol.policiesCount,
            "BridgeDistributor: Invalid coverId"
        );

        uint256 limit = 0;
        if (pol.policiesCount > _limitLoop) {
            limit = _limitLoop;
        } else {
            limit = pol.policiesCount;
        }

        IDistributor.Cover[] memory userCovers = new IDistributor.Cover[](
            limit
        );

        for (uint256 coverId = 0; coverId < limit; coverId++) {
            IDistributor.Cover memory cover;
            cover.contractAddress = pol.polBooksArr[coverId];
            cover.coverAmount = pol.policiesInfo[coverId].coverAmount;
            cover.premium = pol.policiesInfo[coverId].premium;
            cover.productId = pol.policiesInfo[coverId].startTime;
            cover.expiration = pol.policiesInfo[coverId].endTime;
            cover.status = uint256(pol.status[coverId]);
            userCovers[coverId] = cover;
        }
        return userCovers[_coverId];
    }

    function getPoliciesArr(address _userAddr)
        external
        view
        returns (address[] memory _arr)
    {
        return policyRegistry.getPoliciesArr(_userAddr);
    }

    function getQuote(
        uint256 _bridgeEpochs,
        uint256 _amountInWei,
        address _bridgeProductAddress,
        address _buyerAddress,
        address _interfaceCompliant2,
        bytes calldata _interfaceCompliant3
    ) external view override returns (IDistributor.CoverQuote memory) {
        bool isPolicyBook = policyBookRegistry.isPolicyBook(
            _bridgeProductAddress
        );
        require(isPolicyBook == true, "BridgeDistributor: Not a policyBook");

        IPolicyBookV2 policyBook = IPolicyBookV2(_bridgeProductAddress);

        IDistributor.CoverQuote memory coverQuote;
        (
            coverQuote.prop1, // totalSeconds, totalPrice
            coverQuote.prop2,
            coverQuote.prop3
        ) = policyBook.getPolicyPrice(
            _bridgeEpochs,
            _amountInWei,
            _buyerAddress
        );
        coverQuote.prop4 = policyBook.totalLiquidity();
        coverQuote.prop5 = policyBook.totalCoverTokens();
        //coverQuote.prop5  = policyQuote.getQuote(coverQuote.prop1,coverQuote.prop2, policyBook); //get price in DAI?

        address[] memory policyBookArr = new address[](1);
        policyBookArr[0] = _bridgeProductAddress;
        //(IPolicyBookRegistry.PolicyBookStats[] memory _stats) = policyBookRegistry.stats(policyBookArr);
        //coverQuote.prop6  = _stats[0].maxCapacity;

        return coverQuote;
    }

    function buyCover(
        address _bridgeProductAddress,
        uint256 _epochsNumber,
        uint16 _sumAssured,
        address _buyerAddress,
        address _treasuryAddress,
        uint256 _premium,
        bytes calldata _interfaceCompliant4
    ) external payable nonReentrant {
        // get payable contract address
        IPolicyBookV2 policyBook = IPolicyBookV2(_bridgeProductAddress);
        IPolicyBookFacadeV2 policyBookFacade = policyBook.policyBookFacade();

        address stblToken = contractsRegistry.getUSDTContract();

        // Check previous allowance
        require(
            IERC20Upgradeable(stblToken).allowance(msg.sender, address(this)) >=
                _premium,
            "BridgeDistributor: Need funds approval"
        );

        // transfer erc20 funds to this contract
        IERC20Upgradeable(stblToken).safeTransferFrom(
            msg.sender,
            address(this),
            _premium
        );
        if (
            IERC20Upgradeable(stblToken).allowance(
                address(this),
                address(policyBook)
            ) == uint256(0)
        ) {
            //safe as this contract has no funds stored & will be called once only
            IERC20Upgradeable(stblToken).approve(address(policyBook), MAX_INT);
        }
        // buy policyBookFacade
        policyBookFacade.buyPolicyFromDistributorFor(
            _buyerAddress,
            _epochsNumber,
            _sumAssured,
            _treasuryAddress
        );
    }

    function listWithStats(uint8 _offset, uint256 _limitLoop)
        external
        view
        returns (PolicyCatalog[] memory)
    {
        uint256 count = policyBookRegistry.count();

        uint256 limit = 0;
        if (count > _limitLoop) {
            limit = _limitLoop;
        } else {
            limit = count;
        }

        (
            address[] memory _policyBooks,
            IPolicyBookRegistryV2.PolicyBookStats[] memory _stats
        ) = policyBookRegistry.listWithStats(_offset, count);

        PolicyCatalog[] memory catalogList;
        PolicyCatalog memory catalog;

        for (uint8 i = 0; i < limit; i++) {
            catalog.name = _stats[i].symbol;
            catalog.insuredContract = _stats[i].insuredContract;
            catalog.maxCapacity = _stats[i].maxCapacity;
            catalog.totalDaiLiquidity = _stats[i].totalSTBLLiquidity;
            catalog.APY = _stats[i].APY;
            catalog.whitelisted = _stats[i].whitelisted;
            catalog.policyAddress = _policyBooks[i];
            catalogList[i] = catalog;
        }
        return catalogList;
    }

    struct PolicyCatalog {
        string name;
        address insuredContract;
        IPolicyBookFabricV2.ContractType contractType;
        uint256 maxCapacity;
        uint256 totalDaiLiquidity;
        uint256 APY;
        bool whitelisted;
        address policyAddress;
    }

    function list(uint256 _offset)
        external
        view
        returns (address[] memory _policyBooks)
    {
        uint256 limit = policyBookRegistry.count();
        return policyBookRegistry.list(_offset, limit);
    }

    function stats() public view returns (address[] memory) {
        address[] memory _policyBooks = this.list(0);
        policyBookRegistry.stats(_policyBooks);
        return _policyBooks;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return interfaceId == type(IDistributor).interfaceId;
    }

    function addressCero() external view returns (address) {
        return address(0);
    }
}
