//SPDX-License-Identifier: MIT
/**
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(     (@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(   @@@@@@@@@@@@@@@@@@@@(            @@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@             @@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@(            @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@(            @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@     @@@@@@@     @@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@(         @@(         @@(            @@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@          @@          @@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@     @@@@@@@     @@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@ @@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(     @@@@@@@     @@@@@@@     @@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @           @           @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@(            @@@         @@@         @@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@     @@@@@@@     @@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@(            @@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@(            @@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@(            @@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@(     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 */
pragma solidity 0.8.6;

import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./Math.sol";
import "./SafeCast.sol";
import "./IVestedNil.sol";
import "./INOwnerResolver.sol";
import "./INilPass.sol";
import "./IArtistMiningCalculator.sol";

/**
 * @title MasterMint contract
 * @author Nil DAO
 * @notice This contract wraps actual minting contracts and performs administrative functions
 */
contract MasterMint is ReentrancyGuard, AccessControl, INOwnerResolver {
    using SafeCast for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");

    enum MintStatus {
        NONE,
        PENDING,
        OPEN,
        PAUSED
    }

    struct MintState {
        uint128 nMinted;
        uint128 totalPaidInWei;
        uint128 artistMiningWithdrawn;
        uint128 paymentWithdrawn;
        uint32 artistMiningThreshold;
        uint16 protocolFeesInBPS;
        INilPass nilPass;
        MintStatus status;
        address creator;
        IArtistMiningCalculator calculator;
    }

    struct MintPaymentState {
        uint32 nMinted;
        uint112 nPaid;
        uint112 totalPaidInWei;
    }

    struct MintWithdrawalState {
        uint128 artistMiningWithdrawn;
        uint128 paymentWithdrawn;
    }

    struct MintMetadata {
        uint32 artistMiningThreshold;
        uint16 artistMiningPaymentThresholdInETH;
        uint16 protocolFeesInBPS;
        uint16 curationFeesInBPS;
        INilPass nilPass;
        MintStatus status;
        address creator;
        IArtistMiningCalculator calculator;
    }

    struct ProtocolConfiguration {
        uint16 protocolFeesInBPS;
        uint16 curationFeesInBPS;
        uint16 artistMiningHighWatermark;
        uint16 artistMiningThresholdInBPS;
        uint16 artistMiningPaymentThresholdInETH;
        uint128 maxNilMintable;
    }

    MintMetadata[] public mintsMetadata;
    MintPaymentState[] public payments;
    MintWithdrawalState[] public withdrawals;
    IVestedNil public immutable vNil;
    INOwnerResolver public immutable nOwnerResolver;
    IArtistMiningCalculator public calculator;
    address public protocolFeesPayoutAccount;
    address public curationFeesPayoutAccount;
    ProtocolConfiguration public configuration;
    uint128 public totalNilMinted;
    uint256 public feesCollectable;
    uint128 public nilCollectable;

    event MintAdded(uint256 mintId, MintMetadata metadata);
    event MintReplaced(uint256 mintId, MintMetadata metadata);

    constructor(
        IVestedNil vNil_,
        INOwnerResolver nOwnerResolver_,
        IArtistMiningCalculator calculator_,
        ProtocolConfiguration memory configuration_,
        address dao
    ) {
        require(address(vNil_) != address(0), "MasterMint:ILLEGAL_NIL_ADDRESS");
        require(address(dao) != address(0), "MasterMint:ILLEGAL_DAO_ADDRESS");
        _setupRole(OPERATOR_ROLE, dao);
        _setupRole(ADMIN_ROLE, dao);
        _setRoleAdmin(OPERATOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender); // This will be surrendered after deployment
        vNil = vNil_;
        nOwnerResolver = nOwnerResolver_;
        setCalculator(calculator_);
        setConfiguration(configuration_);
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "MasterMint:ACCESS_DENIED");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "MasterMint:ACCESS_DENIED");
        _;
    }

    /**
     * @notice Adds a mint
     * @param nilPass NFT to mint
     * @param creator Creator of the NFT
     */
    function addMint(INilPass nilPass, address creator) external onlyOperator {
        MintMetadata memory metadata = _createMint(nilPass, creator);
        mintsMetadata.push(metadata);
        payments.push(MintPaymentState(0, 0, 0));
        withdrawals.push(MintWithdrawalState(0, 0));
        emit MintAdded(mintsMetadata.length - 1, metadata);
    }

    /**
     * @notice Edit a mint
     * @param nilPass NFT to mint
     * @param creator Creator of the NFT
     */
    function replaceMint(
        uint256 mintId,
        INilPass nilPass,
        address creator
    ) external onlyOperator {
        require(mintId < mintsMetadata.length, "MasterMint:ILLEGAL_MINT_ID");
        MintMetadata memory metadata = mintsMetadata[mintId];
        require(metadata.status == MintStatus.PENDING, "MasterMint:ILLEGAL_STATUS");
        metadata = _createMint(nilPass, creator);
        mintsMetadata[mintId] = metadata;
        emit MintReplaced(mintId, metadata);
    }

    function _createMint(INilPass nilPass, address creator) internal view returns (MintMetadata memory) {
        require(address(nilPass) != address(0), "MasterMint:INVALID_DROP");
        require(creator != address(0), "MasterMint:INVALID_CREATOR");
        return
            MintMetadata({
                artistMiningThreshold: calculateThreshold(nilPass).toUint32(),
                artistMiningPaymentThresholdInETH: configuration.artistMiningPaymentThresholdInETH,
                protocolFeesInBPS: configuration.protocolFeesInBPS,
                curationFeesInBPS: configuration.curationFeesInBPS,
                nilPass: nilPass,
                creator: creator,
                status: MintStatus.PENDING,
                calculator: calculator
            });
    }

    function calculateThreshold(INilPass nilPass) public view returns (uint256 artistMiningThreshold) {
        artistMiningThreshold = (configuration.artistMiningThresholdInBPS * nilPass.maxTotalSupply()) / 10000;
        artistMiningThreshold = Math.min(artistMiningThreshold, configuration.artistMiningHighWatermark);
    }

    function setMintCreator(uint256 mintId, address newCreator) external {
        MintMetadata storage metadata = mintsMetadata[mintId];
        require(msg.sender == metadata.creator, "MasterMint:ACCESS_DENIED");
        require(newCreator != address(0), "MasterMint:ILLEGAL_ADDRESS");
        metadata.creator = newCreator;
    }

    function setMintStatus(uint256 mintId, MintStatus status) external onlyOperator {
        require(mintId < mintsMetadata.length, "MasterMint:ILLEGAL_MINT_ID");
        MintMetadata storage metadata = mintsMetadata[mintId];
        require(status > MintStatus.PENDING, "MasterMint:ILLEGAL_STATUS");
        metadata.status = status;
    }

    function mintWithN(uint256 mintId, uint256[] calldata tokenIds) external payable virtual nonReentrant {
        MintMetadata storage metadata = mintsMetadata[mintId];
        MintPaymentState memory payment = payments[mintId];
        require(metadata.status == MintStatus.OPEN, "MasterMint:MINT_NOT_ACTIVE");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(nOwnerResolver.ownerOf(tokenIds[i]) == msg.sender, "MasterMint:NOT_N_OWNER");
        }
        payment.totalPaidInWei += toUint112(msg.value);
        payment.nPaid += toUint112(msg.value);
        payment.nMinted += tokenIds.length.toUint32();
        payments[mintId] = payment;
        metadata.nilPass.mintWithN(msg.sender, tokenIds, msg.value);
    }

    function mint(uint256 mintId, uint8 amount) external payable virtual nonReentrant {
        MintMetadata storage metadata = mintsMetadata[mintId];
        require(metadata.status == MintStatus.OPEN, "MasterMint:MINT_NOT_ACTIVE");
        payments[mintId].totalPaidInWei += toUint112(msg.value);
        metadata.nilPass.mint(msg.sender, amount, msg.value);
    }

    function mintTokenIds(uint256 mintId, uint256[] calldata tokenIds) external payable virtual nonReentrant {
        MintMetadata storage metadata = mintsMetadata[mintId];
        require(metadata.status == MintStatus.OPEN, "MasterMint:MINT_NOT_ACTIVE");
        payments[mintId].totalPaidInWei += toUint112(msg.value);
        metadata.nilPass.mintTokenId(msg.sender, tokenIds, msg.value);
    }

    function mints(uint256 mintId) external view returns (MintState memory) {
        MintMetadata memory metadata = mintsMetadata[mintId];
        MintPaymentState memory paymentData = payments[mintId];
        MintWithdrawalState memory withdrawal = withdrawals[mintId];
        return
            MintState({
                nMinted: paymentData.nMinted,
                totalPaidInWei: paymentData.totalPaidInWei,
                artistMiningWithdrawn: withdrawal.artistMiningWithdrawn,
                paymentWithdrawn: withdrawal.paymentWithdrawn,
                artistMiningThreshold: metadata.artistMiningThreshold,
                protocolFeesInBPS: metadata.protocolFeesInBPS,
                nilPass: metadata.nilPass,
                status: metadata.status,
                creator: metadata.creator,
                calculator: metadata.calculator
            });
    }

    function creatorWithdraw(uint256 mintId, bool withNil) external nonReentrant {
        MintPaymentState memory paymentState = payments[mintId];
        MintMetadata memory metadata = mintsMetadata[mintId];
        MintWithdrawalState memory withdrawal = withdrawals[mintId];

        require(msg.sender == metadata.creator || hasRole(OPERATOR_ROLE, msg.sender), "MasterMint:ACCESS_DENIED");
        require(metadata.status == MintStatus.OPEN, "MasterMint:ILLEGAL_STATE");
        if (withNil) {
            _mintNil(mintId, metadata);
        }
        uint128 newSalesProceeds = paymentState.totalPaidInWei - withdrawal.paymentWithdrawn;
        if (newSalesProceeds > 0) {
            uint256 fees = (metadata.protocolFeesInBPS * newSalesProceeds) / 10000;
            feesCollectable += fees;
            withdrawals[mintId].paymentWithdrawn += newSalesProceeds;
            payable(metadata.creator).transfer((newSalesProceeds - fees));
        }
    }

    function protocolWithdraw(bool withNil) external nonReentrant onlyOperator {
        if (nilCollectable > 0 && withNil) {
            require(curationFeesPayoutAccount != address(0), "MasterMint:INVALID_CURATION_ADDRESS");
            vNil.mint(curationFeesPayoutAccount, nilCollectable);
            nilCollectable = 0;
        }
        if (feesCollectable > 0) {
            require(protocolFeesPayoutAccount != address(0), "MasterMint:INVALID_PROTOCOL_ADDRESS");
            uint256 toCollect = feesCollectable;
            feesCollectable = 0;
            payable(protocolFeesPayoutAccount).transfer(toCollect);
        }
    }

    function _mintNil(uint256 mintId, MintMetadata memory metadata) internal {
        MintPaymentState memory paymentState = payments[mintId];
        MintWithdrawalState memory withdrawal = withdrawals[mintId];
        if (
            paymentState.nMinted > metadata.artistMiningThreshold &&
            paymentState.nPaid > (metadata.artistMiningPaymentThresholdInETH * 1 ether)
        ) {
            uint128 artistMining = Math
                .min(
                    metadata.calculator.calculateArtistMining(mintId, paymentState.totalPaidInWei),
                    configuration.maxNilMintable - totalNilMinted
                )
                .toUint128();
            // At the end of the AM programme there might be a case where the artist mining amount is actually
            // less than what has been already withdrawn, because we have a global cap on the total AM amount
            uint128 nilToMint = artistMining > withdrawal.artistMiningWithdrawn
                ? artistMining - withdrawal.artistMiningWithdrawn
                : 0;

            if (nilToMint > 0) {
                totalNilMinted += nilToMint;
                withdrawals[mintId].artistMiningWithdrawn += nilToMint;
                uint128 fees = (metadata.curationFeesInBPS * nilToMint) / 10000;
                nilCollectable += fees;
                vNil.mint(metadata.creator, (nilToMint - fees));
            }
        }
    }

    function setProtocolFeesPayoutAccount(address newProtocolFeesPayoutAccount) external onlyAdmin {
        protocolFeesPayoutAccount = newProtocolFeesPayoutAccount;
    }

    function setCurationFeesPayoutAccount(address newCurationFeesPayoutAccount) external onlyAdmin {
        curationFeesPayoutAccount = newCurationFeesPayoutAccount;
    }

    function setCalculator(IArtistMiningCalculator calculator_) public onlyAdmin {
        require(address(calculator_) != address(0), "MasterMint:INVALID_ADDRESS");
        calculator = calculator_;
    }

    function setConfiguration(ProtocolConfiguration memory configuration_) public onlyAdmin {
        require(configuration_.protocolFeesInBPS < 2000, "MasterMint:INVALID_PROTOCOL_FEES");
        require(configuration_.curationFeesInBPS < 2000, "MasterMint:INVALID_CURATION_FEES");
        require(configuration_.artistMiningHighWatermark < 8888, "MasterMint:INVALID_HIGH_WM_H");
        require(configuration_.artistMiningHighWatermark > 0, "MasterMint:INVALID_HIGH_WM_L");
        require(configuration_.artistMiningThresholdInBPS < 10000, "MasterMint:INVALID_THRESHOLD_H");
        require(configuration_.artistMiningThresholdInBPS > 0, "MasterMint:INVALID_THRESHOLD_L");
        require(configuration_.artistMiningPaymentThresholdInETH < 100, "MasterMint:INVALID_ETH_THRESHOLD");
        configuration = configuration_;
    }

    function getNumberOfMints() external view returns (uint256) {
        return mintsMetadata.length;
    }

    function ownerOf(uint256 nid) external view override returns (address) {
        return nOwnerResolver.ownerOf(nid);
    }

    function balanceOf(address account) external view override returns (uint256) {
        return nOwnerResolver.balanceOf(account);
    }

    function nOwned(address owner) external view override returns (uint256[] memory) {
        return nOwnerResolver.nOwned(owner);
    }

    function tokenExists(uint256 mintId, uint256 tokenId) external view returns (bool) {
        MintMetadata storage metadata = mintsMetadata[mintId];
        if (address(metadata.nilPass) == address(0)) return false;
        return metadata.nilPass.tokenExists(tokenId);
    }

    function tokensExist(uint256 mintId, uint256[] calldata tokenIds) external view returns (bool[] memory) {
        bool[] memory result = new bool[](tokenIds.length);
        MintMetadata storage metadata = mintsMetadata[mintId];
        if (address(metadata.nilPass) == address(0)) return result;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            result[i] = metadata.nilPass.tokenExists(tokenIds[i]);
        }
        return result;
    }

    function tokensOwned(uint256 mintId, address owner) external view returns (uint256[] memory) {
        MintMetadata storage metadata = mintsMetadata[mintId];
        if (address(metadata.nilPass) == address(0)) return new uint256[](0);
        INilPass nilPass = metadata.nilPass;
        uint256 balance = nilPass.balanceOf(owner);
        uint256[] memory result = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            result[i] = nilPass.tokenOfOwnerByIndex(owner, i);
        }
        return result;
    }

    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    receive() external payable virtual {
        feesCollectable += msg.value;
    }
}
