// contracts/CustoMoose.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IToken.sol";
import "./Library.sol";
import "./TraitLibrary.sol";
import "./BytesLib.sol";

contract Customoose is ERC721Enumerable, Ownable {
    using BytesLib for bytes;
    using SafeMath for uint256;
    using Library for uint8;

    //Mappings
    mapping(uint256 => string) internal tokenIdToConfig;
    mapping(uint256 => uint256) internal tokenIdToStoredTrax;

    //uint256s
    uint256 MAX_SUPPLY = 10000;
    uint256 MINTS_PER_TIER = 1000;

    uint256 MINT_START = 1639418400;
    uint256 MINT_START_ETH = MINT_START.add(86400);

    uint256 MINT_DELAY = 43200;
    uint256 START_PRICE = 70000000000000000;
    uint256 MIN_PRICE = 20000000000000000;
    uint256 PRICE_DIFF = 5000000000000000;

    uint256 START_PRICE_TRAX = 10000000000000000000;
    uint256 PRICE_DIFF_TRAX = 10000000000000000000;

    //address
    address public mooseAddress;
    address public traxAddress;
    address public libraryAddress;
    address _owner;

    constructor(address _mooseAddress, address _traxAddress, address _libraryAddress) ERC721("Frame", "FRAME") {
        _owner = msg.sender;
        setMooseAddress(_mooseAddress);
        setTraxAddress(_traxAddress);
        setLibraryAddress(_libraryAddress);

        // test mint
        mintInternal();
    }

    /*
  __  __ _     _   _             ___             _   _             
 |  \/  (_)_ _| |_(_)_ _  __ _  | __|  _ _ _  __| |_(_)___ _ _  ___
 | |\/| | | ' \  _| | ' \/ _` | | _| || | ' \/ _|  _| / _ \ ' \(_-<
 |_|  |_|_|_||_\__|_|_||_\__, | |_| \_,_|_||_\__|\__|_\___/_||_/__/
                         |___/                                     
   */

    /**
     * @dev Generates an 8 digit config
     */
    function config() internal pure returns (string memory) {
        // This will generate an 9 character string.
        // All of them will start as 0
        string memory currentConfig = "000000000";
        return currentConfig;
    }

    /**
     * @dev Mint internal, this is to avoid code duplication.
     */
    function mintInternal() internal returns (uint256 tokenId) {
        uint256 _totalSupply = totalSupply();
        require(_totalSupply < MAX_SUPPLY);
        require(!Library.isContract(msg.sender));

        uint256 thisTokenId = _totalSupply;

        tokenIdToConfig[thisTokenId] = config();
        tokenIdToStoredTrax[thisTokenId] = 0;
        _mint(msg.sender, thisTokenId);
        return thisTokenId;
    }

    /**
     * @dev Mints new frame using TRAX
     */
    function mintFrameWithTrax(uint8 _times) public {
        require(block.timestamp >= MINT_START, "Minting has not started");
        uint256 allowance = IToken(traxAddress).allowance(msg.sender, address(this));
        require(allowance >= _times * getMintPriceTrax(), "Check the token allowance");

        IToken(traxAddress).burnFrom(msg.sender, _times * getMintPriceTrax());
        for(uint256 i=0; i< _times; i++){
            mintInternal();
        }
    }

    /**
     * @dev Mints new frame using ETH
     */
    function mintFrameWithEth(uint8 _times) public payable {
        require(block.timestamp >= MINT_START_ETH, "Minting for ETH has not started");
        require((_times > 0 && _times <= 20));
        require(msg.value >= _times * getMintPriceEth());

        for(uint256 i=0; i< _times; i++){
            mintInternal();
        }
    }

    /**
     * @dev Mints new frame with customizations using ETH
     */
    function mintCustomooseWithEth(string memory tokenConfig) public payable {
        require(block.timestamp >= MINT_START_ETH, "Minting for ETH has not started");
        require(msg.value >= getMintPriceEth(), "Not enough ETH");

        uint256 tokenId = mintInternal();
        setTokenConfig(tokenId, tokenConfig);
    }

    /**
     * @dev Mints new frame with customizations using TRAX
     */
    function mintCustomooseWithTrax(string memory tokenConfig) public payable {
        require(block.timestamp >= MINT_START, "Minting has not started");
        uint256 allowance = IToken(traxAddress).allowance(msg.sender, address(this));
        require(allowance >= getMintPriceTrax(), "Check the token allowance");

        IToken(traxAddress).burnFrom(msg.sender, getMintPriceTrax());
        uint256 tokenId = mintInternal();
        setTokenConfig(tokenId, tokenConfig);
    }

    /**
     * @dev Burns a frame and returns TRAX
     */
    function burnFrameForTrax(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender);

        //Burn token
        _transfer(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            _tokenId
        );

        //Return the TRAX
        IToken(traxAddress).transfer(
            msg.sender,
            tokenIdToStoredTrax[_tokenId]
        );
    }

    /**
     * @dev Sets a trait for a token
     */
    function setTokenTrait(uint256 _tokenId, uint8 _traitIndex, uint8 _traitValue) public onlyOwner {
        string memory tokenConfig = tokenIdToConfig[_tokenId];
        string memory newTokenConfig = Library.stringReplace(tokenConfig, _traitIndex, Library.toString(_traitValue));

        tokenIdToConfig[_tokenId] = newTokenConfig;
    }

    /**
     * @dev Sets the config for a token
     */
    function setTokenConfig(uint256 _tokenId, string memory _newConfig) public {
        require(keccak256(abi.encodePacked(tokenIdToConfig[_tokenId])) !=
            keccak256(abi.encodePacked(_newConfig)), "Config must be different");

        uint256 allowance = IToken(traxAddress).allowance(msg.sender, address(this));
        (uint256 price, uint256 valueDiff, bool valueIncreased) = getCustomizationPrice(_tokenId, _newConfig);
        uint256 balance = IToken(traxAddress).balanceOf(msg.sender);
        require(allowance >= price, "Check the token allowance");
        require(balance >= price, "You need more TRAX");

        if(valueDiff >= 0 && valueIncreased) {
            IToken(traxAddress).transferFrom(
                msg.sender,
                address(this),
                valueDiff
            );
            IToken(traxAddress).burnFrom(msg.sender, price.sub(valueDiff));
            tokenIdToStoredTrax[_tokenId] += valueDiff;
        } else if(valueDiff >= 0 && !valueIncreased) {
            tokenIdToStoredTrax[_tokenId] -= valueDiff;
        }
        tokenIdToConfig[_tokenId] = _newConfig;
    }

    /**
     * @dev Takes an array of trait changes and gets the new config
     */
    function getNewTokenConfig(uint256 _tokenId, uint8[2][] calldata _newTraits)
        public
        view
        returns (string memory)
    {
        string memory tokenConfig = tokenIdToConfig[_tokenId];
        
        string memory newTokenConfig = tokenConfig;
        for (uint8 i = 0; i < _newTraits.length; i++) {
            string memory newTraitValue = Library.toString(_newTraits[i][1]);
            newTokenConfig = Library.stringReplace(newTokenConfig, _newTraits[i][0], newTraitValue);
        }
        return (newTokenConfig);
    }

    /**
     * @dev Gets the price of a newly minted frame
     */
    function getMintCustomizationPrice(string memory _newConfig)
        public
        view
        returns (uint256 price)
    {
        price = 0;
        for (uint8 i = 0; i < 9; i++) {
            uint8 traitValue = convertInt(bytes(_newConfig).slice(i, 1).toUint8(0));
            uint256 traitPrice = TraitLibrary(libraryAddress).getPrice(i, traitValue);
            price = price.add(traitPrice);
        }

        price = price.mul(10**16);
        return price;
    }

    /**
     * @dev Gets the price given a tokenId and new config
     */
    function getCustomizationPrice(uint256 _tokenId, string memory _newConfig)
        public
        view
        returns (uint256 price, uint256 valueDiff, bool increased)
    {
        string memory tokenConfig = tokenIdToConfig[_tokenId];
        uint256 currentValue = tokenIdToStoredTrax[_tokenId];
        
        price = 0;
        uint256 futureValue = 0;
        for (uint8 i = 0; i < 9; i++) {
            uint8 traitValue = convertInt(bytes(_newConfig).slice(i, 1).toUint8(0));
            uint256 traitPrice = TraitLibrary(libraryAddress).getPrice(i, traitValue);
            bool isChanged = keccak256(abi.encodePacked(bytes(tokenConfig).slice(i, 1))) !=
                keccak256(abi.encodePacked(bytes(_newConfig).slice(i, 1)));

            futureValue = futureValue.add(traitPrice);
            if(isChanged) {
                price = price.add(traitPrice);
            }
        }

        price = price.mul(10**16);
        futureValue = futureValue.mul(10**16).div(100).mul(80);
        if(futureValue == currentValue) {
            valueDiff = 0;
            increased = true;
        } else if(futureValue > currentValue) {
            valueDiff = futureValue.sub(currentValue);
            increased = true;
        } else {
            valueDiff = currentValue.sub(futureValue);
            increased = false;
        }

        return (price, valueDiff, increased);
    }

    /**
     * @dev Gets the price of a specified trait
     */
    function getTraitPrice(uint256 typeIndex, uint256 nameIndex)
        public
        view
        returns (uint256 traitPrice)
    {
        traitPrice = TraitLibrary(libraryAddress).getPrice(typeIndex, nameIndex);
        return traitPrice;
    }

    /**
     * @dev Gets the current mint price in ETH for a new frame
     */
    function getMintPriceEth()
        public
        view
        returns (uint256 price)
    {
        if(block.timestamp < MINT_START_ETH) {
            return START_PRICE;
        }

        uint256 _mintTiersComplete = block.timestamp.sub(MINT_START_ETH).div(MINT_DELAY);
        if(PRICE_DIFF.mul(_mintTiersComplete) >= START_PRICE.sub(MIN_PRICE)) {
            return MIN_PRICE;
        } else {
            return START_PRICE - (PRICE_DIFF * _mintTiersComplete);
        }
    }

    /**
     * @dev Gets the current mint price in TRAX for a new frame
     */
    function getMintPriceTrax()
        public
        view
        returns (uint256 price)
    {
        uint256 _totalSupply = totalSupply();

        if(_totalSupply == 0) return START_PRICE_TRAX;

        uint256 _mintTiersComplete = _totalSupply.div(MINTS_PER_TIER);
        price = START_PRICE_TRAX.add(_mintTiersComplete.mul(PRICE_DIFF_TRAX));
        return price;
    }

    /*
 ____     ___   ____  ___        _____  __ __  ____     __ ______  ____  ___   ____   _____
|    \   /  _] /    ||   \      |     ||  |  ||    \   /  ]      ||    |/   \ |    \ / ___/
|  D  ) /  [_ |  o  ||    \     |   __||  |  ||  _  | /  /|      | |  ||     ||  _  (   \_ 
|    / |    _]|     ||  D  |    |  |_  |  |  ||  |  |/  / |_|  |_| |  ||  O  ||  |  |\__  |
|    \ |   [_ |  _  ||     |    |   _] |  :  ||  |  /   \_  |  |   |  ||     ||  |  |/  \ |
|  .  \|     ||  |  ||     |    |  |   |     ||  |  \     | |  |   |  ||     ||  |  |\    |
|__|\_||_____||__|__||_____|    |__|    \__,_||__|__|\____| |__|  |____|\___/ |__|__| \___|
                                                                                           
*/

    /**
     * @dev Convert a raw assembly int value to a pixel location
     */
    function convertInt(uint8 _inputInt)
        internal
        pure
        returns (uint8)
    {
        if (
            (_inputInt >= 48) &&
            (_inputInt <= 57)
        ) {
            _inputInt -= 48;
            return _inputInt;
        } else {
            _inputInt -= 87;
            return _inputInt;

        }
    }

    /**
     * @dev Config to SVG function
     */
    function configToSVG(string memory _config)
        public
        view
        returns (string memory)
    {
        string memory svgString;

        for (uint8 i = 0; i < 9; i++) {
            uint8 thisTraitIndex = convertInt(bytes(_config).slice(i, 1).toUint8(0));
            bytes memory traitRects = TraitLibrary(libraryAddress).getRects(i, thisTraitIndex);

            if(bytes(traitRects).length == 0) continue;
            bool isRow = traitRects.slice(0, 1).equal(bytes("r"));

            uint16 j = 1;
            string memory thisColor = "";
            bool newColor = true;
            while(j < bytes(traitRects).length)
            {
                if(newColor) {
                    // get the color
                    thisColor = string(traitRects.slice(j, 3));
                    j += 3;
                    newColor = false;
                    continue;
                } else {
                    // if pipe, new color
                    if (
                        traitRects.slice(j, 1).equal(bytes("|"))
                    ) {
                        newColor = true;
                        j += 1;
                        continue;
                    } else {
                        // else add rects
                        bytes memory thisRect = traitRects.slice(j, 3);

                        uint8 x = convertInt(thisRect.slice(0, 1).toUint8(0));
                        uint8 y = convertInt(thisRect.slice(1, 1).toUint8(0));
                        uint8 length = convertInt(thisRect.slice(2, 1).toUint8(0)) + 1;

                        if(isRow) {
                            svgString = string(
                                abi.encodePacked(
                                    svgString,
                                    "<rect class='c",
                                    thisColor,
                                    "' x='",
                                    x.toString(),
                                    "' y='",
                                    y.toString(),
                                    "' width='",
                                    length.toString(),
                                    "px' height='1px'",
                                    "/>"
                                )
                            );
                            j += 3;
                            continue;
                        } else {
                            svgString = string(
                                abi.encodePacked(
                                    svgString,
                                    "<rect class='c",
                                    thisColor,
                                    "' x='",
                                    x.toString(),
                                    "' y='",
                                    y.toString(),
                                    "' height='",
                                    length.toString(),
                                    "px' width='1px'",
                                    "/>"
                                )
                            );
                            j += 3;
                            continue;
                        }
                    }
                }
            }
        }

        svgString = string(
            abi.encodePacked(
                '<svg id="moose-svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 32 32">',
                svgString,
                "<style>rect.bg{width:32px;height:32px;} #moose-svg{shape-rendering: crispedges;}",
                TraitLibrary(libraryAddress).getColors(),
                "</style></svg>"
            )
        );

        return svgString;
    }

    /**
     * @dev Config to metadata function
     */
    function configToMetadata(string memory _config)
        public
        view
        returns (string memory)
    {
        string memory metadataString;

        for (uint8 i = 0; i < 9; i++) {
            uint8 thisTraitIndex = convertInt(bytes(_config).slice(i, 1).toUint8(0));

            (string memory traitName, string memory traitType) = TraitLibrary(libraryAddress).getTraitInfo(i, thisTraitIndex);
            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    traitType,
                    '","value":"',
                    traitName,
                    '"}'
                )
            );

            if (i != 8)
                metadataString = string(abi.encodePacked(metadataString, ","));
        }

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     * @dev Returns the SVG and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId));

        string memory tokenConfig = _tokenIdToConfig(_tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Library.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "FRAME Edition 0, Token #',
                                    Library.toString(_tokenId),
                                    '", "description": "FRAME tokens are fully customizable on-chain pixel art. Edition 0 is a collection of 32x32 Moose avatars.", "image": "data:image/svg+xml;base64,',
                                    Library.encode(
                                        bytes(configToSVG(tokenConfig))
                                    ),
                                    '","attributes":',
                                    configToMetadata(tokenConfig),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Returns a config for a given tokenId
     * @param _tokenId The tokenId to return the config for.
     */
    function _tokenIdToConfig(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        string memory tokenConfig = tokenIdToConfig[_tokenId];
        return tokenConfig;
    }

    /**
     * @dev Returns the current amount of TRAX stored for a given tokenId
     * @param _tokenId The tokenId to look up.
     */
    function _tokenIdToStoredTrax(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        uint256 storedTrax = tokenIdToStoredTrax[_tokenId];
        return storedTrax;
    }

    /**
     * @dev Returns the wallet of a given wallet. Mainly for ease for frontend devs.
     * @param _wallet The wallet to get the tokens of.
     */
    function walletOfOwner(address _wallet)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    /*
  ___   __    __  ____     ___  ____       _____  __ __  ____     __ ______  ____  ___   ____   _____
 /   \ |  |__|  ||    \   /  _]|    \     |     ||  |  ||    \   /  ]      ||    |/   \ |    \ / ___/
|     ||  |  |  ||  _  | /  [_ |  D  )    |   __||  |  ||  _  | /  /|      | |  ||     ||  _  (   \_ 
|  O  ||  |  |  ||  |  ||    _]|    /     |  |_  |  |  ||  |  |/  / |_|  |_| |  ||  O  ||  |  |\__  |
|     ||  `  '  ||  |  ||   [_ |    \     |   _] |  :  ||  |  /   \_  |  |   |  ||     ||  |  |/  \ |
|     | \      / |  |  ||     ||  .  \    |  |   |     ||  |  \     | |  |   |  ||     ||  |  |\    |
 \___/   \_/\_/  |__|__||_____||__|\_|    |__|    \__,_||__|__|\____| |__|  |____|\___/ |__|__| \___|
                                                                                                     
    */

    /**
     * @dev Sets the ERC721 token address
     * @param _mooseAddress The NFT address
     */

    function setMooseAddress(address _mooseAddress) public onlyOwner {
        mooseAddress = _mooseAddress;
    }

    /**
     * @dev Sets the ERC20 token address
     * @param _traxAddress The token address
     */

    function setTraxAddress(address _traxAddress) public onlyOwner {
        traxAddress = _traxAddress;
    }

   /**
     * @dev Sets the trait library address
     * @param _libraryAddress The token address
     */

    function setLibraryAddress(address _libraryAddress) public onlyOwner {
        libraryAddress = _libraryAddress;
    }

    /**
     * @dev Withdraw ETH to owner
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }
}