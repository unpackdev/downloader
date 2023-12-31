// SPDX-License-Identifier: MIT
/**
 _____
/  __ \
| /  \/ ___  _ ____   _____ _ __ __ _  ___ _ __   ___ ___
| |    / _ \| '_ \ \ / / _ \ '__/ _` |/ _ \ '_ \ / __/ _ \
| \__/\ (_) | | | \ V /  __/ | | (_| |  __/ | | | (_|  __/
 \____/\___/|_| |_|\_/ \___|_|  \__, |\___|_| |_|\___\___|
                                 __/ |
                                |___/
 */

import "./ERC721Enumerable.sol";
import "./Ownable2Step.sol";
import "./MerkleProof.sol";

import "./IERC20Metadata.sol";
import "./AggregatorV3Interface.sol";

import "./IBondCalculator.sol";
import "./ICvgOracle.sol";
import "./IOracleStruct.sol";

pragma solidity ^0.8.0;

contract Ibo is ERC721Enumerable, Ownable2Step {
    struct BondParams {
        uint8 composedFunction;
        IERC20Metadata token;
        uint24 gamma;
        uint16 scale;
        uint24 minRoi; // Min bond ROI, divide by 1000 to get the roi in %
        uint24 maxRoi; // Max bond ROI, divide by 1000 to get the roi in %
        uint256 percentageMaxCvgToMint; // Percentage maximum of the maxCvgToMint that an user can mint in one deposit
        uint256 maxCvgToMint; // Limit of Max CVG to mint
    }

    struct BondView {
        address bondAddress;
        uint88 bondRoi;
        bool isValid;
        uint256 totalCvgMinted;
        uint256 maxCvgToMint;
        uint256 assetPriceUsdCvgOracle;
        uint256 assetPriceUsdAggregator;
        uint256 bondPriceAsset;
        uint256 bondPriceUsd;
        uint256 percentageMaxCvgToMint;
        ERC20View token;
    }

    struct ERC20View {
        string token;
        address tokenAddress;
        uint256 decimals;
    }

    event BondDeposit(
        uint256 indexed tokenId,
        uint256 amountDeposited,
        uint256 cvgAdded,
        uint256 amountDepositedUsd,
        IERC20Metadata token
    );

    string internal baseURI;

    address public immutable treasuryBonds;

    /// @dev bond ROI calculator
    IBondCalculator public immutable bondCalculator;

    /// @dev oracle fetching prices in LP
    ICvgOracle public immutable cvgOracle;

    uint256 public iboStartTimestamp;

    /// @dev 0.33$
    uint256 public constant CVG_PRICE_NO_ROI = 33 * 10 ** 16;
    uint256 public constant IBO_DURATION = 6 hours;

    uint256 public constant MAX_CVG_PEPE_PRIVILEGE = 15_000 * 10 ** 18;
    uint256 public constant MAX_CVG_WL_PRIVILEGE = 7_500 * 10 ** 18;

    /// @dev The ID of the next token that will be minted. Skips 0
    uint256 public nextIdToken = 1;
    uint256 public nextIdBond = 1;

    bytes32 public merkleRootPepe;

    bytes32 public merkleRootWl;

    mapping(address => uint256) public soldDuringPrivilege;

    mapping(uint256 => BondParams) public bondsParams;

    mapping(uint256 => uint256) public totalCvgDuePerBond;

    mapping(uint256 => uint256) public totalCvgPerToken;

    constructor(
        address _treasuryBonds,
        IBondCalculator _bondCalculator,
        ICvgOracle _cvgOracle,
        bytes32 _merklePepe,
        bytes32 _merkleWl
    ) ERC721("IBO Cvg", "cvgIBO") {
        _transferOwnership(_treasuryBonds);
        treasuryBonds = _treasuryBonds;
        bondCalculator = _bondCalculator;
        cvgOracle = _cvgOracle;
        merkleRootPepe = _merklePepe;
        merkleRootWl = _merkleWl;
    }

    /**
     *  @notice Create a new bond with associated bondParams
     *  @param bondParams BondParams
     *
     */
    function createBond(BondParams calldata bondParams) external onlyOwner {
        bondsParams[nextIdBond++] = bondParams;
    }

    /**
     *  @notice Set the id of the curve related to the bond, 0 for square root, 1 for the logarithm  and 2 for square and 3 linear
     *  @param bondId uint256
     *  @param newComposedFunction uint8
     */
    function setComposedFunction(uint256 bondId, uint8 newComposedFunction) external onlyOwner {
        require(newComposedFunction < 4, "INVALID_COMPOSED_FUNCTION");
        bondsParams[bondId].composedFunction = newComposedFunction;
    }

    /**
     *  @notice Kicks in the IBO
     *  @param startTimestamp uint256
     */
    function setStartTimestamp(uint256 startTimestamp) external onlyOwner {
        iboStartTimestamp = startTimestamp;
    }

    /**
     *  @notice deposit into a bond to get an NFT with an underlaying value of CVG
     *  @param tokenId uint256
     *  @param bondId uint256
     *  @param amountIn uint256
     *  @param amountOutMin uint256
     *  @param privilegeType uint256
     *  @param _merkleProof bytes32[]
     */
    function deposit(
        uint256 tokenId,
        uint256 bondId,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 privilegeType,
        bytes32[] calldata _merkleProof
    ) external {
        require(amountIn > 0, "LTE");
        BondParams memory _bondParams = bondsParams[bondId];
        uint256 cvgToSold;
        uint256 _tokenId;
        uint256 depositedUsdValue;
        uint256 _totalCvgDue = totalCvgDuePerBond[bondId];
        {
            bool isPrivilege;
            uint256 _iboStartTimestamp = iboStartTimestamp;
            /// @dev peprivilege
            if (block.timestamp < _iboStartTimestamp + 45 * 1 minutes) {
                require(merkleVerifyWl(_merkleProof, privilegeType), "INVALID_PROOF");
                isPrivilege = true;
            }

            /// @dev Bond expired after 6h
            require(block.timestamp <= _iboStartTimestamp + IBO_DURATION, "BOND_INACTIVE");

            if (tokenId == 0) {
                _tokenId = nextIdToken++;
            } else {
                require(ownerOf(tokenId) == msg.sender, "TOKEN_NOT_OWNED");
                _tokenId = tokenId;
            }

            /// @dev Compute the amount deposited in dollar
            depositedUsdValue =
                amountIn *
                cvgOracle.getAndVerifyOracle(address(_bondParams.token)) *
                10 ** (18 - IERC20Metadata(_bondParams.token).decimals());

            /// @dev Compute the number of CVG to vest
            cvgToSold =
                depositedUsdValue /
                _computeCvgBondUsdPrice(CVG_PRICE_NO_ROI, _bondParams, _iboStartTimestamp, _totalCvgDue);

            if (isPrivilege) {
                uint256 newValueSold = soldDuringPrivilege[msg.sender] + cvgToSold;
                if (privilegeType == 0) {
                    require(newValueSold <= MAX_CVG_PEPE_PRIVILEGE, "MAX_CVG_PEPE_PRIVILEGE");
                } else {
                    require(newValueSold <= MAX_CVG_WL_PRIVILEGE, "MAX_CVG_WL_PRIVILEGE");
                }

                soldDuringPrivilege[msg.sender] = newValueSold;
            }
        }

        /// @dev Verify if ROI has not decreased
        require(cvgToSold >= amountOutMin, "OUT_MIN_NOT_REACHED");

        require(
            cvgToSold <= (_bondParams.percentageMaxCvgToMint * _bondParams.maxCvgToMint) / 10 ** 3,
            "MAX_CVG_PER_BOND"
        );
        {
            require(cvgToSold + _totalCvgDue <= _bondParams.maxCvgToMint, "MAX_CVG_ALREADY_MINTED");

            totalCvgDuePerBond[bondId] = _totalCvgDue + cvgToSold;

            totalCvgPerToken[_tokenId] += cvgToSold;
        }
        /// @dev deposit asset in the bondContract
        IERC20Metadata(_bondParams.token).transferFrom(msg.sender, treasuryBonds, amountIn);

        if (tokenId == 0) {
            _mint(msg.sender, _tokenId);
        }

        emit BondDeposit(_tokenId, amountIn, cvgToSold, depositedUsdValue / 10 ** 18, _bondParams.token);
    }

    /**
     *  @notice Compute the ROI thanks to the BondCalculator
     *  @return uint256 the ROI discount on the token price
     */
    function _depositRoi(uint256 bondId) internal view returns (uint256) {
        BondParams memory _bondParams = bondsParams[bondId];
        return
            bondCalculator.computeRoi(
                block.timestamp - iboStartTimestamp,
                IBO_DURATION,
                _bondParams.composedFunction,
                _bondParams.maxCvgToMint,
                totalCvgDuePerBond[bondId],
                _bondParams.gamma,
                _bondParams.scale,
                _bondParams.minRoi,
                _bondParams.maxRoi
            );
    }

    function _computeCvgBondUsdPrice(
        uint256 realCvgPrice,
        BondParams memory _bondParams,
        uint256 startTimestamp,
        uint256 alreadySold
    ) internal view returns (uint256) {
        return
            (realCvgPrice *
                (1_000_000 -
                    bondCalculator.computeRoi(
                        block.timestamp - startTimestamp,
                        IBO_DURATION,
                        _bondParams.composedFunction,
                        _bondParams.maxCvgToMint,
                        alreadySold,
                        _bondParams.gamma,
                        _bondParams.scale,
                        _bondParams.minRoi,
                        _bondParams.maxRoi
                    ))) / 10 ** 6;
    }

    function getTotalCvgDue() external view returns (uint256) {
        return totalCvgDuePerBond[1] + totalCvgDuePerBond[2] + totalCvgDuePerBond[3];
    }

    function getBondView(uint256 bondId) external view returns (BondView memory bondView) {
        BondParams memory _bondParams = bondsParams[bondId];
        IERC20Metadata token = _bondParams.token;
        uint256 alreadySold = totalCvgDuePerBond[bondId];
        bool isValid = true;
        uint256 assetUsdPrice;
        uint256 assetPriceUsdAggregator;
        {
            (
                uint256 _assetUsdPrice,
                uint256 _assetPriceUsdAggregator,
                bool verify1,
                bool verify2,
                bool verify3,
                bool verify4,
                bool areStableVerified,
                bool areLimitsVerified
            ) = cvgOracle.getDataForVerification(address(_bondParams.token));
            assetUsdPrice = _assetUsdPrice;
            assetPriceUsdAggregator = _assetPriceUsdAggregator;

            isValid = verify1 && verify2 && verify3 && verify4 && areStableVerified && areLimitsVerified;
        }

        uint256 bondPriceUsd = _computeCvgBondUsdPrice(CVG_PRICE_NO_ROI, _bondParams, iboStartTimestamp, alreadySold);

        bondView = BondView({
            bondAddress: address(this),
            bondRoi: uint88(_depositRoi(bondId)),
            maxCvgToMint: _bondParams.maxCvgToMint,
            totalCvgMinted: alreadySold,
            token: ERC20View({decimals: token.decimals(), token: token.symbol(), tokenAddress: address(token)}),
            assetPriceUsdCvgOracle: assetUsdPrice,
            assetPriceUsdAggregator: assetPriceUsdAggregator,
            bondPriceUsd: bondPriceUsd,
            bondPriceAsset: (bondPriceUsd * 10 ** 18) / assetUsdPrice,
            percentageMaxCvgToMint: _bondParams.percentageMaxCvgToMint,
            isValid: isValid
        });
    }

    /// @dev Check if a given address is on the White list S
    function merkleVerifyWl(bytes32[] calldata _merkleProofWl, uint256 _privilegeType) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (_privilegeType == 0) {
            return MerkleProof.verify(_merkleProofWl, merkleRootPepe, leaf);
        } else {
            return MerkleProof.verify(_merkleProofWl, merkleRootWl, leaf);
        }
    }

    function getTokenIdsForWallet(address _wallet) external view returns (uint256[] memory) {
        uint256 range = balanceOf(_wallet);
        uint256[] memory tokenIds = new uint256[](range);
        for (uint256 i = 0; i < range; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokenIds;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        return string(abi.encodePacked(baseURI));
    }
}
