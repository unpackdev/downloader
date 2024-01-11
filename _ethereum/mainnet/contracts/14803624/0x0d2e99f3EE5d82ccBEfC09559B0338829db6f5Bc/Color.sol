// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Color is ERC721, Ownable {
    uint256[26] redLevel = [
        200,
        10,
        20,
        210,
        40,
        220,
        60,
        0,
        70,
        90,
        100,
        80,
        30,
        130,
        140,
        230,
        150,
        170,
        180,
        190,
        110,
        120,
        50,
        160,
        240,
        250
    ];
    uint256[26] greenLevel = [
        40,
        250,
        20,
        190,
        0,
        180,
        60,
        70,
        80,
        130,
        110,
        230,
        120,
        90,
        140,
        100,
        200,
        170,
        150,
        30,
        160,
        210,
        220,
        240,
        50,
        10
    ];
    uint256[26] blueLevel = [
        130,
        10,
        110,
        30,
        40,
        50,
        60,
        70,
        240,
        230,
        100,
        80,
        140,
        20,
        120,
        0,
        160,
        170,
        210,
        250,
        200,
        90,
        220,
        180,
        150,
        190
    ];

    struct Metadata {
        uint256 red;
        uint256 green;
        uint256 blue;
    }

    uint256 private redIndex = 0;
    uint256 private greenIndex = 0;
    uint256 private blueIndex = 0;

    mapping(uint256 => Metadata) private idToMetaData;
    mapping(address => uint256[]) private minterToTokenIds;

    string private mainUri;
    uint256 private MAX_COLOR_VALUE = 256;
    uint256 private mint_fee = 10 * 10**16; //0.10 eth, almost $200
    uint256 private commissionPecentage = 40;
    uint256 private maxFreeToken = 100;
    uint256 private currentFreeToken = 0;

    constructor() ERC721("Pure Color Club", "PCC") {
        mainUri = "https://purecolorclub.com/";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return string(abi.encodePacked(mainUri, "token/"));
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        mainUri = _uri;
    }

    function contractURI() public view returns (string memory) {
        // return _baseURI() + "contractURL/";
        return string(abi.encodePacked(mainUri, "contractURL/"));
    }

    function getCommissionPecentage() external view returns (uint256) {
        return commissionPecentage;
    }

    function setCommissionPecentage(uint256 commission) external onlyOwner {
        require(commission >= 0, "commission must be larger than zero");
        require(
            commission <= 100,
            "commission must be smaller than one hundred"
        );
        commissionPecentage = commission;
    }

    function getMintFee() external view returns (uint256) {
        return mint_fee;
    }

    function setMintFee(uint256 mintFee) external onlyOwner {
        mint_fee = mintFee;
    }

    function isAddressMinted(address benefiter) external view returns (bool) {
        return minterToTokenIds[benefiter].length != 0;
    }

    function mintAndPayCommission(uint256 number, address benefiter)
        external
        payable
    {
        checkMintCondition(number);

        require(
            this.isAddressMinted(benefiter),
            "benefiter must mint at least one token"
        );

        require(number <= 10, "mint number must be small than 10");
        require(
            msg.sender != benefiter,
            "benefiter address and minter address must be different"
        );
        for (uint256 i = 0; i < number; i++) {
            generateToken();
        }

        uint256 commission = (msg.value / 100) * commissionPecentage;
        if (commission != 0) {
            payable(benefiter).transfer(commission);
        }
        payable(owner()).transfer(msg.value - commission);
    }

    function mint(uint256 number) external payable {
        checkMintCondition(number);

        for (uint256 i = 0; i < number; i++) {
            generateToken();
        }
        payable(owner()).transfer(msg.value);
    }

    function mintFree() external {
        require(
            !this.isAddressMinted(msg.sender),
            "this address already had a token"
        );

        require(currentFreeToken < maxFreeToken, "all free tokens were minted");
        generateToken();
        ++currentFreeToken;
    }

    function setMaxFreeToken(uint256 newMaxFreeToken) external onlyOwner {
        maxFreeToken = newMaxFreeToken;
    }

    function getMaxFreeToken() external view returns (uint256) {
        return maxFreeToken;
    }

    function getCurrentFreeToken() external view returns (uint256) {
        return currentFreeToken;
    }

    function checkMintCondition(uint256 number) private {
        require(number <= 10, "mint number must be small than 11");
        require(
            msg.value == mint_fee * number,
            "your value is not equal to mint fee"
        );
    }

    function generateToken() private {
        uint256 length = redLevel.length;
        uint256 red = redLevel[redIndex];
        uint256 green = greenLevel[greenIndex];
        uint256 blue = blueLevel[blueIndex];
        uint256 id = (red * 1000000) + (green * 1000) + blue;

        // check if color is not existed
        require(!_exists(id), "id is already existed");

        _safeMint(msg.sender, id);
        idToMetaData[id] = Metadata(red, green, blue);
        minterToTokenIds[msg.sender].push(id);
        ++blueIndex;
        if (blueIndex == length) {
            blueIndex = 0;
            ++greenIndex;
        }
        if (greenIndex == length) {
            greenIndex = 0;
            ++redIndex;
        }
        if (redIndex == length) {
            redIndex = 0;
            greenIndex = 0;
            blueIndex = 0;
        }
    }

    function getTokenIdsFromMinter(address minter)
        external
        view
        returns (uint256[] memory)
    {
        return minterToTokenIds[minter];
    }

    function getTokenMetadata(uint256 tokenId)
        external
        view
        returns (
            uint256 red,
            uint256 green,
            uint256 blue
        )
    {
        require(_exists(tokenId), "token have not been minted");
        Metadata memory metadata = idToMetaData[tokenId];
        red = metadata.red;
        green = metadata.green;
        blue = metadata.blue;
    }

    function isTokenIDExist(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
}

// function convertColorToString(uint red, uint green, uint blue) private pure returns(string memory){
//     string memory redString = Strings.toString(red);
//     string memory greenString = Strings.toString(green);
//     string memory blueString = Strings.toString(blue);

//     return string(abi.encodePacked(redString,'-',greenString,'-',blueString));
// }

// function setTokenName(uint256 tokenId, string memory tokenName) external{
//     require(_exists(tokenId), "token have not been minted");
//     require(ownerOf(tokenId) == msg.sender, "only the owner of this token can change its name");
//     idToMetaData[tokenId].name = tokenName;
// }

// function mint() external payable {
//     mintWithoutPay();
//     payable(owner()).transfer(mint_fee);
// }

// function mintAndPayCommission(address benefiter) external payable {
//     mintWithoutPay();
//     uint256 commission = (mint_fee / 100) * commissionPecentage;
//     if (commission != 0) {
//         payable(benefiter).transfer(commission);
//     }
//     payable(owner()).transfer(mint_fee - commission);
// }
