// contracts/SVGGenerator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./DateUtils.sol";
// import "./console.sol";

struct AstroChartArgs {
    uint16[] monthAndDay;
    string remaining;
    bool exists;
    uint32 generation;
}

struct BreedConfig {
    uint32 alreadyBredCount;
    uint256 breedPrice;
    uint256 bredFromRootTokenId;
}

library AstroChartLib {
    // the limit for initial mint
    uint256 private constant INITIAL_MINT_LIMIT = 366;
    uint256 private constant SALES_START_PRICE = 1000 ether;
    uint256 private constant PRICE_DROP_DURATION = 600; // 10 mins
    uint256 private constant PRICE_DROP_PERCENT = 10;
    uint256 private constant PRICE_DROP_FLOOR = 0.1 ether;

    struct LibStorage {
        bool noDateLimitPrimeMint;
        // already minted for initial minting
        uint256 initalMintCount;
        // salesStartTime, offset from day's 0 clock, unit: seconds
        uint256 salesStartTime;
        // salesEndTime, offset from day's 0 clock, unit: seconds
        uint256 salesEndTime;
        // initial deposit
        uint256 initialDeposit;
        // initial mint's conflict detector
        mapping(bytes32 => uint256) mintedDate2PrimeTokenId;
        // record tokenId to origin data
        mapping(uint256 => AstroChartArgs) tokenIdToAstroData;
        // record tokenId to breed next generation's price and alreadBredCount
        mapping(uint256 => BreedConfig) tokenIdToBreedConfig;
        // record owner to pending withdraws
        mapping(address => uint256) pendingWithdraws;
        uint256 nextTokenId;
        // charge the oracle gas fee for oracle operator to submit transaction
        uint256 oracleGasFee;
    }

    // return a struct storage pointer for accessing the state variables
    function libStorage() internal pure returns (LibStorage storage ds) {
        bytes32 position = keccak256("AstroChartLib.storage");
        assembly {
            ds.slot := position
        }
    }

    function _initNextTokenId(uint256 initValue) public {
        libStorage().nextTokenId = initValue;
    }

    /**
     * @dev calculates the next token ID based on totalSupply
     * @return uint256 for the next token ID
     */
    function _nextTokenId() private returns (uint256) {
        uint256 res = libStorage().nextTokenId;
        libStorage().nextTokenId += 1;
        return res;
    }

    function getOracleGasFee() public view returns (uint256) {
        return libStorage().oracleGasFee;
    }

    function setOracleGasFee(uint256 _fee) public {
        libStorage().oracleGasFee = _fee;
    }

    /**
    set the sales startTime and endTime, only can be done by owner
     */
    function setSalesTimes(uint256 _salesStartTime, uint256 _salesEndTime) public {
        libStorage().salesStartTime = _salesStartTime;
        libStorage().salesEndTime = _salesEndTime;
    }

    function getSalesTimes() public view returns (uint256, uint256) {
        return (libStorage().salesStartTime, libStorage().salesEndTime);
    }

    function initialDeposit() public view returns (uint256) {
        return libStorage().initialDeposit;
    }

    function initialMintCount() public view returns (uint256) {
        return libStorage().initalMintCount;
    }

    function beginNoDateLimitPrimeMint() public {
        libStorage().noDateLimitPrimeMint = true;
    }

    function isNoDateLimitPrimeMintBegan() public view returns (bool) {
        return libStorage().noDateLimitPrimeMint;
    }

    function initialMintDry(uint16[] calldata monthAndDay, string calldata remaining) public returns (uint256 tokenId) {
        //checks
        require(libStorage().initalMintCount < INITIAL_MINT_LIMIT, "IMLA");

        uint256 price = getPrice();
        require(msg.value >= getPrice() + libStorage().oracleGasFee, "IMSPWI+O");

        require(price != 0, "SNS");

        uint16 month = monthAndDay[0];
        uint16 day = monthAndDay[1];
        require(libStorage().mintedDate2PrimeTokenId[dateToBytes32(month, day)] == 0, "IMDAE");

        if (!isNoDateLimitPrimeMintBegan()) {
            require(DateUtils.getDayFromTimestamp(block.timestamp) == day, "DTNT");
        }

        _checkForDateAndCity(monthAndDay);

        //effects
        AstroChartArgs memory args = AstroChartArgs({
            monthAndDay: monthAndDay,
            remaining: remaining,
            exists: true,
            generation: 0
        });

        tokenId = _nextTokenId();
        libStorage().tokenIdToAstroData[tokenId] = args;
        libStorage().initalMintCount++;
        libStorage().initialDeposit += msg.value;
        libStorage().mintedDate2PrimeTokenId[dateToBytes32(month, day)] = tokenId;
    }

    function regenerateDry(
        uint256 tokenId,
        address ownerOfToken,
        uint16[] calldata _monthAndDay,
        string calldata remaining
    ) public {
        //require
        require(ownerOfToken == msg.sender, "TNOBS");
        require(msg.value >= libStorage().oracleGasFee, "RSPWO");
        AstroChartArgs memory originArgs = libStorage().tokenIdToAstroData[tokenId];
        require(_monthAndDay[0] == originArgs.monthAndDay[0] && _monthAndDay[1] == originArgs.monthAndDay[1], "MDSETO");
        _checkForDateAndCity(_monthAndDay);

        //effect
        AstroChartArgs memory args = AstroChartArgs({
            monthAndDay: _monthAndDay,
            remaining: remaining,
            exists: true,
            generation: 0
        });
        libStorage().tokenIdToAstroData[tokenId] = args;
        libStorage().initialDeposit += msg.value;
    }

    function getTokenIdByMonthAndDay(uint16 month, uint16 day) public view returns (uint256) {
        return libStorage().mintedDate2PrimeTokenId[dateToBytes32(month, day)];
    }

    function dateToBytes32(uint16 month, uint16 day) private pure returns (bytes32) {
        bytes memory encoded = abi.encodePacked(month, day);
        return bytesToBytes32(encoded);
    }

    function bytesToBytes32(bytes memory b) private pure returns (bytes32 out) {
        for (uint8 i = 0; i < b.length; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
    }

    function getPrice() public view returns (uint256) {
        if (libStorage().salesStartTime == 0) {
            return 0;
        }

        uint256 currentTimeOffset = DateUtils.getUTCSecondsOffsetInDay(block.timestamp);
        uint256 startSalesTime = libStorage().salesStartTime;

        if (currentTimeOffset < startSalesTime) {
            return 0;
        }

        uint256[75] memory priceTable = [
            (uint256)(900.0 ether),
            810.0 ether,
            729.0 ether,
            656.1 ether,
            590.4 ether,
            531.4 ether,
            478.2 ether,
            430.4 ether,
            387.4 ether,
            348.6 ether,
            313.8 ether,
            282.4 ether,
            254.1 ether,
            228.7 ether,
            205.8 ether,
            185.3 ether,
            166.7 ether,
            150.0 ether,
            135.0 ether,
            121.5 ether,
            109.4 ether,
            98.4 ether,
            88.6 ether,
            79.7 ether,
            71.7 ether,
            64.6 ether,
            58.1 ether,
            52.3 ether,
            47.1 ether,
            42.3 ether,
            38.1 ether,
            34.3 ether,
            30.9 ether,
            27.8 ether,
            25.0 ether,
            22.5 ether,
            20.2 ether,
            18.2 ether,
            16.4 ether,
            14.7 ether,
            13.3 ether,
            11.9 ether,
            10.7 ether,
            9.6 ether,
            8.7 ether,
            7.8 ether,
            7.0 ether,
            6.3 ether,
            5.7 ether,
            5.1 ether,
            4.6 ether,
            4.1 ether,
            3.7 ether,
            3.3 ether,
            3.0 ether,
            2.7 ether,
            2.4 ether,
            2.2 ether,
            1.9 ether,
            1.7 ether,
            1.6 ether,
            1.4 ether,
            1.3 ether,
            1.1 ether,
            1.0 ether,
            0.9 ether,
            0.8 ether,
            0.7 ether,
            0.6 ether,
            0.6 ether,
            0.5 ether,
            0.4 ether,
            0.3 ether,
            0.2 ether,
            0.1 ether
        ];

        // Public sales
        uint256 dropCount = (currentTimeOffset - startSalesTime) / PRICE_DROP_DURATION;

        return dropCount < priceTable.length ? priceTable[dropCount] : PRICE_DROP_FLOOR;
    }

    /**
    require monthAndDay.length == 2 and monthAndDay is valid or else throw "datetime not valid" as "DTNV"
    */
    function _checkForDateAndCity(uint16[] calldata monthAndDay) private view {
        require(monthAndDay.length == 2, "DTNV");
        uint16 month = monthAndDay[0];
        uint16 day = monthAndDay[1];
        require(DateUtils.isDateValid(2012, month, day), "DTNV");
    }

    function setBreedPrice(uint256 tokenId, uint256 breedPrice) public {
        //effects
        libStorage().tokenIdToBreedConfig[tokenId].breedPrice = breedPrice;
    }

    function getBreedPrice(uint256 tokenId) public view returns (uint256) {
        BreedConfig storage breedConfig = libStorage().tokenIdToBreedConfig[tokenId];
        AstroChartArgs memory args = getAstroArgsOf(tokenId);
        return getBreedPriceInner(breedConfig, args);
    }

    function getBreedPriceInner(BreedConfig storage breedConfig, AstroChartArgs memory astroChartArgs)
        internal
        view
        returns (uint256)
    {
        uint256 userBreedPrice = breedConfig.breedPrice;
        return userBreedPrice == 0 ? suggestBreedPrice(astroChartArgs) : userBreedPrice;
    }

    function suggestBreedPrice(AstroChartArgs memory astroChartArgs) internal pure returns (uint256) {
        uint256 generation = astroChartArgs.generation;
        return 1 ether / (2**generation);
    }

    function withdrawBreedFee() public {
        //checks
        require(libStorage().pendingWithdraws[msg.sender] > 0, "PWMLTZ");

        //effects
        libStorage().pendingWithdraws[msg.sender] = 0;

        //interactions
        payable(msg.sender).transfer(libStorage().pendingWithdraws[msg.sender]);
    }

    function breedFromDry(
        uint256 fromTokenId,
        uint16[] calldata monthAndDay,
        string calldata remaining,
        address ownerOfFromToken,
        AstroChartArgs memory astroDataOfParentToken
    ) public returns (uint256 bredTokenId) {
        //checks
        BreedConfig storage breedConfig = libStorage().tokenIdToBreedConfig[fromTokenId];
        require(
            msg.value >= getBreedPriceInner(breedConfig, astroDataOfParentToken) + libStorage().oracleGasFee,
            "LTBP+O"
        );
        _checkForDateAndCity(monthAndDay);
        require(monthAndDay[0] == astroDataOfParentToken.monthAndDay[0], "MNE");
        require(monthAndDay[1] == astroDataOfParentToken.monthAndDay[1], "DNE");

        require(breedConfig.alreadyBredCount < breedingLimitationOf(astroDataOfParentToken.generation), "BGBL");

        //effects
        AstroChartArgs memory args = AstroChartArgs({
            monthAndDay: monthAndDay,
            remaining: remaining,
            exists: true,
            generation: astroDataOfParentToken.generation + 1
        });

        //set bredToken to astro data
        bredTokenId = _nextTokenId();
        libStorage().tokenIdToAstroData[bredTokenId] = args;

        //set breedConfig.bredFromRootTokenId
        libStorage().tokenIdToBreedConfig[bredTokenId].bredFromRootTokenId = breedConfig.bredFromRootTokenId == 0
            ? fromTokenId
            : breedConfig.bredFromRootTokenId;

        //update pending withdraw of from token's owner
        libStorage().pendingWithdraws[ownerOfFromToken] += breedConfig.breedPrice;

        //add oracleGadFee to initialDeposit
        libStorage().initialDeposit += msg.value - breedConfig.breedPrice;
        // update alreadyBredCount of fromToken
        breedConfig.alreadyBredCount += 1;
    }

    function breedingLimitationOf(uint32 generation) public pure returns (uint32 res) {
        if (generation == 0) {
            return 2**32 - 1;
        }

        if (generation > 10) {
            return 0;
        }

        uint32 revisedGen = 10 - generation;
        res = uint32(1) << revisedGen;
    }

    function getAstroArgsOf(uint256 tokenId) public view returns (AstroChartArgs memory) {
        return libStorage().tokenIdToAstroData[tokenId];
    }

    function getBreedConfigOf(uint256 tokenId) public view returns (BreedConfig memory) {
        return libStorage().tokenIdToBreedConfig[tokenId];
    }

    function getPendingWithdraw() public view returns (uint256) {
        return libStorage().pendingWithdraws[msg.sender];
    }
}
