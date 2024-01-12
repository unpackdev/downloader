// contracts/AstroChart.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseOraclizedAstroChart.sol";
import "./PrimeAstroChart.sol";

contract OrdinaryAstroChart is BaseOraclizedAstroChart {
    using Chainlink for Chainlink.Request;

    PrimeAstroChart private primeAstroChart;

    uint256 private constant PRIME_TOKENID_UPPER_BOUND = 366;

    event AstroChartBred(uint256 bredTokenId, uint256 fromTokenId, address bredTokenOwner, uint256 price);

    constructor(address _primeAstroChartAddress, address _svgGeneratorAddress) ERC721("AstroChart", "O-ASTRO") {
        AstroChartLib._initNextTokenId(PRIME_TOKENID_UPPER_BOUND + 1);
        _transferOwnership(_msgSender());
        primeAstroChart = PrimeAstroChart(_primeAstroChartAddress);
        svgGenerator = SVGGenerator(_svgGeneratorAddress);
    }

    ///
    /// setUpParams used by MetaAstro ERC-721 Token
    /// @param linkTokenAddress, Chainlink's ERC-20 token address,
    /// @param _oracle, oracle address
    /// @param _jobId, oracle jobId used to calculate astro data
    /// @param _feeInLink, fee that should paid to Oracle operator for each request
    /// @param _oracleGasFee, gas fee that operator use when submit data back to contract
    /// @param _oracleRequestHost, host for oracle operator node to send request to
    /// @param _svgGenerator, SVGGenerator address
    ///
    function setUpParams(
        address linkTokenAddress,
        address _oracle,
        bytes32 _jobId,
        uint256 _feeInLink,
        uint256 _oracleGasFee,
        string calldata _oracleRequestHost,
        SVGGenerator _svgGenerator
    ) external onlyOwner {
        oracle = _oracle;
        jobId = _jobId;
        fee = _feeInLink;
        oracleRequestHost = _oracleRequestHost;
        setChainlinkToken(linkTokenAddress);
        AstroChartLib.setOracleGasFee(_oracleGasFee);
        svgGenerator = _svgGenerator;
    }

    /**
    withdraw oracle gas fee deposit, only can be done by owner
     */
    function withdrawOracleGasDeposit(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    /**
    checks:
      1. require ownerOf(tokenId) == msg.sender, guard only owner can change breed price, or else throw "Only owner can change breed price" as "OOCCBP"
      2. require !isTokenFromPrime(tokenId), or else throw "`tokenId` comes from PrimeAstroChart" as "TCFP"
    effects:
      1. update tokenId's breed price
     */
    function setBreedPrice(uint256 tokenId, uint256 breedPrice) external {
        //checks
        address ownerOfToken = isTokenFromPrime(tokenId) ? primeAstroChart.ownerOf(tokenId) : ownerOf(tokenId);
        require(ownerOfToken == msg.sender, "OOCCBP");

        //effects
        AstroChartLib.setBreedPrice(tokenId, breedPrice);
    }

    /**
    require pendingWithdraws[msg.sender] > 0, or else throw "pending withdraw must large than zero" as PWMLTZ
     */
    function withdrawBreedFee() external {
        AstroChartLib.withdrawBreedFee();
    }

    /**
    checks:
        1. require msg.value >= token.breedPrice + oracleGasFee, or else throw "LTBP+O"
        2. require datetimeOfBirth[1] == astroDataOfParentToken.datetimeOfBirth[1], or else throw "month not equal" as "MNE"
        3. require datetimeOfBirth[2] == astroDataOfParentToken.datetimeOfBirth[2], or else throw "day not equal" as "DNE"
        4. require astroDataOfParentToken.alreadyBredCount < breedingLimitationOf(astroDataOfParentToken.generation), or else throw "beyond generation's breeding limitation" as "BGBL" 
        5. require astroDataOfParentToken.exists, or else throw "ERC721: owner query for nonexistent token" 
    Effects:
        1. update pendinpendingWithdraws of fromToken's owner, as origin value + breedPrice
    Explainations:
    LTBP: less than breed price
     */
    function breedFrom(
        uint256 fromTokenId,
        uint16[] calldata monthAndDay,
        string calldata remaining
    ) external payable {
        AstroChartArgs memory argsOfFromToken;
        address ownerOfFromToken;

        //judge if breed from prime astro chart
        if (isTokenFromPrime(fromTokenId)) {
            argsOfFromToken = primeAstroChart.getAstroArgsOf(fromTokenId);
            ownerOfFromToken = primeAstroChart.ownerOf(fromTokenId);
        }
        /** if (fromTokenId > 366) say it's ordinary AstroChart */
        else {
            argsOfFromToken = AstroChartLib.getAstroArgsOf(fromTokenId);
            ownerOfFromToken = ownerOf(fromTokenId);
        }

        uint256 bredTokenId = AstroChartLib.breedFromDry(
            fromTokenId,
            monthAndDay,
            remaining,
            ownerOfFromToken,
            argsOfFromToken
        );

        _safeMint(msg.sender, bredTokenId);

        // interactions
        sendRequestToOracle(bredTokenId, monthAndDay, remaining);
        emit AstroChartBred(bredTokenId, fromTokenId, msg.sender, msg.value);
    }

    function breedingLimitationOf(uint32 generation) public pure returns (uint32 res) {
        return AstroChartLib.breedingLimitationOf(generation);
    }

    function getAstroArgsOf(uint256 tokenId) external view returns (AstroChartArgs memory) {
        if (isTokenFromPrime(tokenId)) {
            return primeAstroChart.getAstroArgsOf(tokenId);
        } else {
            return AstroChartLib.getAstroArgsOf(tokenId);
        }
    }

    function getBreedConfig(uint256 tokenId) external view returns (BreedConfig memory) {
        return AstroChartLib.getBreedConfigOf(tokenId);
    }

    function getBreedPrice(uint256 tokenId) external view returns (uint256) {
        return AstroChartLib.getBreedPrice(tokenId);
    }

    function getPendingWithdraw() external view returns (uint256) {
        return AstroChartLib.getPendingWithdraw();
    }

    function isTokenFromPrime(uint256 tokenId) private pure returns (bool) {
        return tokenId <= 366;
    }

    /**
    ERC-721 tokenURI 
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        BreedConfig memory breedConfig = AstroChartLib.getBreedConfigOf(tokenId);
        return tokenURIOf(tokenId, breedConfig.bredFromRootTokenId);
    }
}
