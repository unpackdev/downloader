// contracts/AstroChart.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BaseOraclizedAstroChart.sol";

contract PrimeAstroChart is BaseOraclizedAstroChart {
    event AstroChartBred(uint256 bredTokenId, uint256 fromTokenId, address bredTokenOwner, uint256 price);

    constructor(address _svgGeneratorAddress) ERC721("meta-astro-genesis", "P-ASTRO") {
        AstroChartLib._initNextTokenId(1);
        _transferOwnership(_msgSender());
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
    /// @param _salesStartTime, initial mint start time
    /// @param _salesEndTime, initial mint end time
    ///
    function setUpParams(
        address linkTokenAddress,
        address _oracle,
        bytes32 _jobId,
        uint256 _feeInLink,
        uint256 _oracleGasFee,
        string calldata _oracleRequestHost,
        uint256 _salesStartTime,
        uint256 _salesEndTime,
        SVGGenerator _svgGenerator
    ) external onlyOwner {
        oracle = _oracle;
        jobId = _jobId;
        fee = _feeInLink;
        oracleRequestHost = _oracleRequestHost;
        setChainlinkToken(linkTokenAddress);
        AstroChartLib.setOracleGasFee(_oracleGasFee);
        AstroChartLib.setSalesTimes(_salesStartTime, _salesEndTime);
        svgGenerator = _svgGenerator;
    }

    /**
    withdraw initial deposit, only can be done by owner
    require amount <= initialDeposit, or else throw "withdraw amount must less than initialDeposit" as WAMLTI
     */
    function withdrawInitialDeposit(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    /**
    initial mint,
    require initialMintCount < INITIAL_MINT_LIMIT, or else throw "initial mint limit arrived" as "IMLA"
    require msg.value >= getPrice() + oracleGasFee, or else throw "initial mint should pay with initialMintPrice + oracleGasFee" as "IMSPWI+O"
    require salesStartTime > 0 && currentTimeOffset >= salesStartTime, or else throw sales not start as "SNS"
    require libStorage().initialMintDate2Exists[dateToBytes32(datetimeOfBirth)] == false, or else throw initial mint date already exists as "IMDAE"
    _checkForDateAndCity's rule, ref _checkForDateAndCity's comment
     */
    function initialMint(
        address to,
        uint16[] calldata monthAndDay,
        string calldata remaining
    ) external payable {
        uint256 tokenId = AstroChartLib.initialMintDry(monthAndDay, remaining);
        _safeMint(to, tokenId);

        //interactions
        sendRequestToOracle(tokenId, monthAndDay, remaining);
    }

    /**
    regenerate,
    require onwerOf(tokenId) == msg.sender, or else throw "token not owned by sender" as "TNOBS"
    require msg.value >= oracleGasFee, or else throw "regenerate should pay with oracleGasFee" as "RSPWO"
    require monthAndDay == token.originAstroArgs.monthAndDay, or else throw "Month and day should equal to origin" as "MDSETO" 
    require monthAndDay.length == 2 and monthAndDay is valid or else throw "datetime not valid" as "DTNV"
     */
    function regenerate(
        uint256 tokenId,
        uint16[] calldata monthAndDay,
        string calldata remaining
    ) external payable {
        AstroChartLib.regenerateDry(tokenId, ownerOf(tokenId), monthAndDay, remaining);
        sendRequestToOracle(tokenId, monthAndDay, remaining);
    }

    function beginNoDateLimitMint() public onlyOwner {
        AstroChartLib.beginNoDateLimitPrimeMint();
    }

    function isNoDateLimitMintBegan() public view returns (bool) {
        return AstroChartLib.isNoDateLimitPrimeMintBegan();
    }

    function initalMintCount() external view returns (uint256) {
        return AstroChartLib.initialMintCount();
    }

    function initialDeposit() external view returns (uint256) {
        return AstroChartLib.initialDeposit();
    }

    function getPrice() external view returns (uint256) {
        return AstroChartLib.getPrice();
    }

    function getSalesTimes() external view returns (uint256, uint256) {
        return AstroChartLib.getSalesTimes();
    }

    function getAstroArgsOf(uint256 tokenId) external view returns (AstroChartArgs memory) {
        return AstroChartLib.getAstroArgsOf(tokenId);
    }

    function getPendingWithdraw() external view returns (uint256) {
        return AstroChartLib.getPendingWithdraw();
    }

    ///
    /// return relative prime tokenId if exist, orelse return 0
    function getTokenIdByMonthAndDay(uint16 month, uint16 day) external view returns (uint256) {
        return AstroChartLib.getTokenIdByMonthAndDay(month, day);
    }

    /**
    ERC-721 tokenURI 
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return tokenURIOf(tokenId, tokenId);
    }
}
